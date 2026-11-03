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
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (padding != EdgeInsets.zero) {
      content = Padding(padding: padding, child: content);
    }

    return Align(alignment: Alignment.topCenter, child: content);
  }
}
