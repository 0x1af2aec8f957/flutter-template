import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' show WebViewController;

import './CustomWebview.dart';

/// 带控制按钮的全屏 webview 组件

class FullScreenWebView extends StatefulWidget {
  final Uri url;
  final double iconSize = 18;
  final double marginSize = 10;
  const FullScreenWebView(this.url, {super.key});

  @override
  _FullScreenWebView createState() => _FullScreenWebView();

  static Future<void> open(BuildContext context, {required Uri url}) => Navigator.of(context).push(PageRouteBuilder( // 打开 webview
    pageBuilder: (context, animation, secondaryAnimation) => FullScreenWebView(url),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0, 1);
      const end = Offset.zero;
      const curve = Curves.ease;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  ));
}

class _FullScreenWebView extends State<FullScreenWebView> {
  WebViewController? controller;

  Icon get ReloadIcon => Icon(Icons.refresh, size: widget.iconSize, color: Colors.white);
  Icon get CloseIcon => Icon(Icons.close, size: widget.iconSize, color: Colors.white);

  ButtonStyle get iconButtonStyle => IconButton.styleFrom(
    backgroundColor: Colors.transparent,
    padding: EdgeInsets.zero,
  );

  FutureOr<void> handleReload() {
    controller?.clearCache();
    return controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          CustomWebView(
            url: widget.url,
            onWebViewCreated: (_controller) => controller = _controller,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + widget.marginSize,
            right: widget.marginSize,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: '重新加载',
                    icon: ReloadIcon,
                    style: iconButtonStyle,
                    visualDensity: VisualDensity.compact,
                    onPressed: handleReload,
                  ),
                  Container(
                    width: 2,
                    color: Colors.grey,
                    height: CloseIcon.size,
                    margin: EdgeInsets.symmetric(horizontal: 1),
                  ),
                  // FractionallySizedBox(heightFactor: 1, child: CustomVerticalDivider(width: 1, color: Colors.black,)),
                  IconButton(
                    tooltip: '关闭',
                    icon: CloseIcon,
                    style: iconButtonStyle,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.pop(context) : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}