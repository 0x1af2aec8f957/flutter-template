import 'dart:io';
import 'package:dio/dio.dart' show RequestOptions, ResponseType;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import './QrCode/Index.dart';
import '../utils/common.dart';
import '../setup/config.dart';
import '../plugins/http.dart';
import '../plugins/dialog.dart';
import '../plugins/cssColor.dart';
import './FullScreenWebView.dart';

typedef WebViewCreatedCallback = void Function(WebViewController controller); // 创建 WebView 回调
typedef AppLifecycleStateChange = Future<void> Function(AppLifecycleState state); // WebView 生命周期变更执行
typedef PageDOMContentChangeCallback = void Function(JavaScriptMessage message); // 页面 DOM 发生变更执行
typedef PageSystemOverlayStyleChange = void Function(Color color, SystemUiOverlayStyle systemOverlayStyle); // 页面 DOM 主题色发生变更执行

const allowRequestSchemes = [ // 允许 webview 跳转的链接，不允许处理的链接将在外部使用默认打开方式进行打开
  'HTTP',
  'HTTPS',
];

class CustomWebView extends StatefulWidget {
  final String? url;
  final WebViewCreatedCallback? onWebViewCreated;

  // 自定义扩展事件，不需要依赖对接WEB才能完成的操作
  final AppLifecycleStateChange? onLifecycleStateChange; // webview 生命周期变更执行
  final PageDOMContentChangeCallback? onPageDOMContentChangeCallback; // 页面DOM发生变更执行
  final PageSystemOverlayStyleChange? onPageSystemOverlayStyleChange; // DOM主题色发生变更执行

  CustomWebView({
    super.key,
    this.url,
    this.onWebViewCreated,
    this.onLifecycleStateChange,
    this.onPageDOMContentChangeCallback,
    this.onPageSystemOverlayStyleChange,
  });

  @override
  State<StatefulWidget> createState() => _CustomWebView();
}
class _CustomWebView extends State<CustomWebView> {
  final WebViewController controller = WebViewController.fromPlatformCreationParams(WebViewPlatform.instance is WebKitWebViewPlatform ? WebKitWebViewControllerCreationParams(mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{}, allowsInlineMediaPlayback: true/* 允许自动及内联播放 */) : const PlatformWebViewControllerCreationParams());
  final _picker = ImagePicker();
  bool isLoading = true; // 是否正在加载中

  Future<List<String>> _androidFilePicker(FileSelectorParams params) async { // android 选择文件
    Talk.log(params.acceptTypes.toString(), name: 'AndroidWebView 请求的选择文件 MIME 类型');
    if (params.acceptTypes.any((type) => type == 'image/*')) {
      await widget.onLifecycleStateChange?.call(AppLifecycleState.paused); // 应用即将进入后台
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      await widget.onLifecycleStateChange?.call(AppLifecycleState.resumed); // 应用已经进入前台
      return photo == null ? [] : [Uri.file(photo.path).toString()];
    }

    if (params.acceptTypes.any((type) => type == 'video/*')) {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      return (video == null) ? [] : [Uri.file(video.path).toString()];
    }

    return [];
  }

