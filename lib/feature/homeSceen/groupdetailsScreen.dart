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

    widget.group.save();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContactPickerScreen(
                group: widget.group,
                groupIndex: widget.groupIndex,
              ),
            ),
          );

          if (result == true) {
            // 🔄 لو تم اضافة contacts، عمل تحديث للشاشة
            setState(() {});
          }
        },
      ),

      body: ListView.builder(
        itemCount: widget.group.contacts.length,
        itemBuilder: (context, index) {
          final contact = widget.group.contacts[index];

          return Dismissible(
            key: Key(contact.phone),

            direction: DismissDirection.endToStart,

            // 🔴 خلفية الحذف
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete, color: Colors.white),
            ),

            confirmDismiss: (direction) async {
              final removedContact = contact;

              // ❌ حذف
              widget.group.contacts.removeAt(index);
              widget.group.save();

              setState(() {});

              // 🔥 Snackbar جامد
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(child: Text("${removedContact.name} removed")),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: "UNDO",
                    textColor: Colors.yellow,
                    onPressed: () {
                      if (index <= widget.group.contacts.length) {
                        widget.group.contacts.insert(index, removedContact);
                      } else {
                        widget.group.contacts.add(removedContact);
                      }

                      widget.group.save();
                      setState(() {});
                    },
                  ),
                ),
              );

              return true;
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),

              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : "?",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                title: Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                subtitle: Text(contact.phone),

                trailing: IconButton(
                  icon: const Icon(Icons.sms),
                  onPressed: () {
                    showSendMessageSheet(context, contact.phone);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
