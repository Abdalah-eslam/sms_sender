import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:sms_sender/core/utils/custombottomsheet.dart';
import 'package:sms_sender/feature/homeSceen/data/group_model.dart';
import 'package:sms_sender/feature/homeSceen/groupdetailsScreen.dart';
import 'package:sms_sender/feature/homeSceen/sendmassgeTogroupScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<GroupModel>("groups");

    return Scaffold(
      appBar: AppBar(title: const Text("Groups")),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CustomBottomSheet(context);
        },
        child: const Icon(Icons.add),
      ),

      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, box, _) {
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Your Groups",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = box.getAt(index)!;

                  return Dismissible(
                    key: Key(box.keyAt(index).toString()),

                    /// swipe directions
                    direction: DismissDirection.horizontal,

                    /// background عند السحب لليمين
                    background: Container(
                      color: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: const Icon(
                        Icons.sms,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    /// background عند السحب للشمال
                    secondaryBackground: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    confirmDismiss: (direction) async {
                      /// لو السحب للشمال (حذف)
                      if (direction == DismissDirection.endToStart) {
                        final confirm = await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Delete Group"),
                              content: const Text(
                                "Are you sure you want to delete this group?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: const Text("Cancel"),
                                ),

                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          box.deleteAt(index);
                          return true;
                        }

                        return false;
                      }

                      /// السحب لليمين (ارسال رسالة)
                      if (direction == DismissDirection.startToEnd) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SendGroupMessageScreen(group: group),
                          ),
                        );
                        return false;
                      }

                      return false;
                    },

                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailsScreen(
                              group: group,
                              groupIndex: index,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(group.name),
                        subtitle: Text("${group.contacts.length} contacts"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  );
                }, childCount: box.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
