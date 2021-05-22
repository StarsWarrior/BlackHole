import 'package:flutter/material.dart';

class EmptyScreen {
  Widget emptyScreen(BuildContext context, int turns, String t1, double s1,
      String t2, double s2, String t3, double s3) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotatedBox(
              quarterTurns: turns,
              child: Text(
                t1,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: s1,
                  color: Theme.of(context).accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  t2,
                  style: TextStyle(
                    fontSize: s2,
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  t3,
                  style: TextStyle(
                    fontSize: s3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
