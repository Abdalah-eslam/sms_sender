import 'package:flutter/material.dart';
import 'package:sms_sender/core/service/smsService.dart';

void showSendMessageSheet(BuildContext context, String phone) {
  final messageController = TextEditingController();
  bool isSending = false;

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
                  "Send Message",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  enabled: !isSending,
                  decoration: const InputDecoration(
                    hintText: "Write your message",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (messageController.text.trim().isEmpty || isSending)
                        ? null
                        : () async {
                            setState(() => isSending = true);

                            try {
                              await SmsService.sendToSingle(
                                message: messageController.text.trim(),
                                phone: phone,
                              );

                              if (!context.mounted) return;
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Message sent successfully"),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              setState(() => isSending = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Failed to send: ${e.toString()}",
                                  ),
                                ),
                              );
                            }
                          },
                    child: isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Send"),
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
