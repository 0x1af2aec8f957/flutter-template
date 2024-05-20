import 'package:flutter/material.dart';

import '../components/FullScreenWebView.dart';

class WebView extends StatelessWidget {
  final String src;

  const WebView({super.key, required this.src});

 @override
  Widget build(BuildContext context) {
    return FullScreenWebView(Uri.parse(src));
  }
}