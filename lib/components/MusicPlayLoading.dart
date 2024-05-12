import 'package:flutter/material.dart';

class _Bar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final BorderRadiusGeometry borderRadius;

  const _Bar({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    margin: EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      shape: BoxShape.rectangle,
      color: color,
      borderRadius: borderRadius,
    ),
  );
}

class MusicPlayLoading extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final Curve curve;
  final Duration duration;
  final BorderRadiusGeometry borderRadius;

  const MusicPlayLoading({
    super.key,
    this.width = 3.0,
    this.height = 40.0,
    this.color = Colors.blue,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 3000),
    this.borderRadius = const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
  });

  @override
  _MusicPlayLoading createState() => _MusicPlayLoading();
}

class _MusicPlayLoading extends State<MusicPlayLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();

  final List<List<double>> values = const [
    [0.0, 0.7, 0.4, 0.05, 0.95, 0.3, 0.9, 0.4, 0.15, 0.18, 0.75, 0.01],
    [0.05, 0.95, 0.3, 0.9, 0.4, 0.15, 0.18, 0.75, 0.01, 0.0, 0.7, 0.4],
    [0.9, 0.4, 0.15, 0.18, 0.75, 0.01, 0.0, 0.7, 0.4, 0.05, 0.95, 0.3],
    [0.18, 0.75, 0.01, 0.0, 0.7, 0.4, 0.05, 0.95, 0.3, 0.9, 0.4, 0.15],
  ];

  late final animations = values.map((_values) => TweenSequence([
    ...List.generate(11, (index) => TweenSequenceItem(
      tween: Tween(begin: _values[index], end: _values[index + 1]),
      weight: 100.0 / values.length,
    )).toList()
  ]).animate(CurvedAnimation(parent: _controller, curve: widget.curve)));

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: animations.map((_animation) => _Bar(
          color: widget.color,
          width: widget.width,
          borderRadius: widget.borderRadius,
          height: _animation.value * widget.height,
        )).toList(),
      ),
    );
  }
}