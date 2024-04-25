import 'dart:io';
import 'dart:convert';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../setup/config.dart';
import '../plugins/dialog.dart';
import '../utils/common.dart';

typedef Callback = void Function(String topic, dynamic payload);
final _cacheQueue = Map<String, Callback>(); // 缓存队列

/// MQTT-SERVICE
class _MQTTService {
  /// MQTT自身代码封装
  get _transitionState => _cacheQueue.isEmpty; // 过渡切换状态[为true才会执行订阅后的回调函数]
  MqttServerClient? client;

  /*
  final String serverAddress; // 订阅地址
  final String username; // 用户名
  final String password; // 密码
  final int port; // 端口


  _MQTTService({
    this.serverAddress,
    this.username,
    this.password,
    this.port
  });
  */

  get isConnected => client?.connectionStatus?.state == MqttConnectionState.connected; // MQTT是否处于连接状态
  get isDisconnected => client?.connectionStatus?.state == MqttConnectionState.disconnected; // MQTT是否处于断开状态

  // 连接成功
  void onConnected() {
    Talk.log('已成功连接', name: 'MQTT-client');
  }

  // 重新连接
  void onAutoReconnect() {
    Talk.log('正在重新连接', name: 'MQTT-client');
  }

  // 重新连接成功
  void onAutoReconnected() {
    Talk.log('重连成功', name: 'MQTT-client');
  }

  // 连接断开
  void onDisconnected() {
    Talk.log('连接断开', name: 'MQTT-client');
  }

  // 订阅主题成功
  void onSubscribed(String topic) {
    Talk.log('订阅成功: $topic', name: 'MQTT-client');
  }

  // 订阅主题失败
  void onSubscribeFail(String topic) {
    _cacheQueue.remove(topic);
    Talk.log('订阅失败: $topic', name: 'MQTT-client');
  }

  // 成功取消订阅
  void onUnsubscribed(String? topic) {
    _cacheQueue.remove(topic);
    Talk.log('取消订阅: $topic', name: 'MQTT-client');
  }

  // 收到 PING 响应
  void pong() {
    Talk.log('收到心跳唤醒', name: 'MQTT-client');
  }

  /// 业务定制功能
  // 手动连接
  Future<void> get connect async{
    Talk.log('正准备尝试连接', name: 'MQTT-client');
    if (client != null) return; // 已实例化则不再执行实例化
    // 未实例化才开始执行实例化
    final DeviceInfoPlugin deviceInfoPlugin = AppConfig.deviceInfo; // 获取设备信息
    final Future<String>? fetchIdentifier = // 获取设备唯一标识码
    AppConfig.platform == 'android'
        ? deviceInfoPlugin.androidInfo.then((AndroidDeviceInfo build) => build.androidId) // android
        : AppConfig.platform == 'ios'
          ? deviceInfoPlugin.iosInfo.then((IosDeviceInfo build) => build.identifierForVendor) // ios
          : null;

    final String? identifier = await fetchIdentifier; // 使用设备唯一编码作为MQTT-clientID的一部分，防止重复的ID被踢下线

    /**
     * EMQ_X测试地址
     * host: broker.emqx.io
     * client_id: flutter_client
     * port: 1883
     * */
    client = MqttServerClient.withPort('broker.emqx.io', '' /* 使用MqttConnectMessage进行构造后，这里的client_id将被忽略 */, 1883)
      ..secure = false
      ..securityContext = SecurityContext.defaultContext
      ..onConnected = onConnected
      ..onAutoReconnect = onAutoReconnect
      ..onAutoReconnected = onAutoReconnected
      ..onDisconnected = onDisconnected
      ..onUnsubscribed = onUnsubscribed
      ..onSubscribed = onSubscribed
      ..onSubscribeFail = onSubscribeFail
      ..pongCallback = pong
      ..keepAlivePeriod = 60
      ..logging(on: !AppConfig.isProduction);

    client?.connectionMessage = MqttConnectMessage()
      ..withClientIdentifier('${AppConfig.platform.toLowerCase()}-${identifier?.toLowerCase() ?? DateTime.now().millisecondsSinceEpoch}') // client_id
      ..authenticateAs('mqtt_example', 'mqtt_example')
      // ..withProtocolName('MQIsdp')
      // ..withProtocolVersion(3)
      ..withWillRetain()
      ..withWillTopic('will topic')
      ..withWillMessage('will message')
      ..withWillQos(MqttQos.atLeastOnce /* MqttQos.atMostOnce */)
      ..startClean();

    await client
        ?.connect() // 异步函数(开始连接)
        .then((value){
      Talk.log('连接成功: ${value?.state}', name: 'MQTT-client');
    }).catchError((err){
      Talk.log('连接失败: $err', name: 'MQTT-client');
      client?.disconnect();
    });

    client?.updates // 处理推送消息
        ?.listen((List<MqttReceivedMessage<MqttMessage>>? message) { // 收到消息推送
          if (message == null) return;
          final String? topic =  message[0].topic;
          final MqttPublishMessage? _message = message[0].payload as MqttPublishMessage;

          if (topic == null || _message == null) return; // 广播数据有误需要退出
          if (_transitionState || !_cacheQueue.containsKey(topic)) return; // 本地未订阅该条数据不予处理

          final Callback? callback = _cacheQueue[topic];
          // final String payload = MqttPublishPayload.bytesToStringAsString(_message.payload.message); // 使用自带的解析器会导致中文乱码，可用Utf8Decoder代替
          final String payload = MqttPublishPayload.bytesToStringAsString(_message.payload.message);
          Talk.log('收到订阅:$topic', name: 'MQTT-client');
          Talk.log('消息推送:$payload', name: 'MQTT-client');
          if (callback != null) callback(topic, payload.parseWithJson);
        });
  }

  // 手动再次连接
  Future<void> get reconnect async{
    Talk.log('正准备尝试重连', name: 'MQTT-client');
    if (isDisconnected) await client?.connect();
  }

  // 手动关闭连接
  void get close{
    Talk.log('正准备尝试关闭连接', name: 'MQTT-client');
    return client?.disconnect();
  }

  // 发布订阅
  void publish(String topic, String message){
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    final _buf = typed.Uint8Buffer();

    _buf.addAll(Utf8Encoder().convert(message));
    builder.addBuffer(_buf);

    client?.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!); // builder.payload也是可用的
  }

  // 添加订阅
  void subscribe(String topic, Callback callback){
    _cacheQueue.putIfAbsent(topic, () => callback); // TODO 插入或替换队列中的回调函数
    Talk.log('正在订阅: $topic', name: 'MQTT-client');
    if (topic.isNotEmpty && topic != null && isConnected) {
      client?.subscribe(topic, MqttQos.exactlyOnce);
    }
  }

  // 取消订阅
  void unsubscribe(String topic){
    _cacheQueue.remove(topic);
    Talk.log('正在取消订阅: $topic', name: 'MQTT-client');
    if (topic.isNotEmpty && topic != null && isConnected) {
      client?.unsubscribe(topic);
    }
  }
}

_MQTTService mqttService = _MQTTService();
