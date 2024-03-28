import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../setup/config.dart';
import '../plugins/applicationUpdate.dart';

class About extends StatelessWidget {
  final String title;

  const About({Key? key, required this.title}) : super(key: key);

  Future<void> handleShare(BuildContext context) { // 分享
    final box = context.findRenderObject() as RenderBox?;
    return Share.share('check out my website https://example.com', sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  Future<void> handleVersionUpdate(BuildContext context) async { // 版本更新
    final packageInfo = await AppConfig.packageInfo;
    return await AppUpgrade.init().then((value) => AppUpgrade.checkUpdate('${packageInfo.version}+${packageInfo.buildNumber}', link: 'https://example.com', hasUpdateToast: true));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(title),
        // centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ListBody(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Image.asset('assets/images/logo.jpg', width: 50, errorBuilder: (BuildContext _context, Object _, StackTrace? _stackTrace) => Icon(Icons.apps, size: 50)),
                      ),
                      FutureBuilder(future: AppConfig.packageInfo, builder: (BuildContext _context, AsyncSnapshot<PackageInfo> _packageInfo) => Text('${_packageInfo.data?.version} (${_packageInfo.data?.buildNumber})'))
                    ],
                  ),
                  ListTile(
                    leading: Icon(Icons.share_sharp),
                    title: Text('分享'),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () => handleShare(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.downloading_rounded),
                    title: Text('版本更新'),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () => handleVersionUpdate(context),
                  ),
                ],
              ),
              FutureBuilder(future: AppConfig.packageInfo, builder: (BuildContext _context, AsyncSnapshot<PackageInfo> _packageInfo) => Text('Copyright © ${DateTime.now().year} ${_packageInfo.data?.appName}. All Rights Reserved.')),
            ],
          ),
        ),
      ),
    );
  }
}
