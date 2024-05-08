import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import './CustomWebview.dart';
import '../plugins/http.dart';
import '../plugins/dialog.dart';

/// 选择或保存文件组件
/// 选择文件需要权限：https://github.com/miguelpruivo/flutter_file_picker/wiki/Setup

enum ActionType { // 文件操作类型
  Single, // 单选
  Multiple, // 多选
  Directory, // 选择文件夹
  Save, // 保存文件到下载目录
}

class ActionResult { // 文件操作结果
  final ActionType type; // 操作类型
  final List<String> filePaths; // 文件路径集合（ActionType.Multiple 才会直接使用，一般使用 single）
  const ActionResult(this.type, this.filePaths);

  String get single => filePaths.first; // 文件路径
}

class CustomFileActionButton extends StatelessWidget {
  final Widget actionWidget;
  final FileType type;
  final List<String>? allowedExtensions;
  final void Function(ActionResult imageActionResult)? onCompleted;
  const CustomFileActionButton({super.key, this.actionWidget = const Icon(Icons.more_horiz), this.type = FileType.any, this.allowedExtensions, this.onCompleted});

  static Future<String> pickFileBySingle({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) { // 单选文件
    final FilePicker picker = FilePicker.platform;
    return picker.pickFiles(type: type, allowedExtensions: allowedExtensions, allowMultiple: false).then((FilePickerResult? result) {
      if (result?.files.single.path == null) return Future.error('文件不存在');
      return result!.files.single.path!;
    });
  }

  static Future<List<String>> pickFileByMultiple({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) { // 多选文件
    final FilePicker picker = FilePicker.platform;
    return picker.pickFiles(type: type, allowedExtensions: allowedExtensions, allowMultiple: true).then((FilePickerResult? result) {
      if (result?.paths == null) return Future.error('文件不存在');
      return result!.paths.where((_path) => _path != null).cast<String>().toList();
    });
  }

  static Future<String> pickFileByDirectory() { // 选择文件夹
    final FilePicker picker = FilePicker.platform;
    return picker.getDirectoryPath().then((String? _path) {
      if (_path == null) return Future.error('文件夹不存在');
      return _path;
    });
  }

  static Future<String> saveFile({Uint8List? bytes, required String fileName/* 可以是 url */}) { // 保存文件到下载目录（url 会自动完成下载）
    return getDownloadsDirectory().then((Directory? _directory) {
      if (_directory == null) return Future.error('下载文件夹无法读取');
      final String filePath = path.joinAll(['/', ..._directory.uri.pathSegments, path.basename(fileName)]);
      final localFile = File(filePath);

      if (localFile.existsSync()) return Future.error('文件已存在');
      if (bytes != null) { // 保存内容到文件
        localFile..createSync(recursive: true)..writeAsBytesSync(bytes);
        return filePath;
      }

      /// 下载文件
      if (!Uri.parse(fileName).isAbsolute) return Future.error('未提供 bytes，且文件路径不是完整的 url');
      final tmpFile = File(path.join(filePath, '.tmp'));
      return Http.original.download(fileName, tmpFile.path).then((_) { // 下载文件
        localFile..createSync(recursive: true)..writeAsBytesSync(tmpFile.readAsBytesSync());
        return tmpFile.delete(recursive: true).then((_) => filePath);
      });
    });
  }

  static Future<ActionResult> handleOpenMoreSheet(BuildContext context, { // 显示所有可操作按钮
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uri? downloadUri, // 保存文件 需要传入文件 uri
    bool hasDirectory = false, // 是否仅显示选择文件夹
    bool hasMultiple = false, // 是否仅显示批量选择文件
    bool hasSingle = true, // 是否仅显示选择文件
  }) {
    return Talk.sheetAction<ActionType>(
      children: [
        if (downloadUri != null) TextButton(
          onPressed: () => Navigator.of(context).pop(ActionType.Save),
          child: Text('保存文件')
        ),
        if (hasSingle) TextButton(
          onPressed: () => Navigator.of(context).pop(ActionType.Single),
          child: Text('选择文件')
        ),
        if (hasDirectory) TextButton(
          onPressed: () => Navigator.of(context).pop(ActionType.Directory),
          child: Text('选择文件夹')
        ),
        if (hasMultiple) TextButton(
          onPressed: () => Navigator.of(context).pop(ActionType.Multiple),
          child: Text('批量选择文件')
        ),
      ],
    ).then((_type) {
      if (_type == ActionType.Save) return saveFile(fileName: downloadUri.toString()).then((result) => ActionResult(_type!, [result])); // 保存文件

      if (_type == ActionType.Single) return pickFileBySingle(type: type, allowedExtensions: allowedExtensions).then((result) => ActionResult(_type!, [result])); // 选择单个文件

      if (_type == ActionType.Directory) return pickFileByDirectory().then((result) => ActionResult(_type!, [result])); // 选择文件夹

      if (_type == ActionType.Multiple) return pickFileByMultiple(type: type, allowedExtensions: allowedExtensions).then((result) => ActionResult(_type!, result)); // 选择多个文件

      return Future.error('无法识别当前操作类型');
    });
  }

  static Future<T?> preview<T>(BuildContext context, { // 预览文件（支持网络文件）
    required String filePath, // 文件路径
    String? title, // 预览标题
  }) => Navigator.of(context).push<T>(PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title ?? '文件预览'),
        // actions: [],
      ),
      body: CustomWebView(url: filePath),
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
      onTap: () => handleOpenMoreSheet(context, type: type, allowedExtensions: allowedExtensions).then((imageActionResult) => onCompleted?.call(imageActionResult)),
    );
  }
}