import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../plugins/dialog.dart';

/// 选择或保存图片组件
/// 选择图片需要权限：https://pub.dev/packages/image_picker
/// 保存图片需要权限：https://pub.dev/packages/image_gallery_saver

enum ActionType { // 图片操作类型
  Photograph, // 拍照
  Album, // 从手机相册选择
  Save, // 保存图片到相册
}

class ActionResult { // 图片操作结果
  final ActionType type; // 操作类型
  final String filePath; // 文件路径
  const ActionResult(this.type, this.filePath);
}

class CustomImageActionButton extends StatelessWidget {
  final Widget actionWidget;
  final GlobalKey? repaintBoundaryKey;
  final void Function(ActionResult imageActionResult)? onCompleted;
  const CustomImageActionButton({super.key, this.actionWidget = const Icon(Icons.more_horiz), this.repaintBoundaryKey, this.onCompleted});

  static Future<String> pickImageByCamera() { // 拍照并选择
    final ImagePicker picker = ImagePicker();
    return picker.pickImage(source: ImageSource.camera).then((XFile? image) {
      if (image == null) return Future.error('图片不存在');
      return image.path;
    });
  }

  static Future<String> pickImageByAlbum() { // 从手机相册选择
    final ImagePicker picker = ImagePicker();
    return picker.pickImage(source: ImageSource.gallery).then((XFile? image) {
      if (image == null) return Future.error('图片不存在');
      return image.path;
    });
  }

  static Future<String> saveImageByRepaintBoundaryKey(GlobalKey _repaintBoundaryKey) { // 截取 key 为 _repaintBoundaryKey 的 Widget图像，并保存到相册
    final BuildContext? buildContext = _repaintBoundaryKey.currentContext;
    if (buildContext == null) return Future.error('上下文获取失败');

    return (buildContext.findRenderObject() as RenderRepaintBoundary)
      .toImage()
      .then((image) => image.toByteData(format: ImageByteFormat.png))
      .then((imageBytes) {
        if (imageBytes == null) return Future.error('图片数据不存在');
        final result = ImageGallerySaver.saveImage(imageBytes.buffer.asUint8List(), isReturnImagePathOfIOS: true);

        if (result is! Future) return Future.error('保存失败');
        return result.then((value) {
          if (value?['isSuccess'] != true || value?['filePath'] is! String) return Future.error(value?['errorMessage'] ?? '保存失败');
          Talk.toast('保存成功');
          return Uri.parse(value['filePath']).path;
        });
      });
  }

  static Future<ActionResult> handleOpenMoreSheet(BuildContext context, { // 显示所有可操作按钮
    GlobalKey? repaintBoundaryKey, // 保存图 需要传入的 repaintBoundaryKey 为 `RepaintBoundary(key: key)` 中的 key
    bool isOnlyShowSave = false, // 是否仅显示保存图片
  }) {
    assert(repaintBoundaryKey == null || isOnlyShowSave == false);
    return Talk.sheetAction<ActionType>(
      children: [
        if (!isOnlyShowSave) TextButton(
          onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.of(context).pop(ActionType.Photograph) : null,
          child: Text('拍照')
        ),
        if (!isOnlyShowSave) TextButton(
          onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.of(context).pop(ActionType.Album) : null,
          child: Text('从手机相册选择')
        ),
        if (repaintBoundaryKey != null) TextButton(
          onPressed: () => ModalRoute.of(context)!.isCurrent ? Navigator.of(context).pop(ActionType.Save) : null,
          child: Text('保存图片')
        ),
      ],
    ).then((type) {
      if (type == ActionType.Photograph) return pickImageByCamera().then((result) => ActionResult(type!, result)); // 拍照

      if (type == ActionType.Album) return pickImageByAlbum().then((result) => ActionResult(type!, result)); // 从手机相册选择

      if (type == ActionType.Save && repaintBoundaryKey != null) return saveImageByRepaintBoundaryKey(repaintBoundaryKey).then((result) => ActionResult(type!, result)); // 保存图片

      return Future.error('无法识别当前操作类型');
    });
  }

  static Future<T?> preview<T>(BuildContext context, { // 预览图片
    Axis scrollDirection = Axis.horizontal,
    ScrollPhysics scrollPhysics = const BouncingScrollPhysics(),
    List<Uri> images = const <Uri>[],
    BoxDecoration? backgroundDecoration,
    PageController? pageController,
    void Function(int)? onPageChanged,
  }) => Navigator.of(context).push<T>(PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => Container(
      child: PhotoViewGallery.builder(
        scrollPhysics: scrollPhysics,
        scrollDirection: scrollDirection,
        itemCount: images.length,
        backgroundDecoration: backgroundDecoration,
        pageController: pageController,
        onPageChanged: onPageChanged,
        builder: (BuildContext context, int index) {
          final Uri imageSrc = images[index];
          final bool isValidAbsoluteUrl = imageSrc.isAbsolute;
          final bool isValidFileUrl = !isValidAbsoluteUrl || imageSrc.isScheme('FILE');
          final bool isValidAssetUrl = isValidFileUrl && imageSrc.path.startsWith('assets/');

          Offset pointPosition = Offset.zero;

          return PhotoViewGalleryPageOptions(
            imageProvider: (isValidAssetUrl ? AssetImage(imageSrc.path) : isValidFileUrl ? FileImage(File(imageSrc.path)) : CachedNetworkImageProvider(imageSrc.toString())) as ImageProvider<Object>,
            initialScale: PhotoViewComputedScale.contained * 0.8,
            heroAttributes: PhotoViewHeroAttributes(tag: imageSrc),
            onTapUp: (context, details, controllerValue) { // 手指移除
             if (ModalRoute.of(context)!.isCurrent && pointPosition == details.globalPosition/* 与按下的位置相同 */) Navigator.of(context).pop(); // 关闭预览
            },
            onTapDown: (context, details, controllerValue) { // 手指按下
              pointPosition = details.globalPosition; // 记录按下的位置
            },
            errorBuilder: (context, error, stackTrace) => GestureDetector(
              onTap: () {
                if (ModalRoute.of(context)!.isCurrent) Navigator.of(context).pop(); // 关闭预览
              },
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          );
        },
        loadingBuilder: (context, event) => Center(
          child: Container(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            ),
          ),
        ),
      )
    ),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: actionWidget,
      onTap: () => handleOpenMoreSheet(context, repaintBoundaryKey: repaintBoundaryKey).then((imageActionResult) => onCompleted?.call(imageActionResult)),
    );
  }
}