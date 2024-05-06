import 'dart:io' show File;
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? radius;
  final Widget? errorWidget;
  final double opacity;
  final Map<String, String>? headers;
  final BoxFit fit;
  final bool hasPlaceholder;

  Widget Function(BuildContext context, String url, Object error) get errorBuilder => (context, url, error) => Container( // 图片错误
    width: width,
    child: FittedBox(child: errorWidget ?? Icon(Icons.broken_image_outlined)),
  );

  /* Widget Function(BuildContext context, String url) get placeholderBuilder => (context, url) => Container( // 加载中
    width: width,
    child: FittedBox(child: errorWidget ?? Icon(Icons.image_outlined)),
  ); */

  const CustomImage({
    super.key,
    this.url,
    this.width,
    this.radius,
    this.headers,
    this.opacity = 1,
    this.errorWidget,
    this.fit = BoxFit.contain,
    this.hasPlaceholder = true,
  });

  get random => Random().nextDouble() * 100;
  double get _radius => radius ?? 4;
  get isValidUrl => url != null;
  get isValidAbsoluteUrl => isValidUrl && Uri.parse(url!).isAbsolute;
  get isValidFileUrl => isValidUrl && !Uri.parse(url!).isAbsolute;
  get isValidAssetUrl => isValidFileUrl && url!.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (isValidAssetUrl) return ClipRRect( // Asset 资源
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        width: width,
        child: Image.asset(
          url!,
          fit: fit,
          errorBuilder: (BuildContext _context, Object __, StackTrace? ___) => errorBuilder(_context, url!, 'Image.asset error'),
        ),
      ),
    );

    if (isValidFileUrl) return ClipRRect( // File 文件
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        width: width,
        child: Image.file(
          File(url!),
          fit: fit,
          errorBuilder: (BuildContext _context, Object __, StackTrace? ___) => errorBuilder(_context, url!, 'Image.file error'),
        ),
      ),
    );

    return ClipRRect( // 圆角矩形
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        width: width,
        child: LayoutBuilder( /// NOTE: 避免使用 IntrinsicWidth 与 IntrinsicHeight，它们的开支非常昂贵，这里得到布局限制信息即可，无需强制限制内部子组件的布局大小。
          builder: (BuildContext _context, BoxConstraints constraints) { // 支持解析传入宽度为 double.infinity 的图片渲染
            final double _width = constraints.biggest.width;
            final String placeholder = "https://picsum.photos/${(_width * 3).toInt()}?random=${random}"; // 随机图片
            return CachedNetworkImage(
              fit: fit,
              width: width,
              httpHeaders: headers,
              errorWidget: errorBuilder,
              // placeholder: placeholderBuilder,
              imageUrl: hasPlaceholder && !isValidAbsoluteUrl ? placeholder : (url ?? ''),
              progressIndicatorBuilder: (context, url, downloadProgress) => Padding( // 加载中
                padding: const EdgeInsets.all(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CircularProgressIndicator(value: downloadProgress.progress)),
              ),
            );
          }
        ),
      ),
    );
  }
}