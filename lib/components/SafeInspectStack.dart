import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/common.dart';
import '../setup/config.dart';

/// 应用安全检查
class SafeInspectStack extends StatefulWidget {
  final Widget child;

  const SafeInspectStack({
    super.key,
    required this.child // 进行安全审查时，展示的小部件
  });

  @override
  State<SafeInspectStack> createState() => _SafeInspectStack();
}

class _SafeInspectStack extends State<SafeInspectStack> with WidgetsBindingObserver {
  AppLifecycleState appLifecycleState = AppLifecycleState.resumed; // 应用程序激活状态

  bool get isAppLifecycleKeepResumed => appLifecycleState == AppLifecycleState.resumed; // 应用是否处于前台运行

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 监听应用激活状态（前后台）
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState _state) {
    setState(() {
      appLifecycleState = _state;
    });
    /* switch (_state) {
      case AppLifecycleState.inactive: // 应用处于切换状态、分屏状态、画中画、电话呼叫时
        break;
      case AppLifecycleState.resumed:// 应用程序处于激活状态，前台
        break;
      case AppLifecycleState.paused: // 应用程序不可见，后台
        break;
      case AppLifecycleState.detached: // 应用程序发生意外退出时会被调用，或者初始化应用程序时可能被调用
        break;
      default:
        return;
    } */
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          widget.child,
          if (!isAppLifecycleKeepResumed) Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                color: Colors.transparent,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur( // 高斯模糊效果
                      sigmaX: 8,
                      sigmaY: 8,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      widthFactor: 1,
                      heightFactor: 1,
                      child: FutureBuilder<PackageInfo>(
                        future: AppConfig.packageInfo,
                        builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) => Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [BoxShadow(
                                  color: Colors.grey[300]!, // 颜色
                                  offset: Offset(0, -1), // 偏移量
                                  blurRadius: 10, // 阴影模糊
                                  spreadRadius: 3 // 阴影扩散
                              )]
                          ),
                          child: Text(
                            '${snapshot.data?.appName  ?? StringHelper.placeholder} 正在运行',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 20, decoration: TextDecoration.none),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ),
        ]
    );
  }
}
