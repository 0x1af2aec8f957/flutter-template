/// H5小程序
import 'dart:io';
import 'dart:async';
import 'dart:convert';
// import 'dart:isolate';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:crypto/crypto.dart';
import 'package:http/io_client.dart' show IOClient;
import 'package:shelf/shelf_io.dart' as io;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shelf_proxy/shelf_proxy.dart'; // shelf 代理中间件
import 'package:shelf_router/shelf_router.dart' as router;
import 'package:shelf_static/shelf_static.dart'; // shelf 静态文件中间件
import 'package:path_provider/path_provider.dart';
import 'package:belatuk_range_header/belatuk_range_header.dart'; // RangeHeader 解析

import '../setup/config.dart';
import '../utils/common.dart';
import '../plugins/http.dart';
import '../plugins/dialog.dart';

typedef CheckCache = bool Function(shelf.Request request); // Type: 检查是否需要缓存

class SmallProgram { // isolate 启动参数
  Uri? _remoteZipFileAddress; // 远程资源包地址
  final String name; // 小程序名称
  final Uri serverAddress; // 小程序服务器地址（远程服务器提供 api 的地址）
  final int port; // 小程序启动使用的端口
  final bool hasLocalBundle; // 是否有本地资源包
  Future<bool> get isStaticAssetsValid async => File(path.join((await staticAssetsDirectory).path, 'index.html')).existsSync(); // 小程序静态资源是否有效，必须要包含一个入口文件：index.html
  final Future<bool> Function(File localZipFile, void Function(Uri url) updateRemoteZipFileAddress) shouldUpdate; // 是否需要更新, NOTE: 如果需要更新，则必需要调用 updateRemoteZipFileAddress 方法更新远程资源包地址
  final Future<void> Function(Uri url)? onUpdated; // 更新成功后的回调
  Future<Directory> get applicationDirectory => getApplicationDocumentsDirectory(); // 应用程序包目录(沙盒目录，读写无需单独的权限申请)，该文件夹一定存在
  Future<Directory> get downloadsDirectory => applicationDirectory.then((_dir) { // 小程序下载目录
    final dir = Directory(path.join(_dir.path, 'downloads')); // 下载目录
    Talk.log('远程ZIP资源包下载目录：${dir.path}', name: 'SmallProgram');
    if (!dir.existsSync()) dir.createSync(recursive: true); // 如果下载目录不存在，则创建
    return dir;
  });
  Future<Directory> get cachesDirectory => applicationDirectory.then((_dir) { // 小程序资源缓存目录
    final dir = Directory(path.join(_dir.path, 'caches')); // 缓存目录
    Talk.log('小程序资源缓存目录：${dir.path}', name: 'SmallProgram');
    if (!dir.existsSync()) dir.createSync(recursive: true); // 如果缓存目录不存在，则创建
    return dir;
  });

  Future<File> get localZipFile async { // 小程序压缩包文件(如果本地文件不存在，指定目录文件也不存在，该文件也会不存在)
    final dir = await downloadsDirectory;
    final file = File(path.join(dir.path, '${name}.zip')); // 本地存储的下载文件
    Talk.log('小程序ZIP资源包存放路径：${file.path}', name: 'SmallProgram');
    if (file.existsSync()) return file; // 如果文件存在，则直接返回

    if (hasLocalBundle) { // 如果有本地资源包，则将资源包写入小程序下载目录指定文件
      final _file = await rootBundle.load('assets/${name}.zip'); // 本地资源包
      Talk.log('未找到资源包，正在将本地资源包写入到：${file.path}', name: 'SmallProgram');
      file
        ..create(recursive: true) // 如果文件不存在，则创建
        ..writeAsBytesSync(_file.buffer.asUint8List()); // 将资源包写入文件
    }

    return file;
  }

  Future<Directory> get staticAssetsDirectory => applicationDirectory.then((_dir) { // 小程序静态资源目录
    final dir = Directory(path.join(_dir.path, 'www', name)); // 静态资源目录
    Talk.log('小程序资源存放目录：${dir.path}', name: 'SmallProgram');
    if (!dir.existsSync()) dir.createSync(recursive: true); // 如果静态资源目录不存在，则创建
    return dir;
  });

