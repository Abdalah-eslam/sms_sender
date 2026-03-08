import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:hive/hive.dart';
import 'package:sms_sender/feature/homeSceen/data/group_model.dart';
import 'package:sms_sender/feature/homeSceen/data/contact_model.dart';

class ContactPickerScreen extends StatefulWidget {
  final GroupModel group;
  final int groupIndex;

  const ContactPickerScreen({
    super.key,
    required this.group,
    required this.groupIndex,
  });

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  List<Contact> contacts = [];
  Set<Contact> selectedContacts = {};

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final phoneContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      contacts = phoneContacts.where((c) => c.phones.isNotEmpty).toList();

      setState(() {});
    }
  }

  void addSelectedContacts() {
    final box = Hive.box<GroupModel>("groups");

    for (var contact in selectedContacts) {
      widget.group.contacts.add(
        ContactModel(
          name: contact.displayName,
          phone: contact.phones.first.number,
        ),
      );
    }

    box.put(widget.groupIndex, widget.group);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Contacts")),

      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];

          final isSelected = selectedContacts.contains(contact);

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                contact.displayName.isNotEmpty ? contact.displayName[0] : "?",
              ),
            ),

            title: Text(contact.displayName),

            subtitle: Text(contact.phones.first.number),

            trailing: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (isSelected) {
                    selectedContacts.remove(contact);
                  } else {
                    selectedContacts.add(contact);
                  }
                });
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: selectedContacts.isEmpty ? null : addSelectedContacts,
        child: const Icon(Icons.check),
      ),
    );
  }
}
