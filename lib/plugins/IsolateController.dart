import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../plugins/dialog.dart';

typedef _EntryPoint = void Function(SendPort port/* 外部 SendPort */, SendPort _port/* 内部 SendPort */);
typedef _MessageCallback = void Function(dynamic message/* 收到的消息 */, {SendPort? port/* 相对 SendPort */});
/// Isolate 控制器
class IsolateController {
  late Isolate _instance; // Isolate 实例
  late SendPort _sendPort; // 内部 SendPort

  final String debugName;
  final ReceivePort receivePort; // 外部 ReceivePort
  late final RootIsolateToken? rootIsolateToken = RootIsolateToken.instance; // 根隔离标识

  SendPort get sendPort => receivePort.sendPort; // 外部 SendPort
  void Function({int priority}) get kill => _instance.kill;
  Capability Function([Capability? resumeCapability]) get pause => _instance.pause;
  void Function(Capability resumeCapability) get resume => _instance.resume;
  void Function(SendPort responsePort, {Object? response, int priority}) get ping => _instance.ping;

  IsolateController(_EntryPoint entryPoint, {
    this.debugName = 'isolate-controller',
    ReceivePort? receivePort,
    _MessageCallback? onData, // 外部收到内部消息回调
    _MessageCallback? onMessage, // 内部收到外部消息回调，NOTE: 该回调函数在另一个隔离沙盒中运行，请注意代码上下文满足 top-level 规则
  }): receivePort = receivePort ?? ReceivePort() {
    Isolate.spawn<(SendPort, {
      String name,
      RootIsolateToken? token,
      _EntryPoint entryPoint,
      _MessageCallback? onMessage
    })>((argument) {
        if (argument.token != null) BackgroundIsolateBinaryMessenger.ensureInitialized(argument.token!); // doc: https://docs.flutter.dev/perf/isolates#using-platform-plugins-in-isolates
        final ReceivePort _receivePort = new ReceivePort(); // 内部 ReceivePort（不支持在外部传出: https://api.dart.dev/dart-isolate/SendPort/send.html）

        _receivePort.listen((message) { // 接收到外部传入消息
          Talk.log("外部传入的消息:\n" + message, name: argument.name);
          argument.onMessage?.call(message, port: argument.$1);
        });

        argument.$1.send(_receivePort.sendPort); // 将内部 SendPort 发送到外部
        argument.entryPoint(argument.$1, _receivePort.sendPort);
      },
      (sendPort, name: debugName, token: rootIsolateToken, entryPoint: entryPoint, onMessage: onMessage), // 传入外部 SendPort
      debugName: debugName,
    ).then((_isolate) => _instance = _isolate);

    this.receivePort.listen((message) { // 接收到内部传出消息
      if (message is SendPort) {
        _sendPort = message;
        Talk.log("内部传出的 SendPort, 已存入外部 _sendPort", name: debugName);
        return;
      }

      Talk.log("内部传出的消息:\n" + message, name: debugName);
      onData?.call(message, port: _sendPort);
    });
  }

  Never exit() {
    // receivePort.close();
    return Isolate.exit(sendPort);
  }

  static Future<R> run<M, R>(ComputeCallback<M?, R> callback, { // 短暂的隔离环境，支持自动判断有无外部消息
    M? message,
    String debugLabel = 'isolate-controller',
  }) {
    if(message == null) return Isolate.run(() => callback(null), debugName: debugLabel); // 独立执行，不依赖外部传入的消息
    return compute<M, R>(callback, message, debugLabel: debugLabel); // 需要从外部传入必要的消息完成执行
  }
}

/*
  /// 使用示例:
  final bool isInitLoading = false;
  void log(){
    debugPrint('test: ${isInitLoading}');
  }

  final IsolateController isolateController = IsolateController((outside, inside) { // 不能调用 主 Isolate 的代码
    Future.delayed(Duration(seconds: 5), () => outside.send('Outside sendPort by entryPoint'));
    Future.delayed(Duration(seconds: 8), () => inside.send('Inside sendPort by entryPoint'));
  }, onData: (message, {port}) {
    log();
    Talk.log('onData 接收到消息: ${message}');
    if(message.toString().endsWith('entryPoint')) port?.send('测试 onData 发出的消息');
  }, onMessage: (message, {port}) { // 不能调用 主 Isolate 的代码
    Talk.log('onMessage 接收到消息: ${message}');
    if(message.toString().endsWith('entryPoint')) port?.send('测试 onMessage 发出的消息');
  });

  void testExit() {
    isolateController.exit();
  }
*/