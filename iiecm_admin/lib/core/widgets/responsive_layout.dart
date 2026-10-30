import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Ensures content remains centered and nicely bounded on tablets, foldables, and wide screens
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = AppConstants.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

