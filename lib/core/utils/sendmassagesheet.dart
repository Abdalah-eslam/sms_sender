import 'package:flutter/material.dart';
import 'package:sms_sender/core/service/smsService.dart';

void showSendMessageSheet(BuildContext context, String phone) {
  final messageController = TextEditingController();

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
              "Send Message",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Write your message",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Send"),
                onPressed: () async {
                  try {
                    await SmsService.sendToSingle(
                      message: messageController.text,
                      phone: phone,
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Message sent successfully"),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to send message")),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
