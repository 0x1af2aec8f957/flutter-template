import 'package:isar/isar.dart';

part 'test.g.dart';
/// test schema original

@collection
class Test {
  Id? id; // id
  DateTime? createdTime; // 创建时间	
  DateTime? updatedTime; // 更新时间
}