import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../api/test.dart' as Api;
/// 数据库实例

import '../../setup/config.dart';

import './schema/test.dart';

final List<CollectionSchema<dynamic>> _schemas = [ // 数据库 Schema
  TestSchema,
];

class DbInstance {
  Isar? instance;

  final String name = 'default';

  bool get hasBeenInitialized => instance != null; // 是否已初始化
  bool get isOpen => instance?.isOpen ?? false; // 是否已打开

  DbInstance._internal() {
    getApplicationDocumentsDirectory().then((Directory _dir) {
      instance ??= Isar.openSync(
        _schemas,
        directory: _dir.path,
        name: name,
        inspector: !AppConfig.isProduction
      );
    });
  }

  factory DbInstance() => _instance;
  static late final DbInstance _instance = DbInstance._internal();

  /// CRUD

  /// test schema
  Future<Test?> get test => instance!.tests.where().findFirst(); // 获取 test
  Future<Id> updateTest() => Api.Test.test.then((result) => instance!.writeTxn(() => instance!.tests.put( // 新增或更新 test
    Test()
      ..id = int.tryParse(result.id)
      ..createdTime = result.createdTime
      ..updatedTime = result.updatedTime
  )));

  Future<bool> close() {
    if (instance == null) Future.error('Isar 尚未打开');
    return instance!.close();
  }
}