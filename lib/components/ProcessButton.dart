import 'package:flutter/material.dart';

import '../utils/common.dart';

// extension ProcessButton on RawMaterialButton {}
class ProcessButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final EdgeInsetsGeometry margin;
  final double widthFactor;
  final ButtonStyle style; // default: ElevatedButton.styleFrom(shape: StadiumBorder()/* CircleBorder() | RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) |  BeveledRectangleBorder(borderRadius: BorderRadius.circular(12)*/)
  final Widget child;

  ProcessButton({
    super.key,
    ButtonStyle? style,
    this.onPressed,
    this.margin = EdgeInsets.zero,
    this.widthFactor = 1,
    this.child = const SizedBox.shrink(),
  }): style = style ?? ElevatedButton.styleFrom();

  @override
  State<ProcessButton> createState() => _ProcessButton();
}

class _ProcessButton extends State<ProcessButton> {
  bool isLoading = false;

  void handleClick() {
    if (widget.onPressed == null || isLoading) return null;

    setState(() {
      isLoading = true;
    });

    widget.onPressed?.call().whenComplete(() {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widget.widthFactor,
      child: Padding(
        padding: widget.margin,
        child: ElevatedButton(
          onPressed: () => isLoading ? null : handleClick(), // 为 null 时，按钮的样式为 MaterialState.disabled
          style: widget.style,
          // 去按钮背景颜色的反色
          child: isLoading ? CircularProgressIndicator(
            color: widget.style.backgroundColor?.resolve({MaterialState.disabled})?.invert,
            strokeWidth: 3
          ): widget.child
        ),
      ),
    );
  }
}