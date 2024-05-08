import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils/common.dart';
import '../plugins/dialog.dart';

class Storage extends StatelessWidget {
  final String title;
  Storage({Key? super.key, required this.title});

  Future<bool> handleClearApplicationDocumentsDirectory() => Talk.alert('文档数据不可被清除', title: '警告', isCancel: false); // 清空文档

  Future<dynamic> handleClearTemporaryDirectory() => Talk.sheetAlert('确定清除缓存数据吗？').then((bool isOk) { // 清空缓存
    if (!isOk) return Future.error('用户取消清除缓存数据');
    return Future.wait([
      FilePicker.platform.clearTemporaryFiles(), // 清空临时文件
      DefaultCacheManager().emptyCache(), // 清空缓存
      WebViewController().clearCache(),
      WebViewController().clearLocalStorage(),
    ]);
  });

  Future<void> handleClearDownloadsDirectory() async { // 清空下载
    final bool isOk = await Talk.sheetAlert('确定清除下载数据吗？');
    if (!isOk) return;

    final dir = await getDownloadsDirectory();
    dir?.delete(recursive: true);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              color: Colors.grey.withOpacity(0.1),
              margin: EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('文档'),
                subtitle: Text('应用程序使用的主要目录，用于存储用户生成的数据', style: TextStyle(fontSize: 12)),
                trailing: FutureBuilder<int>(
                  future: getApplicationDocumentsDirectory().then((result) => result.fileSize),
                  builder: (context, snapshot) => snapshot.connectionState != ConnectionState.done ? SizedBox.square(dimension: 5, child: CircularProgressIndicator(strokeWidth: 3)) : GestureDetector(
                    child: Text(snapshot.data?.size ?? StringHelper.placeholder),
                    onDoubleTap: handleClearApplicationDocumentsDirectory,
                  ),
                )
              ),
            ),
            Container(
              color: Colors.grey.withOpacity(0.1),
              margin: EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('缓存'),
                subtitle: Text('应用程序可以使用的临时目录，用于缓存数据', style: TextStyle(fontSize: 12)),
                trailing: FutureBuilder<int>(
                  future: getTemporaryDirectory().then((result) => result.fileSize),
                  builder: (context, snapshot) => snapshot.connectionState != ConnectionState.done ? SizedBox.square(dimension: 5, child: CircularProgressIndicator(strokeWidth: 3)) : GestureDetector(
                    child: Text(snapshot.data?.size ?? StringHelper.placeholder),
                    onDoubleTap: handleClearTemporaryDirectory, // 清空缓存
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.grey.withOpacity(0.1),
              margin: EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('下载'),
                subtitle: Text('应用程序可以访问的下载目录，用于存储下载产生的数据', style: TextStyle(fontSize: 12)),
                trailing: FutureBuilder<int?>(
                  future: getDownloadsDirectory().then((result) => result?.fileSize),
                  builder: (context, snapshot) => snapshot.connectionState != ConnectionState.done ? SizedBox.square(dimension: 5, child: CircularProgressIndicator(strokeWidth: 3)) : GestureDetector(
                    child: Text(snapshot.data?.size ?? StringHelper.placeholder),
                    onDoubleTap: handleClearDownloadsDirectory,
                  ),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}