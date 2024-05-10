import 'dart:convert';
import 'dart:typed_data';

import '../utils/common.dart';

/// 自定义协议生成与解析（适用于内部通讯处理）
/// ${_protocol}://${userName}@${userId}/${action}?${queryParameters}#${describe}

const String _protocol = 'example';

class CustomProtocol {
  Uri get location => Uri.parse(uri);
  final String uri;

  const CustomProtocol(this.uri);

  String get userId => Uri.decodeComponent(location.host); // 用户ID
  String get action => Uri.decodeComponent(location.path); // 目标动作
  String get protocol => Uri.decodeComponent(location.scheme); // 协议（固定不变）
  String get username => Uri.decodeComponent(location.userInfo); // 用户名
  int get port => location.port; // 端口（请勿使用，始终为null）
  Map<String, String> get queryParameters => location.queryParameters.map((String key, String value) => MapEntry(Uri.decodeComponent(key), Uri.decodeComponent(value))); // 携带的参数
  String get describe  => Uri.decodeComponent(location.fragment); // 描述或备注

  factory CustomProtocol.fromLocation({ // 解析成来自协议标准参数的协议对象
    required String userId,
    required String action,
    required String username,
    String? describe,
    Map<String, String>? queryParameters
  }) {
    queryParameters?.putIfAbsent('timeStamp', DateTime.now().millisecondsSinceEpoch.toString); // 添加触发时间参数（单位：毫秒）

    return CustomProtocol(Uri(
      scheme: _protocol,
      host: userId,
      userInfo: username,
      port: null,
      path: action,
      queryParameters: queryParameters,
      fragment: describe
    ).toString());
  }

  factory CustomProtocol.fromBase64(String base64Href) { // 解析来自base64编码的字符串
    final Uint8List _href = base64Decode(base64Href);
    return CustomProtocol(Uri.decodeComponent(utf8.decode(_href)));
  }

  factory CustomProtocol.tryFromBase64(String base64Href) { // 解析来自base64编码的字符串
    try {
      return CustomProtocol.fromBase64(base64Href);
    } catch(e) {
      throw Exception('Protocol.tryFromBase64: $e');
    }
  }

  String toString() { // 转成字符串
    return Uri.decodeComponent(location.toString());
  }

  String toBase64() { // 转成base64编码的字符串
    return Uri.encodeComponent(location.toString()).parseToBase64;
  }
}