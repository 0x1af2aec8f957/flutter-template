import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils/common.dart';

class Storage extends StatelessWidget {
  final String title;
  Storage({Key? super.key, required this.title});

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
                  builder: (context, snapshot) => snapshot.connectionState != ConnectionState.done ? CircularProgressIndicator() : Text(snapshot.data?.size ?? StringHelper.placeholder),
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
                  builder: (context, snapshot) => snapshot.connectionState != ConnectionState.done ? CircularProgressIndicator() : GestureDetector(
                    child: Text(snapshot.data?.size ?? StringHelper.placeholder),
                    onDoubleTap: () => DefaultCacheManager().emptyCache(), // 清空缓存
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
                  builder: (context, snapshot) => snapshot.connectionState != ConnectionState.done ? CircularProgressIndicator() : Text(snapshot.data?.size ?? StringHelper.placeholder),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}