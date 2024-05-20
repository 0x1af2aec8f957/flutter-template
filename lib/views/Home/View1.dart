import 'package:flutter/material.dart';

import '../../components/FullScreenWebView.dart';

class View1 extends StatelessWidget{
  final TabController? tabController;
  final List<dynamic> tabs;

  const View1({this.tabController, this.tabs = const []});

  @override
  Widget build(BuildContext context) {

    return TabBarView(
      controller: tabController,
      children: tabs.map((e) { //创建3个Tab页
        return Container(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => FullScreenWebView.open(context, url: Uri.https('www.baidu.com')),
            child: Text(e, textScaler: TextScaler.linear(5))
          ),
        );
      }).toList(),
    );
  }
}