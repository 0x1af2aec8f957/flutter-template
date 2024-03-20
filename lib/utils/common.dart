// 公共方法
import 'dart:async' show FutureOr;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, Clipboard, ClipboardData;

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

  Future<void> get copyWithClipboard => ClipboardHelper.copy(this); // 复制到粘贴板

  bool get isNumber => num.tryParse(this) != null; // 是否是数字
  num get parseWithNumber => num.tryParse(this) ?? 0; // 转换为数字
}

extension NumberHelper on num {
  static String get placeholder => numberPlaceholder; // 数字占位符

  String toStringByDigit([int digit = 0]) { // toStringAsFixed 不四舍五入的版本
    if (digit < 0 || digit > 20) return numberPlaceholder;
    if (digit == 0) return this.floor().toString();

    return this.toStringAsFixed(digit + 1).replaceFirst(RegExp(r'\d$'), ''); // 保留小数点后 digit 位，不四舍五入
  }
}

extension NullHelper on Null {
  String get fillWithString => this ?? StringHelper.placeholder;
  String get fillWithNumber => this ?? NumberHelper.placeholder;
}

/// 项目内部的通用方法
Future<void> openSchemaUri(Uri? uri) {
  if (uri == null) return Future.error('不是从schema协议启动的，停止跳转');
  return router.push('/example');
}