import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sms_sender/feature/homeSceen/data/group_model.dart';

void CustomBottomSheet(BuildContext context) {
  final box = Hive.box<GroupModel>("groups");
  final TextEditingController groupController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                    errorText: null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: groupController.text.isEmpty
                        ? null
                        : () {
                            final groupName = groupController.text.trim();

                            // Check if group name already exists
                            final exists = box.values.any(
                              (group) =>
                                  group.name.toLowerCase() ==
                                  groupName.toLowerCase(),
                            );

                            if (exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Group name already exists"),
                                ),
                              );
                              return;
                            }

                            final newGroup = GroupModel(
                              name: groupName,
                              contacts: [],
                            );

                            box.add(newGroup);
                            groupController.clear();
                            Navigator.pop(context);
                          },
                    child: const Text("Done"),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
