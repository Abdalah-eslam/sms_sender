import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sms_sender/core/utils/sendmassagesheet.dart';
import 'package:sms_sender/feature/homeSceen/contactpicker.dart';
import 'package:sms_sender/feature/homeSceen/data/group_model.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;
  final int groupIndex;

  const GroupDetailsScreen({
    super.key,
    required this.group,
    required this.groupIndex,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late Box<GroupModel> box;

  @override
  void initState() {
    super.initState();
    box = Hive.box<GroupModel>("groups");
  }

  void deleteContact(int index) {
    widget.group.contacts.removeAt(index);

    box.put(widget.groupIndex, widget.group);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContactPickerScreen(
                group: widget.group,
                groupIndex: widget.groupIndex,
              ),
            ),
          );
        },
      ),

      body: ListView.builder(
        itemCount: widget.group.contacts.length,
        itemBuilder: (context, index) {
          final contact = widget.group.contacts[index];

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),

            title: Text(contact.name),

            subtitle: Text(contact.phone),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ارسال رسالة
                IconButton(
                  icon: const Icon(Icons.sms),
                  onPressed: () {
                    showSendMessageSheet(context, contact.phone);
                  },
                ),

                /// حذف
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    deleteContact(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
