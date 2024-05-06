import 'package:flutter/material.dart';

import './CustomImage.dart';

/// 自定义头像
class Avatar extends StatelessWidget {
  final String? url;
  final double width;
  final double? radius;
  final double opacity;
  final Map<String, String>? headers;
  final Widget errorWidget;

  const Avatar({
    super.key,
    this.url,
    this.width = 50,
    this.radius,
    this.headers,
    this.opacity = 1,
    this.errorWidget = const Icon(Icons.person),
  });

  static Group({
    required List<String> urls,
    double width = 50,
    double radius = 0,
    Map<String, String>? headers,
    double opacity = 1,
    Widget errorWidget = const Icon(Icons.person),
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Wrap(
        spacing: 1,
        runSpacing: 1,
        children: [
          for (final url in urls) Avatar(
            url: url,
            width: (width - 3) / 2,
            radius: radius,
            headers: headers,
            opacity: opacity,
            errorWidget: errorWidget,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomImage(
      url: url,
      width: width,
      radius: radius,
      headers: headers,
      opacity: opacity,
      errorWidget: errorWidget,
      hasPlaceholder: false,
    );
  }
}