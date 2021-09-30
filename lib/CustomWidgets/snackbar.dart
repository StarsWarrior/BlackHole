import 'package:flutter/material.dart';

class ShowSnackBar {
  void showSnackBar(BuildContext context, String title,
      {SnackBarAction? action, Duration? duration, bool noAction = false}) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: duration ?? const Duration(seconds: 1),
          elevation: 6,
          backgroundColor: Colors.grey[900],
          behavior: SnackBarBehavior.floating,
          content: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          action: noAction
              ? null
              : action ??
                  SnackBarAction(
                    textColor: Theme.of(context).colorScheme.secondary,
                    label: 'Ok',
                    onPressed: () {},
                  ),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Failed to show Snackbar with title:$title');
    }
  }
}
