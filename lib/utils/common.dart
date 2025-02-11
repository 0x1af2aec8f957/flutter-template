// 公共方法
import 'dart:io' show Directory;
import 'dart:async' show FutureOr;
import 'dart:convert' show Utf8Encoder, base64Encode, json;
import 'package:crypto/crypto.dart' show Digest, md5;
import 'package:lpinyin/lpinyin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, Clipboard, ClipboardData;
import "package:collection/collection.dart" as collection;

import './constant.dart';
import '../setup/router.dart';
import '../plugins/dialog.dart';

final methodChannel = MethodChannel('com.template.flutter');

/// 模板通用的方法
extension ColorHelper on Color { /// NOTE: 普通类的扩展可直接调用: Colors.red.invert
  Color get invert => Color.fromARGB(alpha, 255 - red, 255 - green, 255 - blue); // 反色
}

extension FutureHelper<T> on Future<T> { /// NOTE: 抽象实例的扩展，需要使用 FutureHelper 调用: FutureHelper.doWhileByDuration
  static Future<void> doWhileByDuration(FutureOr<bool> Function() action, {Duration duration = Durations.extralong4}) => Future.doWhile(() => Future.sync(action).then((isDone) => isDone ? Future.delayed(duration, () => true) : Future.value(false))); // doWhile 的 duration 版本，间隔 duration 执行 action 直到 action 返回 false
  static Future<T?> sync<T>(FutureOr<T> Function()? action) => action == null ? Future<T?>.value(null) : Future<T>.sync(action); // 跟 Future.sync 一样，但是入参允许为 null
}

extension ClipboardHelper on Clipboard {
  static Future<void> copy(String? text, { isToast = true }) { // 复制到粘贴板
    if (text != null) return Clipboard
        .setData(ClipboardData(text: text))
        .then((r) => isToast ? Talk.toast('复制成功') : null);

    if (isToast) Talk.toast('复制失败');
    return Future.error('复制失败');
  }

  static Future<String?> paste() => Clipboard.getData(Clipboard.kTextPlain).then((data) => data?.text); // 粘贴
}

extension StringHelper on String {
  static String get placeholder => stringPlaceholder; // 字符串占位符

  String get pinyin => PinyinHelper.getPinyinE(this, separator: " ", defPinyin: '#'); // 获取汉字拼音，不支持转换的会使用 # 返回
  String get shortPinyin => PinyinHelper.getShortPinyin(this); // 获取汉字拼音首字母组合
  String get firstWordPinyin => PinyinHelper.getFirstWordPinyin(this); // 获取汉字拼音首字母

  Future<void> copyWithClipboard() => ClipboardHelper.copy(this); // 复制到粘贴板

  bool get isNumber => num.tryParse(this) != null; // 是否是数字
  num get parseToNumber => num.tryParse(this) ?? 0; // 转换为数字

  Digest get parseToMD5 => md5.convert(Utf8Encoder().convert(this)); // 转换为 MD5

  String get parseToBase64 => base64Encode(Utf8Encoder().convert(this)); // 转换为 Base64

  Map<String, dynamic> get parseToMap => this.isJsonString ? json.decode(this) : Map<String, dynamic>(); // 转换为 Map
  bool get isJsonString { // 是否是 jsonMap
    try {
      if (!this.startsWith('{') || !this.endsWith('}')) return false;
      return json.decode(this) is Map<String, dynamic>;
    } catch (_) {
      return false;
    }
  }

  int compareAsciiUpperCase(String str) => collection.compareAsciiUpperCase(this.shortPinyin, str.shortPinyin); // 比较两个字符串的 ASCII 大小
}

extension NumberHelper on num {
  static String get placeholder => numberPlaceholder; // 数字占位符

  String toStringByDigit([int digit = 0]) { // toStringAsFixed 不四舍五入的版本
    if (digit < 0 || digit > 20) return numberPlaceholder;
    if (digit == 0) return this.floor().toString();

    return this.toStringAsFixed(digit + 1).replaceFirst(RegExp(r'\d$'), ''); // 保留小数点后 digit 位，不四舍五入
  }

  String get size { // 数据大小格式化
    if (this < 1024) return '${this.toStringByDigit(2)} B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringByDigit(2)} KB';
    if (this < 1024 * 1024 * 1024) return '${(this / 1024 / 1024).toStringByDigit(2)} MB';
    if (this < 1024 * 1024 * 1024 * 1024) return '${(this / 1024 / 1024 / 1024).toStringByDigit(2)} GB';
    if (this < 1024 * 1024 * 1024 * 1024 * 1024) return '${(this / 1024 / 1024 / 1024 / 1024).toStringByDigit(2)} TB';

    return NumberHelper.placeholder;
  }
}

extension MapHelper on Map {
  String get parseToString => json.encode(this); // 转换为 jsonString
}

extension ListHelper on List {
  String get parseToString => json.encode(this); // 转换为 jsonString
  void sortToASCII() => sort((prev, cur) => prev.compareAsciiUpperCase(cur)); // 按照 ASCII 排序
}

extension NullHelper on Null {
  String get fillToString => StringHelper.placeholder;
  String get fillToNumber => NumberHelper.placeholder;
}

extension DirectoryHelper on Directory {
  Future<int> get fileSize => this.list(recursive: true).fold<int>(0, (sum, file) => sum + file.statSync().size); // 获取文件夹中所有文件大小
}

/// 项目内部的通用方法
Future<void> openSchemaUri(Uri? uri) { // 通过 schema 协议打开页面
  if (uri == null) return Future.error('不是从schema协议启动的，停止跳转');
  return router.push('${uri.path}?${uri.query}');
}