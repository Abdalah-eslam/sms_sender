import 'package:hive/hive.dart';
import 'contact_model.dart';

part 'group_model.g.dart';

@HiveType(typeId: 1)
class GroupModel {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<ContactModel> contacts;

  GroupModel({required this.name, required this.contacts});
}