  @override
  void initState() {
    super.initState();

    controller
      ..enableZoom(false)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) { // Update loading bar.
            Talk.log(progress.toString(), name: 'webview 加载进度');
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            controller.runJavaScript(""" // 给 webview 提供监听 DOM 元素变化的能力
                /// DOM变化监听
                var ___observer = new MutationObserver(function(mutationList){
                  if (typeof window._DOMContentChange !== 'undefined') window._DOMContentChange.postMessage(JSON.stringify(mutationList||[]));
                });
                ___observer.observe(document.body, { childList: true, attributes: true, subtree: true });
                window.addEventListener('beforeunload', function(event){ // 用户离开前
                  ___observer.disconnect();
                  // Cancel the event as stated by the standard.
                  // event.preventDefault(); // 需要弹出离开确认框时，取消注释
                  // Chrome requires returnValue to be set.
                  // event.returnValue = ''; // 需要弹出离开确认框时，取消注释
                });

                /// DOM主题色监听
                var ___el = Array.from(document.getElementsByTagName('head')).shift().querySelector("[name='theme-color']");
                if (___el !== null && typeof ___el !== 'undefined' && typeof window._SystemOverlayStyleChange !== 'undefined') window._SystemOverlayStyleChange.postMessage(___el.getAttribute('content'));
            """);

            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            Talk.log(error.description, name: 'webview 加载错误');
          },
          onNavigationRequest: (NavigationRequest request) { // webview 无法打开的链接 在外部尝试打开
            final uri = Uri.parse(request.url);
            if (allowRequestSchemes.any(uri.isScheme)) return NavigationDecision.navigate; // 允许请求的协议

            return canLaunchUrl(Uri.parse(request.url)).then((isCanLaunch) { // 外部能处理的协议，尝试使用外部默认打开方式处理，并阻止继续导航（canLaunchUrl 需要额外的权限描述：https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher#configuration）
              if (isCanLaunch) launchUrl(Uri.parse(request.url)).then((isLaunched) => isLaunched ? NavigationDecision.prevent : NavigationDecision.navigate); // 外部处理成功，阻止继续导航；外部处理失败，允许继续导航

              return NavigationDecision.prevent;
            });
          },
        ),
      )
      ..addJavaScriptChannel('_DOMContentChange', onMessageReceived: (message) { // DOM 变化
        if (widget.onPageDOMContentChangeCallback != null) widget.onPageDOMContentChangeCallback?.call(message);
      })
      ..addJavaScriptChannel('_SystemOverlayStyleChange', onMessageReceived: (message) { // DOM 主题色变化
        final Color _themeColor = CssColor(message.message);
        final SystemUiOverlayStyle _systemOverlayStyle = _themeColor.computeLuminance() < 0.5 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
        if (widget.onPageSystemOverlayStyleChange != null) widget.onPageSystemOverlayStyleChange?.call(_themeColor, _systemOverlayStyle);
      })
      ..addJavaScriptChannel('injectPlatformInfo', onMessageReceived: (message) { // 平台信息 注入
        AppConfig.deviceInfo.deviceInfo.then((value) => controller.runJavaScript("window._platformInfo='${value.data.toString()}'"));
      })
      ..addJavaScriptChannel('injectPackageInfo', onMessageReceived: (message) { // 包信息 注入
        AppConfig.packageInfo.then((value) => controller.runJavaScript("window._packageInfo='${value.toString()}'"));
      })
      ..addJavaScriptChannel('getDeviceId', onMessageReceived: (message) async { // 获取设备 deviceId
        final deviceInfo = AppConfig.deviceInfo;
        String? deviceId;

        if (Platform.isAndroid) deviceId ??= (await deviceInfo.androidInfo).id;
        if (Platform.isIOS) deviceId ??= (await deviceInfo.iosInfo).identifierForVendor;

        deviceId ??= (await deviceInfo.deviceInfo).toString().parseToMD5.toString();
        controller.runJavaScript("window.getDeviceIdCallback('${deviceId}')");
      })
      ..addJavaScriptChannel('request', onMessageReceived: (message) { // 跨域请求
        final options = message.message.parseToMap; // 解析参数
        // if (options is! Map) return; // 必须传入 可解析为 RequestOptions 的 Map 参数
        if (options['path'] == null || options['baseUrl'] == null) return; // 必须传入 path 或 baseUrl

        Http.original.fetch(RequestOptions( // 发起请求
          path: options['path'] ?? '',
          baseUrl: options['baseUrl'] ?? '',
          method: options['method'] ?? 'GET',
          data: options['data'] ?? {},
          queryParameters: options['queryParameters'] ?? {},
          headers: options['headers'] ?? {},
          contentType: options['contentType'] ?? 'application/json',
          responseType: options['responseType'] ?? ResponseType.json,
        )).then((value) => controller.runJavaScript("window.requestCallback('${value.data is String ? value.data : (value.data as Map).parseToString}')"));
      })
      ..addJavaScriptChannel('openUrl', onMessageReceived: (message) async { // 使用外部默认打开方式打开链接
        if (await canLaunchUrl(Uri.parse(message.message))) launchUrl(Uri.parse(message.message)); // canLaunchUrl 需要额外的权限描述：https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher#configuration
      })
      ..addJavaScriptChannel('openWebView', onMessageReceived: (message) { // 打开全屏 webview
        FullScreenWebView.open(context, url: message.message);
      })
      ..addJavaScriptChannel('openNativeView', onMessageReceived: (message) { // 打开主程序 view
        context.push<void>(message.message);
      })
      ..addJavaScriptChannel('openScan', onMessageReceived: (message) { // 打开 扫码界面
        QrCodeScanPage.open<String>(context).then((result) {
          if (result != null) controller.runJavaScript("window.scanCallback('$result')"); // 将扫码结果返回给小程序
        });
      });

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(!AppConfig.isProduction); // android debug
      // (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      (controller.platform as AndroidWebViewController)
        ..setTextZoom(100) // 字体大小不跟随系统变化
        ..setOnShowFileSelector(_androidFilePicker)
        ..setMediaPlaybackRequiresUserGesture(false); // 允许自动播放
    }

    if (controller.platform is WebKitWebViewController) {
      (controller.platform as WebKitWebViewController)
        ..setInspectable(!AppConfig.isProduction) // ios debug
        ..setAllowsBackForwardNavigationGestures(true); // 允许手势返回
    }

    if (widget.url != null) controller.loadRequest(Uri.parse(widget.url!)); // 加载网页地址
    widget.onWebViewCreated?.call(controller);
  }

  @override
  Widget build(BuildContext context) { // 用于构建Widget子树
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) => didPop ? null : controller.canGoBack().then((isCanBack) {
          if (isCanBack) { // webview 可以返回
            controller.goBack();
            return;
          }

          if (Navigator.of(context).canPop() && ModalRoute.of(context)!.isCurrent) { // 主程序 可以返回
            Navigator.of(context).pop();
            return;
          }

          Talk.alert("确认退出？").then((bool? shouldPop) { // 都无法返回，弹窗确认是否退出应用
            if (shouldPop ?? false) exit(0);
          });
      }),
      child: SafeArea(
        child: isLoading
          ? Center(child: CircularProgressIndicator())
          : WebViewWidget(
              controller: controller,
              gestureRecognizers: [
                Factory<LongPressGestureRecognizer>(() => LongPressGestureRecognizer()), // 允许长按复制文本
              ].toSet(),
          ),
      ),
    );
  }
}
