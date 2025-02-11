import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import './http.dart';
import '../setup/config.dart';
import '../plugins/dialog.dart';

final _wsUrl = Uri.https('example.com').replace(scheme: 'wss');

class CustomSocketClient {
  WebSocket? socket;
  bool isActivelyClose = false; // 是否主动关闭
  final Duration reconnectDelay = const Duration(seconds: 5); // 重连延迟

  CustomSocketClient._internal() {
    _init();
  }

  factory CustomSocketClient() => _instance;
  static late final CustomSocketClient _instance = CustomSocketClient._internal();

  get isConnected => socket?.readyState == WebSocket.open;

  Future<void> _init([bool isReset = false]) {
    return SharedPreferences.getInstance().then((prefs) => WebSocket.connect(
      _wsUrl.toString(),
      headers: {
        ...options.headers,
        "username": AppConfig.localHostname,
        "Authorization": prefs.getString('token'),
      },
      customClient: !AppConfig.isProduction ? (HttpClient(context: SecurityContext())..badCertificateCallback = (X509Certificate cert, String host, int port) {
        Talk.log('SimpleWebSocket: Allow self-signed certificate => $host:$port.', name: 'Webrtc');
        return true;
      }) : null,
    ).then((_socket) async {
      Talk.log('正在使用的凭证：${prefs.getString('token')}),\nConnected!', name: 'Socket');
      if (socket != null && isReset) { // 已经创建过连接，需要重置
        await socket?.close(); // 断开连接
        socket = null; // 释放资源
      }

      socket ??= _socket..listen(onMessage, onDone: onDone, onError: onError);
    }));
  }

  void onMessage(dynamic message) {
    Talk.log('收到 message : $message', name: 'Socket');
  }

  void onDone() {
    Talk.log('Done', name: 'Socket');
    if (!isActivelyClose) Future.delayed(reconnectDelay, reconnect); // 自动重连
  }

  void onError(error) {
    Talk.log('Error: $error', name: 'Socket');
    if (!isActivelyClose) Future.delayed(reconnectDelay, reconnect); // 自动重连
  }

  Future<void> sendMessage(String message) {
    Talk.log('发送消息: $message', name: 'Socket');
    return Future.doWhile(() {
      if (socket?.readyState == WebSocket.open) return false;
      return Future.delayed(reconnectDelay, () => true);
    }).then((_) => socket?.add(message));
  }

  Future<dynamic> close() async {
    Talk.log('Socket close', name: 'Socket');
    isActivelyClose = true;
    return socket?.close();
  }

  Future<void> reconnect() { // 重新连接（某些配置凭证更新后，将使用新的凭证进行连接）
    isActivelyClose = false;
    return _init(true);
  }
}