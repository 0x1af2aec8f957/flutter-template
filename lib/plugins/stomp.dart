import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart' show ValueNotifier, UniqueKey, LocalKey;
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../setup/config.dart';
import '../utils/common.dart';
import '../plugins/dialog.dart';

final _wsUrl = Uri.https('example.com').replace(scheme: 'wss');

class CustomStompClient {
  StompClient? client; // Stomp 客户端
  final ValueNotifier<bool> isConnected = ValueNotifier(false); // 是否已连接（UI 更新可以使用 ValueListenableBuilder 构建）
  final Map<String, List<({ // 订阅记录
    LocalKey key,
    void Function(StompFrame) callback,
  })>> subscribeRecords = Map();
  final Map<String, void Function({Map<String, String>? unsubscribeHeaders})> unSubscribeTopicFunctions = Map(); // 取消订阅函数

  Future<StompConfig> get config {
    return SharedPreferences.getInstance().then((prefs) => StompConfig( // 配置文件
      url: _wsUrl.toString(),
      onConnect: onConnect,
      onStompError: onStompError,
      onDisconnect: onDisconnect,
      beforeConnect: onBeforeConnect,
      onDebugMessage: onDebugMessage,
      stompConnectHeaders: {
        "username": "username",
        "Authorization": prefs.getString('token') ?? '',
      },
      webSocketConnectHeaders: {
        "username": "username",
        "Authorization": prefs.getString('token') ?? '',
      },
    ));
  }

  CustomStompClient._internal() {
    _init();
  }

  factory CustomStompClient() => _instance;
  static late final CustomStompClient _instance = CustomStompClient._internal();

  Future<void> _init([bool isReset = false]) {
    return config.then((_config) {
      Talk.log('正在使用的凭证：${_config.stompConnectHeaders?['Authorization']}', name: 'Stomp');
      if (client != null && isReset) deactivate(); // 已经创建过连接，需要重置

      client ??= StompClient(config: _config); // 初始化
      activate(); // 自动连接
    });
  }

  void onConnect(StompFrame connectFrame) { // 连接
    isConnected.value = client?.connected ?? false;
    Talk.log('Connected', name: 'Stomp');
    subscribeRecords.forEach((topic, records) {
      subscribe(topic, null); // 重新订阅（重连时必须）
    });
    /* subscribe('/topic/greetings', (StompFrame frame) {
      Talk.log('/topic/greetings - Received: ${frame.body}', name: 'Stomp');
    });
    sendMessage('/app/hello', 'Hello, STOMP'); */
  }

  Future<void> onBeforeConnect() async { // 连接前
    isConnected.value = client?.connected ?? false;
    Talk.log('Waiting connect...', name: 'Stomp');
    await Future.delayed(const Duration(milliseconds: 200));
    Talk.log('Connecting...', name: 'Stomp');
  }

  void onStompError(StompFrame frame) { // 错误
    isConnected.value = client?.connected ?? false;
    Talk.log('Error: ${frame.body}', name: 'Stomp');
  }

  void onDisconnect(StompFrame frame) { // 断开连接
    isConnected.value = client?.connected ?? false;
    Talk.log('Disconnect', name: 'Stomp');
  }

  Future<LocalKey> subscribe(String topic, void Function(StompFrame frame)? callback, { Map<String, String>? headers }) { // 订阅
    final record = (key: UniqueKey(), callback: callback); // 本次生成的订阅记录
    if (callback != null) { // 订阅记录更新
      final _record = record as ({void Function(StompFrame) callback, LocalKey key});
      subscribeRecords.update(topic, (_records) => [..._records, _record], ifAbsent: () => [_record]);
    }

    return FutureHelper.doWhileByDuration(() => !isConnected.value).then((_) { // 等待 stomp 连接完成才能订阅
      unSubscribe(topic, clearRecords: false); // 取消上一次订阅
      final unSubscribeTopicFunction = client?.subscribe(
        destination: topic,
        callback: (StompFrame frame) => subscribeRecords[topic]?.forEach((item) => item.callback(frame)), // 执行所有订阅回调函数
        headers: headers,
      );

      if (unSubscribeTopicFunction != null) unSubscribeTopicFunctions[topic] = unSubscribeTopicFunction; // 记录取消订阅函数

      return record.key;
    });
  }

  void sendMessage(String topic, String? body, { Map<String, String>? headers, Uint8List? binaryBody }) { // 发送消息
    return client?.send(
      destination: topic,
      body: body,
      headers: headers,
      binaryBody: binaryBody,
    );
  }

  void unSubscribe(String topic, {LocalKey? key, bool clearRecords = true}) { // 取消订阅
    if (key != null) { // 仅取消指定订阅回调
      subscribeRecords[topic]?.removeWhere((item) => item.key == key);
      return;
    }

    // 取消所有订阅回调
    if (clearRecords) subscribeRecords.remove(topic); // 移除订阅回调函数记录
    unSubscribeTopicFunctions[topic]?.call(); // 执行取消订阅函数
    unSubscribeTopicFunctions.remove(topic); // 移除取消订阅函数记录
  }

  void activate() { // 连接
    isConnected.value = client?.connected ?? false;
    client?.activate();
  }

  void deactivate() { // 断开连接
    isConnected.value = client?.connected ?? false;
    client?.deactivate();
    client = null; // 释放资源
  }

  void onDebugMessage(String message) { // 调试信息
    if (!AppConfig.isProduction) Talk.log(message, name: 'Stomp');
  }

  Future<void> reconnect() { // 重新连接（某些配置凭证更新后，将使用新的凭证进行连接，仅仅是断开重连无需执行该方法，StompClient 本身携带断开重连机制）
    return _init(true);
  }

  void dispose() { // 销毁（会释放 isConnected ，不可再次直接使用）
    deactivate();
    isConnected.dispose();
  }
}