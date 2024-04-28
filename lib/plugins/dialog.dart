import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import '../setup/config.dart';
import '../components/CustomDivider.dart';

typedef _LogType = void Function(String, {Object? error, int level, String name, int? sequenceNumber, StackTrace? stackTrace, DateTime? time, Zone? zone});

abstract class Talk {
  static void toast(String text, {int duration = 2}) {
    final insert = AppConfig.navigatorOverlay.insert;
    final OverlayEntry entry = OverlayEntry( // OverlayEntry本身使用Stack布局将自身放置在视图最顶层，应当避免再次使用Stack
      builder: /* Widget */(_) => Positioned(
        bottom: 50.0,
        child: Container(
          padding: MediaQuery.of(_).viewInsets, // 解决键盘弹起，提示信息被遮挡的问题
          width: MediaQuery.of(_).size.width,
          alignment: Alignment.center,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0) /* EdgeInsets.all(8) */,
              child: Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 14.0, decoration: TextDecoration.none),
              ),
            ),
            color: Colors.black.withOpacity(0.5),
          ),

        ),
      ),

      /*Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            bottom: 50.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3.0), // 3像素圆角
              ),
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
              // alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 14.0, decoration: TextDecoration.none),
              ),
            ),
          ),
        ],
      ),*/
    );

    // Overlay.of(navigatorContext).insert(entry);
    insert(entry);

    Future.delayed(Duration(seconds: duration), () => entry.remove());
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackBar(Widget content, {BuildContext? context, SnackBarAction? action, Duration duration = const Duration(seconds: 4)}) { // 底部提示信息
    final instance = ScaffoldMessenger.of(context ?? AppConfig.navigatorContext)..removeCurrentSnackBar()/* 移除上一次的 snackBar */;
    return instance.showSnackBar(SnackBar(content: content, duration: duration, action: action));
  }

  static ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason> materialBanner(Widget content, {BuildContext? context, List<Widget> actions = const []}) { // 顶部提示信息（会一直展示，除非主动关闭）
    final instance = ScaffoldMessenger.of(context ?? AppConfig.navigatorContext)..removeCurrentMaterialBanner()/* 移除上一次的 materialBanner */;
    return instance.showMaterialBanner(MaterialBanner(
      content: content,
      actions: actions.map((action) => Overlay( // Tootip类的按钮需要手动添加 Overlay, issue: https://stackoverflow.com/questions/61087158/materialapp-builder-error-no-overlay-widget-found
        initialEntries: [
            OverlayEntry(
              canSizeOverlay: true,
              builder: (_) => action,
            ),
          ],
      )).toList(),
    ));
  }

  static Future<void> loading([String text = "请稍后..."]) {
    return showDialog<void>(
      context: AppConfig.navigatorContext,
      barrierDismissible: false, //点击遮罩不关闭对话框
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(), // CupertinoActivityIndicator(),
              Padding(
                padding: const EdgeInsets.only(top: 26.0),
                child: Text(text),
              )
            ],
          ),
        );
      },
    );
  }

  static Future<bool> alert(String text, {bool isCancel = true, String title = '提示'}) {
    return showDialog<bool>(
      context: AppConfig.navigatorContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: <Widget>[
            /*Offstage( // 需要隐藏后维护状态，请使用Visibility
              offstage: isCancel,
              child: TextButton(
                child: Text("取消"),
                onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.of(context).pop(false) : null,
              ),
            ),*/
            if (isCancel) TextButton(
              child: Text("取消"),
              onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.of(context).pop(false) : null,
            ),
            TextButton(
              child: Text("确认"),
              onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.of(context).pop(true) : null,
            ),
          ],
        );
      },
    ).then((bool? isConfirm) => isConfirm ?? false);
  }

  static Future<T?> sheetAction<T>({List<Widget> children = const <Widget>[], bool isCancel = true}) {
    return showModalBottomSheet<T>(
      context: AppConfig.navigatorContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...children,
            if (isCancel) CustomDivider(height: 5, color: Colors.grey),
            if (isCancel) SafeArea(
              child: TextButton(
                onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.of(context).pop() : null,
                child: Text('取消', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        );
      }
    );
  }

  static Future<bool> sheetAlert(String text, {bool isCancel = true}) {
    return sheetAction<bool>(
      isCancel: isCancel,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(text, style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ),
          subtitle: Column(
            children: [
              CustomDivider(height: 1, color: Colors.grey.withOpacity(0.2)),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.of(context).pop(true) : null,
                  child: Text('确定', style: TextStyle(color: Colors.red)),
                )
              ),
            ],
          ),
        ),
      ]
    ).then((bool? isConfirm) => isConfirm ?? false);
  }

  static _LogType get log => developer.log;
}