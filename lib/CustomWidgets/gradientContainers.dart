import 'package:blackhole/Helpers/config.dart';
import 'package:flutter/material.dart';

class GradientContainer extends StatefulWidget {
  final Widget child;
  final bool opacity;
  GradientContainer({@required this.child, this.opacity});
  @override
  _GradientContainerState createState() => _GradientContainerState();
}

class _GradientContainerState extends State<GradientContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? ((widget.opacity == true)
                  ? currentTheme.getTransBackGradient()
                  : currentTheme.getBackGradient())
              : [
                  Colors.white,
                  Theme.of(context).canvasColor,
                ],
        ),
      ),
      child: widget.child,
    );
  }
}

class BottomGradientContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  BottomGradientContainer(
      {@required this.child, this.margin, this.padding, this.borderRadius});
  @override
  _BottomGradientContainerState createState() =>
      _BottomGradientContainerState();
}

class _BottomGradientContainerState extends State<BottomGradientContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? EdgeInsets.fromLTRB(25, 0, 25, 25),
      padding: widget.padding ?? EdgeInsets.fromLTRB(10, 15, 10, 15),
      decoration: BoxDecoration(
        borderRadius:
            widget.borderRadius ?? BorderRadius.all(Radius.circular(15.0)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? currentTheme.getBottomGradient()
              : [
                  Colors.white,
                  Theme.of(context).canvasColor,
                ],
        ),
      ),
      child: widget.child,
    );
  }
}

class GradientCard extends StatefulWidget {
  final Widget child;
  final bool miniplayer;
  final double radius;
  GradientCard({@required this.child, this.miniplayer, this.radius});
  @override
  _GradientCardState createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.radius ?? 10.0),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? currentTheme.getCardGradient(
                    miniplayer: widget.miniplayer ?? false)
                : [
                    Colors.white,
                    Theme.of(context).canvasColor,
                  ],
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
