import 'package:flutter/material.dart';

/// Wraps a child widget with [AbsorbPointer] to block all touch events
/// when [isBlocked] is `true`.
class AppInputBlocker extends StatelessWidget {
  final bool isBlocked;
  final Widget child;

  const AppInputBlocker({
    super.key,
    required this.isBlocked,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(absorbing: isBlocked, child: child);
  }
}