  SmallProgram(this.name, {
    required this.serverAddress,
    this.port = 8089,
    required this.shouldUpdate,
    this.hasLocalBundle = false,
    this.onUpdated,
  });

  Future<void> handleDecompression([isRemoveOldDir = true]) async {
    final targetFile = await localZipFile;
    if (!targetFile.existsSync()) return; // 如果文件不存在，停止继续执行

    final targetDir = await staticAssetsDirectory;
    final Archive archive = ZipDecoder().decodeBytes(targetFile.readAsBytesSync());

    if (isRemoveOldDir && targetDir.existsSync()) targetDir.deleteSync(recursive: true); // 如果需要删除原有的目录，则删除

    Talk.log('解压资源存放路径：${targetDir.path}', name: 'SmallProgram');
    return archive.forEach((ArchiveFile _file) { // 将Zip存档的内容解压到磁盘。
      Talk.log('解压文件详细信息：${_file}', name: 'SmallProgram');
      if (_file.isFile) { // 如果是文件
        File(path.join(targetDir.path, '..', _file.name))
          ..createSync(recursive: true)
          ..writeAsBytesSync(_file.content as List<int>);
        return;
      }

      // 如果是目录
      Directory(path.join(targetDir.path, '..', _file.name))
        ..createSync(recursive: true);
    });
  }

  Future<void> updateLocalZipFile([bool isDecompress = true]) async {
    if (_remoteZipFileAddress == null) return; // 如果没有远程资源包地址，则停止继续执行
    late void Function(void Function()) updateSnackBar; // 弹框 UI 更新函数
    int _progress = 0; // 下载进度

    final dir = await downloadsDirectory;
    final file = await localZipFile;
    final tmpFile = File(path.join(dir.path, '${name}.tmp.zip')); // 临时文件

    final snackToast = Talk.snackBar(StatefulBuilder(builder: (_context, _setState){ // 更新提示信息
      updateSnackBar = _setState;
      return Text('正在下载更新包：${_progress}%');
    },), duration: Duration(days: 1));

    await Http.original.downloadUri(_remoteZipFileAddress!, tmpFile.path, onReceiveProgress: (int _count, int _total) { // 下载更新资源包
      Talk.log('正在下载更新包：$_count/$_total', name: 'SmallProgram');
      updateSnackBar((){ // 更新 UI
        _progress = _total > 0 ? (_count / _total * 100).toInt() : 0;
      });
    })
    .whenComplete(snackToast.close) // 下载完成后关闭提示信息
    .catchError((error) {
      Talk.log('下载更新包失败：$error', name: 'SmallProgram');
      Talk.alert('下载更新包失败');
    });

    Talk.log('下载完成，下载资源包保存在：${tmpFile.path}', name: 'SmallProgram');
    Talk.log('正在将 ${tmpFile.path} 的内容 写入到 ${file.path}', name: 'SmallProgram');
    file.writeAsBytesSync(tmpFile.readAsBytesSync());
    Talk.log('正在删除临时下载文件：${tmpFile.path}', name: 'SmallProgram');
    tmpFile.delete(recursive: true); // 重命名临时文件

    if (isDecompress) await handleDecompression(); // 解压资源包
  }

