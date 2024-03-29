import 'package:flutter/material.dart';

import '../utils/common.dart';

typedef Future<void> _FutureVoidCallBack();

// extension ProcessButton on RawMaterialButton {}

class ProcessButton extends StatelessWidget {
  final _FutureVoidCallBack? onPressed;
  // final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHighlightChanged;
  final MouseCursor? mouseCursor;
  final TextStyle? textStyle;
  final Color? fillColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final double elevation;
  final double focusElevation;
  final double hoverElevation;
  final double highlightElevation;
  final double disabledElevation;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VisualDensity visualDensity;
  final BoxConstraints constraints;
  final ShapeBorder shape; // StadiumBorder() | CircleBorder() | RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) |  BeveledRectangleBorder(borderRadius: BorderRadius.circular(12)
  final Duration animationDuration;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool autofocus;
  final MaterialTapTargetSize materialTapTargetSize;
  final Widget? child;
  final bool enableFeedback;
  final bool isBlock;

  ProcessButton({
    super.key,
    required this.onPressed,
    // this.onLongPress,
    this.onHighlightChanged,
    this.mouseCursor,
    this.textStyle,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.elevation = 2.0,
    this.focusElevation = 4.0,
    this.hoverElevation = 4.0,
    this.highlightElevation = 8.0,
    this.disabledElevation = 0.0,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    this.margin = EdgeInsets.zero,
    this.visualDensity = VisualDensity.standard,
    this.constraints = const BoxConstraints.tightForFinite(),
    ShapeBorder? shape,
    this.animationDuration = kThemeChangeDuration,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.materialTapTargetSize = MaterialTapTargetSize.padded,
    this.child,
    this.enableFeedback = true,
    this.isBlock = true,
  }): shape = shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

  static Icon({
    required Widget child,
    required _FutureVoidCallBack onPressed,
  }) => ProcessButton(
    fillColor: Colors.white,
    textStyle: TextStyle(color: Colors.black),
    isBlock: false,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    shape: CircleBorder(),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    bool isLoading = false;
    final _fillColor = fillColor ?? Theme.of(context).primaryColorDark;
    final _textColor = textStyle?.color ?? Theme.of(context).primaryColorLight;

    return StatefulBuilder(
      builder: (_context, _setState) => Padding(
        padding: margin,
        child: RawMaterialButton(
          onPressed: () {
            if (onPressed == null || isLoading) return;
              
            _setState(() {
              isLoading = true;
            });
        
            onPressed?.call().whenComplete(() {
              _setState(() {
                isLoading = false;
              });
            });
          },
          onHighlightChanged: onHighlightChanged,
          mouseCursor: mouseCursor,
          textStyle: TextStyle(color: _textColor, letterSpacing: 2, fontWeight: textStyle?.fontWeight ?? FontWeight.w500, fontSize: textStyle?.fontSize ?? 16),
          fillColor: _fillColor,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          elevation: elevation,
          focusElevation: focusElevation,
          hoverElevation: hoverElevation,
          highlightElevation: highlightElevation,
          disabledElevation: disabledElevation,
          padding: padding,
          visualDensity: visualDensity,
          constraints: constraints.copyWith(minWidth: isBlock ? MediaQuery.of(_context).size.width : null),
          shape: shape,
          animationDuration: animationDuration,
          clipBehavior: clipBehavior,
          focusNode: focusNode,
          autofocus: autofocus,
          materialTapTargetSize: materialTapTargetSize,
          child: isLoading ? Transform.scale(
            scale: 0.6, // 避免跟按钮边框重叠
            child: CircularProgressIndicator(color: _fillColor.invert/* 取按钮背景色的反色 */)
          ): child,
          enableFeedback: enableFeedback,
        ),
      ),
    );
  }
}

class ProcessIconButton extends StatelessWidget {
  final Widget icon;
  final String? tooltip;
  final ButtonStyle? style;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;
  final _FutureVoidCallBack? onPressed;

  ProcessIconButton({
    super.key,
    required this.icon,
    this.style,
    this.tooltip,
    this.margin = EdgeInsets.zero,
    this.padding,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => StatefulBuilder(
    builder: (context, _setState) {
      bool isLoading = false;

      return Padding(
        padding: margin,
        child: IconButton(
          icon: icon,
          style: style,
          tooltip: tooltip,
          padding: padding,
          onPressed: () {
            if (onPressed == null || isLoading) return;

            _setState(() {
              isLoading = true;
            });

            onPressed?.call().whenComplete(() {
              _setState(() {
                isLoading = false;
              });
            });
          },
        ),
      );
    }
  );
}