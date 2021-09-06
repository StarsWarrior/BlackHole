import 'package:flutter/material.dart';

class ShowSnackBar {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
      BuildContext context, String title,
      {SnackBarAction? action, Duration? duration}) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration ?? const Duration(seconds: 1),
        elevation: 6,
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        content: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        action: action ??
            SnackBarAction(
              textColor: Theme.of(context).accentColor,
              label: 'Ok',
              onPressed: () {},
            ),
      ),
    );
  }
}