  Future<HttpServer> runServer() async {
    final isNeedUpdate = await shouldUpdate(await localZipFile, (Uri url) => _remoteZipFileAddress = url);
    if (isNeedUpdate) await updateLocalZipFile(); // 如果需要更新，则更新资源包
    if (!await isStaticAssetsValid) await handleDecompression(); // 如果静态资源无效（在更新之后仍然无效），则解压资源包

    final HttpClient httpClient = HttpClient()..badCertificateCallback = (X509Certificate cert, String host, int port) => true; // 忽略证书错误
    final _proxyHandler = proxyHandler(serverAddress, client: AppConfig.isProduction ? null : IOClient(httpClient)); // 代理处理器
    final staticDirectory = await staticAssetsDirectory;
    final InternetAddress host = InternetAddress.loopbackIPv4/*'127.0.0.1'*/; // 本机IP地址

    final routes = router.Router(notFoundHandler: createStaticHandler(staticDirectory.path, defaultDocument: 'index.html')) // 模拟 connect-history-api-fallback 中间件。
      ..all('/api/<ignored|.*>', _proxyHandler) // 代理 /api 中间件
      ..all('/image/<ignored|.*>', _proxyHandler) // 代理 /image 中间件
      // ..get('/video.mp4', (shelf.Request request) => rootBundle.load('assets/video.mp4').then((value) => shelf.Response(200, body: value.buffer.asUint8List(), headers: {'content-type': 'video/mp4'}))) // 视频文件
    ;

    final handler = const shelf
      .Pipeline()
      .addMiddleware(shelf.logRequests()) // 打印信息
      .addMiddleware(cacheMiddleware((shelf.Request request) => request.url.path.startsWith('image/'))) // 缓存中间件
      .addHandler(routes) // 代理访问处理器
    ;

    return await io.serve(handler, host, port, shared: true /* 在需要销毁上一个服务，马上创建下一个相同的服务时必须要开启 */).then((HttpServer _server){
      _server.idleTimeout = null; // 服务空闲超时时间：https://api.dart.dev/stable/3.0.6/dart-io/HttpServer/idleTimeout.html
      Talk.log('小程序服务运行在：${_server.address.address}:${_server.port}', name: 'SmallProgram');
      if (isNeedUpdate && onUpdated != null) onUpdated!(Uri(scheme: 'http', host: _server.address.host, port: _server.port));
      return _server;
    });
  }

