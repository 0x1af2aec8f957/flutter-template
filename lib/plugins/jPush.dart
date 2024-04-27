/// 激光推送二次封装
/// 注意：在安卓上JPush_flutternebula的compileSdkVersion和minSdkVersion约束限制导致Build失败，解决方案：https://github.com/jpush/janalytics-flutter-plugin/issues/5#issuecomment-664139885
import 'package:jpush_flutter/jpush_flutter.dart' as auroraPush; // 激光推送，doc: https://docs.jiguang.cn/jpush/guideline/intro/

import '../setup/config.dart';

typedef void AddEventHandler ({
  auroraPush.EventHandler onReceiveNotification,
  auroraPush.EventHandler onOpenNotification,
  auroraPush.EventHandler onReceiveMessage,
  auroraPush.EventHandler onReceiveNotificationAuthorization
});
typedef void ApplyPushAuthority ([auroraPush.NotificationSettingsIOS iosSettings]);
typedef Future<Map<dynamic, dynamic>> SetTags (List<String> tags);
typedef Future<Map<dynamic, dynamic>> SetAlias (String alias);
typedef Future<void> SetBadge (int badge);
typedef void ClearNotification ({int notificationId});
typedef Future<String> SendLocalNotification (auroraPush.LocalNotification notification);

final _JPush jPush = _JPush();

class _JPush{
  final auroraPush.JPush instance = auroraPush.JPush(); // TODO 需要开发者证书才能在iOS设备上获得推送选项许可，获得许可后需要将 Push Notification设置为ON（在xcode上操作）

  _JPush(){ // 调用时将自动初始化
    instance.setup( // 初始化极光推送，必须初始化后插件所有功能才能正常工作
      debug: !AppConfig.isProduction, // debug模式
      production: AppConfig.isProduction, // 是否是生产环境
      appKey: 'AppConfig.pushKey', // 极光平台上创建的应用，自动生成的AppKey
      channel: 'developer-default', // 通道
    );
    if (AppConfig.system == 'ios') applyPushAuthority(new auroraPush.NotificationSettingsIOS(sound: true, alert: true, badge: true)); // ios请求通知授权
  }

  /// 获取极光推送注册ID
  Future<String> get  registrationID => instance.getRegistrationID(); // 获取极光推送注册ID

  AddEventHandler get addEventHandler => instance.addEventHandler;

  ///
  /// iOS Only
  /// 申请推送权限，注意这个方法只会向用户弹出一次推送权限请求（如果用户不同意，之后只能用户到设置页面里面勾选相应权限），需要开发者选择合适的时机调用。
  ///
  ApplyPushAuthority get applyPushAuthority => instance.applyPushAuthority;

  ///
  /// 设置 Tag （会覆盖之前设置的 tags）
  ///
  /// @param {Array} params = [String]
  /// @param {Function} success = ({"tags":[String]}) => {  }
  /// @param {Function} fail = ({"errorCode":int}) => {  }
  ///
  SetTags get setTags => instance.setTags;

  ///
  /// 清空所有 tags。
  ///
  /// @param {Function} success = ({"tags":[String]}) => {  }
  /// @param {Function} fail = ({"errorCode":int}) => {  }
  ///
  Future<Map<dynamic, dynamic>> get cleanTags => instance.cleanTags();

  ///
  /// 获取所有当前绑定的 tags
  ///
  /// @param {Function} success = ({"tags":[String]}) => {  }
  /// @param {Function} fail = ({"errorCode":int}) => {  }
  ///
  Future<Map<dynamic, dynamic>> get getAllTags => instance.getAllTags();

  ///
  /// 在原有 tags 的基础上添加 tags
  ///
  /// @param {Array} tags = [String]
  /// @param {Function} success = ({"tags":[String]}) => {  }
  /// @param {Function} fail = ({"errorCode":int}) => {  }
  ///
  SetTags get addTags => instance.addTags;

  ///
  /// 删除指定的 tags
  ///
  /// @param {Array} tags = [String]
  /// @param {Function} success = ({"tags":[String]}) => {  }
  /// @param {Function} fail = ({"errorCode":int}) => {  }
  ///
  SetTags get deleteTags => instance.deleteTags;

  ///
  /// 重置 alias.
  ///
  /// @param {String} alias
  ///
  /// @param {Function} success = ({"alias":String}) => {  }
  /// @param {Function} fail = ({"errorCode":int}) => {  }
  ///
  SetAlias get setAlias => instance.setAlias;


  ///
  /// 删除原有 alias
  ///
  /// @param {Function} success = ({"alias":String}) => {  }
  /// @param {Function} fail = ({"errorCode":int}) => {  }
  ///
  Future<Map<dynamic, dynamic>> get deleteAlias => instance.deleteAlias();

  ///
  /// 设置应用 Badge（小红点）
  ///
  /// @param {Int} badge
  ///
  /// 注意：如果是 Android 手机，目前仅支持华为手机
  ///
  SetBadge get setBadge => instance.setBadge;

  ///
  /// 停止接收推送，调用该方法后应用将不再受到推送，如果想要重新收到推送可以调用 resumePush。
  ///
  Future<void> get stopPush => instance.stopPush();

  ///
  /// 恢复推送功能。
  ///
  Future<void> get resumePush => instance.resumePush();

  ///
  /// 清空通知栏上的所有通知。
  ///
  Future<void> get clearAllNotifications => instance.clearAllNotifications();

  ///
  /// 清空通知栏上某个通知
  /// @param notificationId 通知 id，即：LocalNotification id
  ///
  ClearNotification get clearNotification => instance.clearNotification;

  ///
  /// iOS Only
  /// 点击推送启动应用的时候原生会将该 notification 缓存起来，该方法用于获取缓存 notification
  /// 注意：notification 可能是 remoteNotification 和 localNotification，两种推送字段不一样。
  /// 如果不是通过点击推送启动应用，比如点击应用 icon 直接启动应用，notification 会返回 @{}。
  /// @param {Function} callback = (Object) => {}
  ///
  Future<Map<dynamic, dynamic>> get getLaunchAppNotification => instance.getLaunchAppNotification();

  ///
  /// 发送本地通知到调度器，指定时间出发该通知。
  /// @param {Notification} notification
  ///
  Future<String> sendLocalNotification(auroraPush.LocalNotification localNotification) {
    final fireTime = localNotification.fireTime?.add(Duration(milliseconds: AppConfig.system == 'ios' ? 100 : 0)); // iOS需要延迟100ms，link: https://github.com/jpush/jpush-react-native/issues/422#issuecomment-407681784
    return instance.sendLocalNotification(auroraPush.LocalNotification(
        buildId: localNotification.buildId,
        id: localNotification.id,
        title: localNotification.title,
        content: localNotification.content,
        extra: localNotification.extra,
        fireTime: fireTime,
        badge: localNotification.badge,
        soundName: localNotification.soundName,
        subtitle: localNotification.subtitle
    ));
  }

  /// 调用此 API 检测通知授权状态是否打开
  Future<bool> get isNotificationEnabled => instance.isNotificationEnabled();

  /// 调用此 API 跳转至系统设置中应用设置界面
  void get openSettingsForNotification => instance.openSettingsForNotification();
}
