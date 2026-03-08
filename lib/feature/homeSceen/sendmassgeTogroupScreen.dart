import 'package:flutter/material.dart';
import 'package:sms_sender/core/service/smsService.dart';

import 'package:sms_sender/feature/homeSceen/data/group_model.dart';

class SendGroupMessageScreen extends StatefulWidget {
  final GroupModel group;

  const SendGroupMessageScreen({super.key, required this.group});

  @override
  State<SendGroupMessageScreen> createState() => _SendGroupMessageScreenState();
}

class _SendGroupMessageScreenState extends State<SendGroupMessageScreen> {
  final TextEditingController messageController = TextEditingController();

  Future<void> sendMessage() async {
    final phones = widget.group.contacts.map((c) => c.phone).toList();

    try {
      await SmsService.sendToGroup(
        message: messageController.text,
        phones: phones,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message sent successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to send message")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send to ${widget.group.name}")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Write your message",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sendMessage,
                child: const Text("Send"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
