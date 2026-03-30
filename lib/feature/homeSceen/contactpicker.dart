import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
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
  List<Contact> filteredContacts = [];
  Set<Contact> selectedContacts = {};

  Timer? _debounce;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final phoneContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      contacts = phoneContacts.where((c) => c.phones.isNotEmpty).toList();
      filteredContacts = contacts;

      setState(() {});
    }
  }

  // 🔥 Search with debounce
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery = query;
      search(query);
    });
  }

  void search(String query) {
    final input = query.toLowerCase().trim();
    if (input.isEmpty) {
      setState(() => filteredContacts = List.from(contacts));
      return;
    }

    final normalizedInput = input.replaceAll(RegExp(r'[\s\-]'), '');

    final results = contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phone = contact.phones.first.number.replaceAll(
        RegExp(r'[\s\-]'),
        '',
      );

      return name.contains(input) || phone.contains(normalizedInput);
    }).toList();

    setState(() => filteredContacts = results);
  }

  // 🎯 Highlight search text
  Widget highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(text);
    }

    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, startIndex),
            style: const TextStyle(color: Colors.black),
          ),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(endIndex),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  void addSelectedContacts() {
    final existingPhones = widget.group.contacts.map((c) => c.phone).toSet();
    int addedCount = 0;

    for (var contact in selectedContacts) {
      final phone = contact.phones.first.number;

      // Skip if contact already exists
      if (!existingPhones.contains(phone)) {
        widget.group.contacts.add(
          ContactModel(name: contact.displayName, phone: phone),
        );
        addedCount++;
      }
    }

    widget.group.save();

    if (!mounted) return;

    final message = addedCount == selectedContacts.length
        ? "Added ${addedCount} contacts"
        : "Added $addedCount contact(s), ${selectedContacts.length - addedCount} already exist";

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Contacts")),

      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search name or number...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 📱 Contacts
          Expanded(
            child: ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                final isSelected = selectedContacts.contains(contact);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      contact.displayName.isNotEmpty
                          ? contact.displayName[0].toUpperCase()
                          : "?",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  title: highlightText(contact.displayName, searchQuery),

                  subtitle: highlightText(
                    contact.phones.first.number,
                    searchQuery,
                  ),

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

                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedContacts.remove(contact);
                      } else {
                        selectedContacts.add(contact);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: selectedContacts.isEmpty ? null : addSelectedContacts,
        child: const Icon(Icons.check),
      ),
    );
  }
}
