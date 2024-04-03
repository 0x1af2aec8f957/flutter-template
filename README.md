# flutter-template

[时间组件国际化·标准](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table)  
[版本组件·标准](https://semver.org/spec/v2.0.0-rc.1.html)

#### 目录结构

```bash
.
├── README.md # 目录描述文件
├── assets # 静态资源存放目录
│   ├── README.md # 目录自述文件
│   ├── fonts # 字体文件存放
│   │   └── iconfont.ttf # icon字体库
│   ├── images # 图片文件存放
│   │   ├── 2.0x
│   │   │   ├── flutter_background.png
│   │   │   └── no_data.png
│   │   ├── 3.0x
│   │   │   ├── flutter_background.png
│   │   │   └── no_data.png
│   │   ├── flutter_background.png
│   │   └── no_data.png
│   ├── json # json文件
│   │   └── country_code.json
│   └── locale # 国际化配合文件(文件解析逻辑翻译自Vue.i18n)
│       ├── common.yaml
│       └── home.yaml
├── flutter_template.iml # flutetr资源描述文件
├── lib # 主要的业务代码存放
│   ├── api # api文件模块存放
│   │   ├── README.md
│   │   └── test.dart
│   ├── components # 公用组件存放
│   │   ├── CustomFlatButton.dart # 自定义按钮组件
│   │   ├── CustomScrollBar.dart # 自定义滚动组件
│   │   ├── CustomWebView.dart # 自定义webview组件，支持jockey协议
│   │   ├── NativeAppBar.dart # 自定义AppBar组件，支持原生嵌套flutter项目自动判断路由历史栈堆长度
│   │   ├── NoData.dart # 无数据组件
│   │   ├── README.md # 自述文件
│   │   ├── SliderLess.dart # 百分比滑块组件
│   │   └── WebView.dart # 普通的webview，不包含任何协议
│   ├── lang # 国际化配置
│   │   └── i18n.dart # 国际化设置相关
│   ├── main.dart # 程序入口文件
│   ├── mixins # mixins混入组件
│   │   └── README.md # 自述文件
│   ├── models # provider数据管理model存放
│   │   ├── README.md # 自述文件
│   │   ├── count.dart # model局部示例
│   │   └── global.dart # model全局示例
│   ├── plugins # 自定义插件
│   │   ├── README.md # 自述文件
│   │   ├── dateFormat.dart # 时间格式化
│   │   ├── eventEmitter.dart # event全局事件
│   │   ├── http.dart # http模块封装，基于Dio二次封装
│   │   ├── jockey.dart # jockey协议实现
│   │   ├── mqtt.dart # mqtt协议实现
│   │   ├── screenUtil.dart # 屏幕自适应方案实现
│   │   ├── signer.dart # 接口或数据签名实现
│   │   └── smallProgram.dart # 小程序实现
│   ├── routes.dart # 路由配置文件
│   ├── setup # 主要的程序配置文件
│   │   ├── README.md # 自述文件
│   │   ├── config.dart # App配置文件
│   │   ├── lang.dart # 多语言配置文件
│   │   ├── providers.dart # provider的model集成汇总
│   │   └── router.dart # 全局的router实现
│   ├── template # 模板代码
│   │   └── README.md # 自述文件
│   ├── theme # 主题文件
│   │   └── index.dart # 主题切换基类
│   ├── utils # 常用方法
│   │   ├── README.md # 自述文件
│   │   ├── common.dart # 公用方法
│   │   ├── constant.dart # 常量
│   │   ├── dialog.dart # 弹窗
│   │   ├── iconFont.dart # 项目中的iconFont
│   │   └── types.d.dart # 常用的类型申明
│   └── views # 页面组件(已存放部分示例页面组件)
│       ├── About.dart
│       ├── ApplicationDir.dart
│       ├── Browser.dart
│       ├── Count.dart
│       ├── CustomCachedNetworkImage.dart
│       ├── Example.dart
│       ├── FormTest.dart
│       ├── FullScreen.dart
│       ├── Home
│       │   ├── Drawer.dart
│       │   ├── Index.dart
│       │   ├── View1.dart
│       │   ├── View2.dart
│       │   └── View3.dart
│       ├── LoadingJson.dart
│       ├── README.md
│       ├── SmallProgramTest.dart
│       ├── SubRouter.dart
│       └── Transform.dart
├── pubspec.yaml # flutter配置文件
└── test # 单元测试
    └── widget_test.dart
```

#### 配置文件文档参考地址

1. [添加依赖包](https://flutter.dev/docs/development/packages-and-plugins/using-packages)
2. [静态资源打包](https://flutter.dev/docs/development/ui/assets-and-images)

#### 模板中使用到的技术栈

1. [国际化](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)，官方文档只有基础资源加载实现，在模板中有完整的全局应用切换实现
2. [iconFont](https://pub.dev/packages/cupertino_icons)，本模板有附加的自定义iconFont完整实现
3. [webView](https://pub.dev/packages/webview_flutter)，本模板中附加jockey通讯协议完整实现
4. [计算精度](https://pub.dev/packages/calculate)，该库由本模板作者书写提供，如由问题可直接在模板仓库中提交`issue`
5. [图片缓存](https://pub.dev/packages/cached_network_image)
6. [应用程序目录](https://pub.dev/packages/path_provider)，模板中大量实现依赖此库，如小程序就非常依赖该库
7. [http请求](https://pub.dev/packages/dio)
8. [数据持久化](https://pub.dev/packages/shared_preferences)，模板中多个场景都在使用，如国际化中记住语言选择会依赖
9. [App包信息](https://pub.dev/packages/package_info)，模板中的应用程序升级功能依赖此包进行版本对照
10. [yaml解析器](https://pub.dev/packages/yaml)，模板中大部分配置文件都需要它提供解析支持，比如国际化支持
11. [内存文件系统](https://pub.dev/packages/file)
12. [encrypt](https://pub.dev/packages/encrypt)，模板中涉及数据加解密都依赖此库提供的数据计算支持，模板中实现的接口动态加解密就依赖此库，模板中基于它实现完整的加密生命周期
13. [(解)压缩](https://pub.dev/packages/archive)，模板中小程序实现依赖此库
14. [安卓动态权限请求](https://pub.dev/packages/permission_handler)
15. [web服务](https://pub.dev/packages/shelf)，模板中涉及启动服务的地方都依赖此库
16. [web服务的静态资源中间件](https://pub.dev/packages/shelf_static)
17. [数据管理](https://pub.dev/packages/provider)，模板中的数据和视图层均为分开状态
18. [本地数据库](https://pub.dev/packages/isar)，本地sql依赖该库

#### 模板中独有的技术栈

1. 时间格式化
2. 全局事件总栈
3. jockey通讯协议
4. 样式数字跟随屏幕自适应大小
5. 数据签名
6. 小程序（H5服务模式）
7. 全局对话框（涵盖弹窗及提示等，无键盘遮挡相关问题）
8. 全局国际化
9. 原生嵌套与独立应用通讯（包括路由跳转、国际化等）
10. 全局主题切换
11. 自定义iconFont
12. 自定义受控`Button`视图组件
13. 自定义无数据状态
14. 自定义滚动组件（包含下来刷新、上拉加载更多）
15. 自定义`AppBar`视图组件，该组件可供原生嵌套与本地独立包的返回等功能产生的行为一致
16. 自定义滑块进度组件

#### 扩展构建桌面应用（开发移动平台的项目请跳过此处）

> 项目模板基础功能支持在桌面环境运行（如：全局的路由、国际化、数据存储、网络请求、数据签名等）

```bash
flutter channel dev # 桌面应用支持仍处于实验环节中
flutter upgrade # 确保你的flutter是最新版本
flutter config --enable-windows-desktop # 添加对Windows桌面的支持
flutter config --enable-macos-desktop # 添加对MacOS桌面的支持
flutter config --enable-linux-desktop # 添加对Linux桌面的支持
```

```bash
flutter devices # 通过该命令查看你的桌面设备是否出现在列表中，如果没有请运行 `flutter doctor` 排查错误
```

#### 使用说明

> 通过[flutter.dev-doc](https://flutter.dev/docs/get-started/install)教程安装flutter，建议选择`stable`通道。

> 模板中存在常用的方法封装，可直接使用。

> 模板结构同[vue-template](https://github.com/0x1af2aec8f957/vue-template)一样，包含国际化等配置文件、路由解析及使用方法均一致。

```bash
git clone git@github.com:0x1af2aec8f957/flutter-template.git flutter_template # 需要重命名至flutter_template命名空间才能符合规范
flutter create . # 创建android、ios原生仓库目录，模板中某些示例需要文件、http网络等权限的支持，请分别在文件`AndroidManifest.xml`及`Info.plist`中配置权限
flutter pub get # 安装依赖
flutter run # 运行项目，需要设备支持(可通过`flutter devices`获取设备列表)
```

#### 无法摆脱的意外

###### [混淆Dart源码](https://docs.flutter.dev/deployment/obfuscate)

通过增加选项`--obfuscate`获得混淆二进制文件，通过增加选项`--split-debug-info`显著减小[代码大小](https://docs.flutter.dev/perf/app-size)。
```bash
flutter build apk --obfuscate --release --split-debug-info=build/app/outputs/symbols #Android打包
flutter build ipa --obfuscate --release --split-debug-info=build/ios/symbols #Ios打包
```

###### `flutter build ios --release`生成的`Archive`会比`flutter build ipa --release`大数倍（通常会大~10倍）

> 这与`LLVM bitcode`的工作方式有关，有关该问题的解释：[GitHub·flutter](https://github.com/flutter/flutter/issues/47101#issuecomment-567522077)  
> [Flutter·3.3.x](https://github.com/flutter/flutter/wiki/Creating-an-iOS-Bitcode-enabled-app)是支持`IOS Bitcode`的最后一个稳定版本，后续的版本将不会有该问题。  
```bash
# 由于某些原因无法升级flutter版本，可以使用xrun手动剔除bitcode
cd @workDir/Runner.app/Frameworks/Flutter.framework
xcrun bitcode_strip Flutter -r -o Flutter
```

###### 在Android上执行`flutter build apk`或`flutter build ipa`，在当前仓库上传时的最新`flutter`版本有致命的`BUG`，但官方尚未修复。

```bash
This application cannot tree shake icons fonts. It has non-constant instances of IconData at the following locations:
...文件地址
```

通过增加选项`--no-tree-shake-icons`获得临时解决方案(这将不会分析iconFontData的数据)。
```bash
flutter build apk --no-tree-shake-icons #Android打包
flutter build ipa --no-tree-shake-icons #Ios打包
```

###### 在Android上执行`flutter build apk`后，存在错误信息: `No implementation found for method getAll on channel plugins.flutter.io/shared_preferences`，该错误在`DEBUG`模式下并不会出现。
> 有关该问题的讨论：[GitHub·flutter](https://github.com/flutter/flutter/issues/65334)  
```bash
flutter build apk --no-shrink # 打包apk
flutter build appbundle --no-shrink # 打包appbundle
```
该问题是`image_picker`插件与`shared_preferences`插件引发的冲突错误，导致`shared_preferences`无法升级，将`image_picker`版本升级到最新的版本即可解决该问题。

###### 使用`jarsigner(jks)`对`Build`后的`build/app/outputs/apk/release/app-release.apk`进行签名时，遇到错误: `jarsigner: unable to sign jar: java.util.zip.ZipException: invalid entry compressed size (expected 463 but got 465 bytes)`。
> 注意`flutter`输出的`release`包均为签名过后的。

```bash
zip -d foo.apk META-INF/\* # 删除已有签名 -> https://stackoverflow.com/questions/5089042/jarsigner-unable-to-sign-jar-java-util-zip-zipexception-invalid-entry-compres/30722523#30722523
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore example.jks example.apk example # 再次签名
```

###### 手动删除`Dart`缓存包后，导致依赖始终无法安装成功。
> [dart缓存机制](https://dart.dev/tutorials/libraries/shared-pkgs#install-the-package-dependencies)会缓存你安装过的每一个包，手动删除后会导致无法被再次重新缓存。需要重新定位下载该缓存包才能解决问题。

```bash
pub cache repair # 执行cache repair命令重新激活缓存包
```

###### ios设备更新系统后真机运行出现`连接超时`的情况。
> 问题出在 设备(更新后)和Xcode 之间，有关该[issue](https://github.com/flutter/flutter/issues/72161#issuecomment-916288252)的详细信息，请查看官方解释说明。

目前唯一尝试成功的方法就是，需要等待`xcode`更新支持设备升级的系统后才可以成功连接。

```bash
Launching lib/main.dart on ios_device in debug mode...
Automatically signing iOS for device deployment using specified development team in Xcode project: XXXXXXXXXX
Running pod install...                                              3.3s
Running Xcode build...                                                  
 └─Compiling, linking and signing...                        25.8s
Xcode build done.                                           56.9s
iOS Observatory not discovered after 30 seconds. This is taking much longer than expected...
Installing and launching...                                        80.7s
Error launching application on ios_device.
```

###### `ios-build`期间，在使用某些支持`ios版本过低`的安装包后，总是提示版本或版本范围与设置的目标值不一致的问题。

解决方案如下:
1. 使用`xcode`打开 `@workDir/ios` 文件夹，选中 `Runner->PROJECT->Runner->Build Settings->Deployment->IOS Deployment Target IOS X.Y.Z`(X.Y.Z为当钱包依赖包中最高的所需构建版本)
2. 打开 `ios/Flutter/AppFrameworkInfo.plist` 设置 `MinimumOSVersion` 为 `X.Y.Z`(X.Y.Z为当钱包依赖包中最高的所需构建版本)
3. 打开 `ios/Podfile` 取消带有注释的 `#platform :ios, '9.0'`,将`9.0`改成`X.Y.Z`(X.Y.Z为当钱包依赖包中最高的所需构建版本)
4. 确保 `ios/Podfile` 文件中 `post_install do |installer|`代码块包含以下代码:
    ```bash
      post_install do |installer|
      installer.pods_project.targets.each do |target|
        flutter_additional_ios_build_settings(target)
          target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0' # 这里是必须的，请将9.0改为`X.Y.Z`(X.Y.Z为当钱包依赖包中最高的所需构建版本)
          end
        end
      end
    ```
5. 在工作目录中运行命令`flutter clean && rm ios/Podfile.lock pubspec.lock && rm -rf ios/Pods ios/Runner.xcworkspace`即可。

然后重新运行程序即可解决该问题。

```bash
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'gRPC-C++-gRPCCertificates-Cpp' from project 'Pods')
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'GoogleAppMeasurement' from project 'Pods')
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'FirebaseAuth' from project 'Pods')
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'GoogleUtilities' from project 'Pods')
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'vibration' from project 'Pods')
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'nanopb' from project 'Pods')
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'BoringSSL-GRPC' from project 'Pods')
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'gRPC-Core' from project 'Pods')
warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is
9.0 to 14.0.99. (in target 'gRPC-C++' from project 'Pods')
```

###### `JCore`不支持`arm64`架构，导致无法在模拟器运行应用。

错误信息：
```bash
...from JCore ...arm64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```
[解决方案](https://developer.apple.com/forums/thread/660864):
使用`xcode`打开`ios`目录，选中Pods, 在右侧的`TARGETS`中找到`JCore`，在右侧的`Build Settings`中将`EXCLUDED_ARCHS`设置为`arm64`.

###### `Image.network`无法正常完成加载HTTPS图像地址。

错误信息：
```bash
Connection closed before full header was received, uri = https://picsum.photos/id/237/200/300
```
[解决方案](https://github.com/flutter/flutter/issues/33240#issuecomment-655656090):
```bash
const String originImageUrl = 'https://picsum.photos/id/237/200/300';
final String imageUrl = Uri.parse(originImageUrl).replace(scheme: 'http').toString(); // 将https替换成http
const imageWidget = Image.network(imageUrl);
```

##### `flutter-webview`中`input type="file"`，iOS设备上拍照闪退：
> 需要在`info.plist`中添加对应的相机权限
```conf
<key>NSCameraUsageDescription</key>
<string>$(PRODUCT_NAME) camera description.</string>
```

##### `flutter build xcarchive --no-tree-shake-icons --release --obfuscate --release --split-debug-info=build/app/outputs/symbols`报错：
```error
Showing Recent Messages
rsync error: some files could not be transferred (code 23) at /AppleInternal/Library/BuildRoots/d9889869-120b-11ee-b796-7a03568b17ac/Library/Caches/com.apple.xbs/Sources/rsync/rsync/main.c(996) [sender=2.6.9]
```
['解决方案'](https://developer.apple.com/forums/thread/725230?answerId=746897022#746897022)
```bash
# @workDir/ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks.sh
# 将 source="$(readlink "${source}")" 替换为 source="$(readlink -f "${source}")"
...
  if [ -L "${source}" ]; then
    echo "Symlinked..."
    source="$(readlink -f "${source}")"
  fi
...
```

##### `flutter run ios -d xxx`警告：
> 该警告会导致App启动非常缓慢。
```error
(lldb) warning: libobjc.A.dylib is being read from process memory. This indicates that LLDB could not find the on-disk shared cache for this device. This will likely reduce debugging performance.
```
[解决方案](https://github.com/flutter/flutter/issues/126588#issuecomment-1545825673)

##### `flutter run ios --release`由于依赖项未更新导致的`Command PhaseScriptExecution failed with a nonzero exit code`：
1. Delete your Podfile.lock (I like to use the command '-rm -rf Podfile.lock' on the terminal for this)
2. Delete your Pods folder (I like to use the command '-rm -rf Pods' in the terminal for this)
3. Delete your .xcworkspace
4. Pod install
5. Clear your project into XCode> Product> Clean Build Folder

##### 将flutter从2.X升级到3.X报错：
```error
[!] Invalid `Podfile` file: undefined method `exists?' for File:Class.

 #  from /Volumes/Work/kapok/kapok-app/ios/Podfile:34
 #  -------------------------------------------
 #    pod 'Firebase/Analytics'
 >    flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
 #  end
 #  -------------------------------------------
```
解决方案：
```bash
# 修改flutter-sdk中的文件，适配Ruby最新语法
# flutter/packages/flutter_tools/bin/pod_helper.rb
def flutter_parse_plugins_file(file, platform)
  file_path = File.expand_path(file)
  return [] unless File.exist? file_path # 原来的代码：return [] unless File.exists? file_path

  dependencies_file = File.read(file)
  dependencies_hash = JSON.parse(dependencies_file)

  # dependencies_hash.dig('plugins', 'ios') not available until Ruby 2.3
  return [] unless dependencies_hash.has_key?('plugins')
  return [] unless dependencies_hash['plugins'].has_key?('ios')
  dependencies_hash['plugins'][platform] || []
end
```

##### 最新版的`connectivity_plus-^5.0.2`在执行`pod install`时，抛出异常
> [connectivity_plus-5.0.0](https://pub.dev/packages/connectivity_plus/changelog#500)需要`iOS`最小的sdk为`12`.

```Podfile
# @workDir/ios/Podfile
# Uncomment this line to define a global platform for your project
platform :ios, '12.0' # 将这里的 11 改为 12，再执行 pod install 即可
```

##### 帮助
[Buy me a coffee](https://www.buymeacoffee.com/0x1af2aec8f957)
