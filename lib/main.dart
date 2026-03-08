import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:sms_sender/feature/homeSceen/data/contact_model.dart';
import 'package:sms_sender/feature/homeSceen/data/group_model.dart';

import 'package:sms_sender/feature/permisionScreen/permision.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ContactModelAdapter());
  Hive.registerAdapter(GroupModelAdapter());
  await Hive.openBox<GroupModel>("groups");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PermissionScreen());
  }
}
