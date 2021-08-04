import 'package:flutter/material.dart';

class TextInputDialog {
  Future<void> showTextInputDialog(
    BuildContext context,
    String title,
    String initialText,
    TextInputType keyboardType,
    Function(String) onSubmitted,
  ) async {
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
                    style: TextStyle(color: Theme.of(context).accentColor),
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
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Theme.of(context).accentColor,
              ),
              child: Text(
                "Ok",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                onSubmitted(_controller.text.trim());
              },
            ),
            SizedBox(
              width: 5,
            ),
          ],
        );
      },
    );
  }
}
