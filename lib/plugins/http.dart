import 'dart:io';
import 'dart:convert';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart' show md5;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './signer.dart';
import './dialog.dart';
import '../utils/common.dart';
import '../setup/config.dart';
import '../setup/router.dart' show router;
import '../components/NoPermission.dart';

/// doc: https://github.com/cfug/dio/blob/main/dio/README-ZH.md

final BaseOptions options = BaseOptions(// 单次请求的配置[Options]，可覆盖这里的基础配置
  baseUrl: 'https://www.example.com', //'"https://www.xx.com", // 请求基地址,可以包含子路径
  connectTimeout: Duration(seconds: 5), // 连接服务器超时时间，单位是毫秒
  receiveTimeout: Duration(seconds: 3), // 2.x中为接收数据的最长时限
  headers: <String, dynamic>{ // 公用headers，需要异步或者动态获取的值，在拦截器中设置
    'language': AppConfig.local.toString(), // 语言
    'platform': AppConfig.system, // 平台
  },
  // path: '', // 请求路径，如果 `path` 以 "http(s)"开始, 则 `baseURL` 会被忽略； 否则将会和baseUrl拼接出完整的的url. 已废弃，options有效。
  contentType: Headers.jsonContentType, // 请求的Content-Type，默认值是"application/json; charset=utf-8"
  responseType: ResponseType.json, // 期望以那种格式(方式)接受响应数据
  // responseType: ResponseType.plain, // 签名专用
  validateStatus: /*ValidateStatus*/(status) => status == 200,
  extra: <String, dynamic>{
    'signed': false, // 是否签名
    'refresh': true, // 接口是否刷新（缓存需要）
  }, // 自定义字段，可以在 [Interceptor]、[Transformer] 和 [Response] 中取到
  queryParameters: <String, dynamic /*String|Iterable<String>*/ >{ // 共用查询参数(可处理缓存故障！)

  }
);

class MainInterceptors extends InterceptorsWrapper { // 主要的处理拦截器
  final String basePath;

  MainInterceptors({ required this.basePath });

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final requestUri = Uri.parse(options.baseUrl);
    final packageInfo = await AppConfig.packageInfo;
    final deviceInfo = await AppConfig.deviceInfo;
    final deviceId = md5.convert(utf8.encode((await deviceInfo.deviceInfo).toString())).toString(); // 设备唯一标识
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    options.headers.addAll(<String, dynamic>{ // 需要实时更新的headers
      'device-id': deviceId, // 设备唯一标识
      'version': packageInfo.version, // 版本号
      'token': prefs.getString('token'), // 访问凭证
    });

    options.baseUrl = requestUri.replace(pathSegments: [...requestUri.pathSegments, ...Uri.parse(basePath).pathSegments]).toString(); // 拼接基准路径

    return handler.next(options);
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = response.data;

    switch (data['code']) {
      case 401: // 去登录
        prefs.remove('token');
        router.go('/login');
        return handler.reject(DioException(error : data['msg'] ?? '请登录', requestOptions: response.requestOptions), true);
      case 200: // 正常
      case 201: // 正常（创建新资源）
        response.data = data['data']; // 仅需要业务数据字段
        return handler.next(response);
    /* case 409: // 记录已经存在
        return super.onError(data['msg'] ?? '记录已经存在'); */
      default:
        return handler.reject(DioException(error: data['msg'] ?? '未知的服务器错误', type: DioExceptionType.badResponse, requestOptions: response.requestOptions), true);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    err.response?.statusCode == 403 ? NoPermission.open(AppConfig.navigatorContext) : Talk.toast(err.error?.toString() ?? err.message ?? '未知的网络错误');
    return handler.reject(err);
  }
}

class CacheInterceptor extends Interceptor { // 接口缓存拦截器
  CacheInterceptor();

  final _cache = Map<Uri, Response>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler){
    bool isCache = true; // 是否缓存

    if (options.data != null) isCache = false; // 请求中包含有数据不可缓存
    // if (options.method == 'POST') isCache = false; // 请求为post不可缓存

    final extra = options.extra;
    final Response? response = _cache[options.uri];

    if (response == null || extra["refresh"] == true) return handler.next(options); // 接口配置参数为最高优先级

    return isCache ? /* 提供单独的刷新 */ handler.next(response.requestOptions) : handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler){
    // TODO:必要的缓存才能缓存，非必要需要排除
    _cache[response.requestOptions.uri] = response;
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    return handler.reject(err);
  }
}

class MainTransformer extends BackgroundTransformer { // 主要的转换器,在拦截器之前执行

  @override
  Future<String> transformRequest(RequestOptions options) async { // 请求数据
    if (options.data is Map<String, dynamic>) {
      final extra = options.extra;

      // data 只有两种类型：FormData 或者 Map
      final data = options.contentType == Headers.formUrlEncodedContentType ? FormData.fromMap(options.data) : (options.data as Map).parseToString;

      if (extra['signed'] == true) { // 是否对数据进行签名
        return Crypto(options.uri).encrypt(data: data is String ? data : data.toString());
      }

      return super.transformRequest(options);
    }

    throw DioException(error: "只能处理发送数据为Map类型的数据", requestOptions: options);
  }

  // The [Options] doesn't contain the cookie info. we add the cookie
  // info to [Options.extra], and you can retrieve it in [ResponseInterceptor]
  // and [Response] with `response.request.extra["cookies"]`.
  @override
  Future<dynamic> transformResponse(RequestOptions options, ResponseBody response) async { // 接收数据
    final extra = options.extra;

    if (extra['signed'] == true && options.responseType == ResponseType.plain /* 接口签名必须使用该预期值 */) { // 是否对数据进行解码
      final responseText = await super.transformResponse(options, response);
      final responseBody = Crypto(options.uri).decrypt(data: responseText is String ? responseText :responseText.toString());
      return responseBody.parseToMap;
    }

    return super.transformResponse(options, response);
  }
}

class Http {
  static late final original = Dio()..httpClientAdapter = IOHttpClientAdapter(createHttpClient: AppConfig.isProduction ? () => HttpClient()..badCertificateCallback = (X509Certificate cert, String host, int port) => true/* 忽略证书错误 */: null); // 原始的 dio 实例
  late final Dio _dio = Dio(options);
  final String basePath; // 基准路径

  Http({ required this.basePath }) {
    _dio.transformer = MainTransformer(); // 数据转换处理
    _dio.interceptors // 拦截器：执行顺序 -> FIFO
      ..add(MainInterceptors(basePath: basePath)) // 主要的拦截器
      ..add(CacheInterceptor()); // 接口缓存

    assert(() { // debug 模式下运行, doc: https://api.flutter.dev/flutter/foundation/kDebugMode-constant.html
      _dio
        ..httpClientAdapter = IOHttpClientAdapter(createHttpClient: () => HttpClient()..badCertificateCallback = (X509Certificate cert, String host, int port) => true/* Verify the certificate */) // 忽略证书错误
        ..interceptors.add(PrettyDioLogger(
            compact: false,
            requestBody: true,
            responseBody: true,
            requestHeader: true,
            responseHeader: false,
            logPrint: (log) => Talk.log(log.toString(), name: 'HTTP'),
          ) // debug模式下打印log
        );
      return true;
    }());
  }

  Dio call() => _dio;
}
