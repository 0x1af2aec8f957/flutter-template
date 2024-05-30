import 'package:flutter/services.dart' show MethodCall;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes.dart';
import '../lang/i18n.dart';
import '../setup/config.dart';
import '../utils/common.dart' show methodChannel;

final router = GoRouter(
  routes: routes,
  observers: [RouterObserver()],
  navigatorKey: AppConfig.navigatorKey, // 应用外部使用路由跳转
  debugLogDiagnostics: !AppConfig.isProduction,
  initialLocation: WidgetsBinding.instance.platformDispatcher.defaultRouteName, // 平台默认路由
  /* errorBuilder: (BuildContext _context, GoRouterState _state) => Center( // 处理路由访问错误（比如 404 等）
    child: Text('An unknown fatal error occurred')
  ), */
  /* onException: (BuildContext _context, GoRouterState _state, GoRouter _router) { // 处理所有错误，提供该方法会覆盖 errorBuilder
    Talk.log('路由异常：${_state.error}', name: 'GoRouter.onException');
  }, */
  /* redirect: (BuildContext context, GoRouterState state) { // 鉴权或其它需要重定向的逻辑
    if (AuthState.of(context).isSignedIn) {
      return '/signin';
    } else {
      return null;
    }
  }, */
  /* redirect: (BuildContext context, GoRouterState state) { // token 不存在则跳转到登录页
    if (state.uri.path.startsWith('/register')) return null; // 注册页不需要 token
    return SharedPreferences.getInstance().then((prefs) => prefs.getString('token') == null ? '/login' : null);
  }, */
);

class RouterObserver extends NavigatorObserver {
  // 对路由的鉴权拦截，可在此处理[官方路由表不可使用onGenerateRoute钩子]

  RouterObserver() {
    methodChannel.setMethodCallHandler((MethodCall call) { // 为原生提供界面控制
      final String method = call.method;
      final Map arguments = call.arguments;
      final String name = arguments['name']; // 页面
      final dynamic _arguments = arguments['arguments']; // 参数

      switch (method) {
        // 路由方法
        case "routerPush":
          return router.push(name, extra: _arguments);
        case 'routerReplace':
          return router.replace(name, extra: _arguments);
        case 'routerPop':
          try{
            router.pop(_arguments);
            return Future.value(true);
          }catch(e){
            return Future.value(false);
          }
        case 'pushAndRemoveUntil':
          try{
            router.go(name, extra: _arguments);
            return Future.value(true);
          }catch(e){
            return Future.value(false);
          }
        //  设置参数方法
        case 'setLocale':
          try {
            final _locale = (_arguments as Map);
            I18n.setLanguage(Locale(_locale['languageCode'], _locale['countryCode']));
            return Future.value(true);
          }catch(e) { // 1af2aec8f957
            return Future.value(false);
          }
        //  获取参数方法
        default:
          return Future.value(I18n.$t('common', 'customErrorMessages[1]'));
      }
    });

    if (AppConfig.isProduction) { // 在生产环境，将覆盖 ErrorWidget 向屏幕输出错误的信息
      ErrorWidget.builder = (FlutterErrorDetails flutterErrorDetails) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.back_hand, size: 50),
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(AppConfig.navigatorContext).padding.top),
              child: Text('An unknown fatal error occurred', style: TextStyle(fontSize: 20)),
            ),
          ],
        )
      );
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) { // 对应的push方法
    // 当调用Navigator.push时回调
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) { // 对应的pop方法
    super.didPop(route, previousRoute);
  }
}