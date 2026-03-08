import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sms_sender/feature/homeSceen/data/group_model.dart';

// ignore: non_constant_identifier_names
void CustomBottomSheet(BuildContext context) {
  final box = Hive.box<GroupModel>("groups");
  final TextEditingController groupController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Create New Group",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: groupController,
              decoration: const InputDecoration(
                labelText: "Group name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Done"),
                onPressed: () {
                  if (groupController.text.isEmpty) return;

                  final newGroup = GroupModel(
                    name: groupController.text,
                    contacts: [],
                  );

                  box.add(newGroup);

                  groupController.clear();

                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