  shelf.Middleware cacheMiddleware(CheckCache? checkCache/* 除了基础的 cache-control 以外的缓存判断方法 */) => (shelf.Handler innerHandler) {
    const requestCacheControls = ['only-if-cached']; // 需要缓存的请求指令集
    const requestNoCacheControls = ['no-store', 'no-cache']; // 不需要缓存的请求指令集
    const responseCacheControls = ['public', 'private']; // 需要缓存的响应指令集
    const streamMediaMimeTypes = ['video', 'audio']; // 需要下载的文件类型

    return (shelf.Request request) async {
      final mimeType = lookupMimeType(request.url.path); // 获取请求文件类型
      final isStreamMediaMimeTypes = mimeType != null && streamMediaMimeTypes.any(mimeType.startsWith); // 是否是流媒体文件
      final requestHeaders = Map<String, String>.from(request.headers); // 请求头
      final isNoCache = request.headersAll['Cache-Control']?.any(requestNoCacheControls.contains) ?? false; // 是否强制不需要缓存
      final isAgentCache = (checkCache?.call(request) ?? false) && !isNoCache; // 是否需要缓存
      final dir = await cachesDirectory;  // 获取缓存目录
      final file = File(path.join(dir.path, '${md5.convert(request.url.toString().codeUnits)}.cache')); // 缓存文件
      final header = File(path.join(dir.path, '${md5.convert(request.url.toString().codeUnits)}.header')); // 缓存头文件

      if (isAgentCache && isStreamMediaMimeTypes && !file.existsSync()) { // TODO 音视频文件 在设置 range='bytes=0-' 的情况下，也不会返回全部内容，需要使用下载获取文件所有内容
        await Http.original.downloadUri(
          request.requestedUri.replace(scheme: serverAddress.scheme, host: serverAddress.host, port: serverAddress.port),
          file.path,
        ).then((value) {
          Talk.log('缓存主体文件下载完成[midea-size -> ${file.readAsBytesSync().length}]：${file.path}', name: 'SmallProgram');
        });
      }

      if (file.existsSync() && isAgentCache) { // 如果缓存文件存在，则直接返回
        final headers = header.existsSync() ? Map<String, Object>.from(header.readAsStringSync().parseToMap) : Map<String, Object>();
        final body = file.readAsBytesSync();
        Talk.log('缓存url地址：${request.url}', name: 'SmallProgram');
        Talk.log('找到需要返回的缓存主体文件：${file.path}', name: 'SmallProgram');
        Talk.log('关联的缓存头文件路径：${header.path}', name: 'SmallProgram');
        final rangeHeader = RangeHeader.parse(requestHeaders['range'] ?? 'bytes=0-');
        final rangeHeaderStart = rangeHeader.items.last.start;
        final rangeHeaderEnd = rangeHeader.items.last.end == -1 ? body.length : rangeHeader.items.last.end;

        if (rangeHeader.rangeUnit != 'bytes') return shelf.Response.badRequest(body: 'rangeUnit 仅支持 bytes');
        if (rangeHeader.items.length > 1) return shelf.Response.badRequest(body: '不支持 Multipart ranges');

        headers['content-length'] = (rangeHeaderEnd - rangeHeaderStart).toString(); // 添加 Content-Length 响应头
        headers['accept-ranges'] = rangeHeader.rangeUnit!; // 添加 Accept-Ranges 响应头
        headers['content-range'] = '${rangeHeader.rangeUnit} ${rangeHeaderStart}-${rangeHeaderEnd - 1}/${body.length}'; // 添加 Content-Range 响应头
        return shelf.Response(isStreamMediaMimeTypes ? 206/* 安卓设备 range 请求返回 200 会导致无法正常播放 */ : 200, body: body.sublist(rangeHeaderStart, rangeHeaderEnd), headers: headers);
      }

      requestHeaders['referer'] = 'shelf'; // 请求头中修改 referer 字段
      requestHeaders['host'] = 'shelf'; // 请求头中修改 host 字段
      requestHeaders['user-agent'] = 'shelf'; // 请求头中修改 user-agent 字段
      requestHeaders['range'] = 'bytes=0-'; // 请求头中修改 Range 字段(请求整个文件)
      requestHeaders['accept-ranges'] = 'bytes'; // 请求头中修改 Accept-Ranges 字段(请求整个文件)
      // requestHeaders.remove('range');

      return Future.sync(() => innerHandler(request.change(headers: requestHeaders))).then((response) async {
        final _requestCacheControls = request.headersAll['cache-control'] ?? []; // 实际请求指令集
        final _responseCacheControls = response.headersAll['cache-control'] ?? []; // 实际响应指令集
        final isCache = responseCacheControls.any(_responseCacheControls.contains) || requestCacheControls.any(_requestCacheControls.contains); // 是否需要缓存

        if (!isCache) return response; // 如果不需要缓存，则直接返回
        final _completer = new Completer<List<int>>();
        final headers = Map<String, String>()..addAll(response.headers); // 提取将响应头
        final resultBytes = <int>[]; // 响应主体内容

        headers['server'] = 'shelf'; // 添加 server 响应头
        Talk.log('正在创建缓存头文件：${header.path}', name: 'SmallProgram');
        header.writeAsStringSync(headers.parseToString); // 将响应头写入缓存头文件(jsonString)

        final controller = response.read().listen(
          (newBytes) {
            Talk.log('正在接收缓存数据：${file.path}', name: 'SmallProgram');
            resultBytes.addAll(newBytes);
            if (resultBytes.length != response.contentLength) return;

            Talk.log('接收缓存数据完成：${request.url}}-${resultBytes.length}', name: 'SmallProgram');
            _completer.complete(resultBytes); // 手动完成，否则视频文件会一直等待
          },
          onDone: () => _completer.complete(resultBytes),
          onError: _completer.completeError,
          cancelOnError: true,
        );

        return _completer.future.then((result) {
         
          Talk.log('正在创建缓存主体文件：${file.path}', name: 'SmallProgram');
          file.writeAsBytesSync(resultBytes);
          Talk.log('创建缓存主体文件写入完成：${file.path}', name: 'SmallProgram');
          controller.cancel(); // 取消订阅
          return shelf.Response.ok(result, headers: headers, encoding: response.encoding, context: response.context);
        });

        // return response.read().reduce((previous, element) => [...previous, ...element]).then((result) { // TODO: 视频文件不会调用 reduce 方法，reduce 方法依赖 listen 中的 onDone 方法
        //   Talk.log('正在创建缓存主体文件：${file.path}', name: 'SmallProgram');
        //   file.writeAsBytesSync(result); // 将响应内容写入缓存文件(bytes)
        //   Talk.log('创建缓存主体文件写入完成：${file.path}', name: 'SmallProgram');
        //   return shelf.Response.ok(result, headers: response.headers, encoding: response.encoding, context: response.context);
        // });
      });
    };
  };
}
