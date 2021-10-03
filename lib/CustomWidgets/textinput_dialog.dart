import 'package:flutter/material.dart';

class TextInputDialog {
  Future<void> showTextInputDialog({
    required BuildContext context,
    required String title,
    String? initialText,
    required TextInputType keyboardType,
    required Function(String) onSubmitted,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext ctxt) {
        final _controller = TextEditingController(text: initialText);
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
              TextField(
                autofocus: true,
                controller: _controller,
                keyboardType: keyboardType,
                textAlignVertical: TextAlignVertical.bottom,
                onSubmitted: (value) {
                  onSubmitted(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                primary: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[700],
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () {
                onSubmitted(_controller.text.trim());
              },
              child: Text(
                'Ok',
                style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.secondary == Colors.white
                            ? Colors.black
                            : null),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
          ],
        );
      },
    );
  }
}
