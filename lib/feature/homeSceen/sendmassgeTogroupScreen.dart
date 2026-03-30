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
  bool _isSending = false;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a message")));
      return;
    }

    final phones = widget.group.contacts.map((c) => c.phone).toList();

    if (phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No contacts in this group")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await SmsService.sendToGroup(
        message: messageController.text.trim(),
        phones: phones,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message sent successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
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
            Expanded(
              child: TextField(
                controller: messageController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: "Write your message",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: messageController,
                builder: (context, value, __) {
                  final isEnabled = value.text.trim().isNotEmpty && !_isSending;

                  return ElevatedButton(
                    onPressed: isEnabled ? sendMessage : null,
                    child: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Send"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
