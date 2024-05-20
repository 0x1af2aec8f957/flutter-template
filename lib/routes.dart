import 'package:flutter/material.dart' show WidgetsBinding, BuildContext, Widget;
import 'package:go_router/go_router.dart';

import './views/About.dart';
import './views/Count.dart';
import './views/Storage.dart';
import './views/Example.dart';
import './views/Language.dart';
import './views/FormTest.dart';
import './views/SubRouter.dart';
import './views/Home/index.dart';
import './views/Home/View1.dart';
import './views/Home/View2.dart';
import './views/Home/View3.dart';
import './views/FullScreen.dart';
import './views/LoadingJson.dart';
import './views/ApplicationDir.dart';
import './views/CustomCachedNetworkImage.dart';
import './views/WebView.dart';

final routes = [
  /* GoRoute(
    path: WidgetsBinding.instance.platformDispatcher.defaultRouteName, // 平台默认路由
    builder: (context, state) => Home(title: '首页'), // state.pathParameters 为动态路径中的 params 参数；state.uri.queryParameters 为路径中的 query 参数
  ), */
  ShellRoute( // 嵌套路由
    builder: (BuildContext context, GoRouterState state, Widget child) => Home(title: '首页', child: child),
    routes: <RouteBase>[
      GoRoute(
        path: WidgetsBinding.instance.platformDispatcher.defaultRouteName,
        builder: (BuildContext context, GoRouterState state) => View1(),
      ),
      GoRoute(
        path: '${WidgetsBinding.instance.platformDispatcher.defaultRouteName}2',
        builder: (BuildContext context, GoRouterState state) => View2(),
      ),
      GoRoute(
        path: '${WidgetsBinding.instance.platformDispatcher.defaultRouteName}3',
        builder: (BuildContext context, GoRouterState state) => View3(),
      ),
    ],
  ),
  GoRoute(
    path: '/about',
    builder: (context, state) => About(title: '关于'),
  ),
  GoRoute(
    path: '/storage',
    builder: (context, state) => Storage(title: '存储空间'),
  ),
  GoRoute(
    path: '/language',
    builder: (context, state) => Language(title: '语言设置'),
  ),
  GoRoute(
    path: '/webView',
    builder: (context, state) => WebView(src: state.uri.queryParameters['url']!),
  ),
  GoRoute(
    path: '/example',
    builder: (context, state) => Example(title: '示例程序'),
  ),
  GoRoute(
    path: '/loadingJson',
    builder: (context, state) => LoadingJson(title: '加载本地Json文件'),
  ),
  GoRoute(
    path: '/subRouter',
    builder: (context, state) => SubRouter(title: '子路由示例'),
  ),
  GoRoute(
    path: '/formTest',
    builder: (context, state) => FormTest(title: '表单示例程序'),
  ),
  GoRoute(
    path: '/customCachedNetworkImage',
    builder: (context, state) => CustomCachedNetworkImage(title: '图片缓存示例程序'),
  ),
  GoRoute(
    path: '/applicationDir',
    builder: (context, state) => ApplicationDir(title: '应用目录示例'),
  ),
  GoRoute(
    path: '/fullScreen',
    builder: (context, state) => FullScreen(title: '全屏应用示例'),
  ),
  GoRoute(
    path: '/count',
    builder: (context, state) => Count(title: '计数器应用示例'),
  ),
];