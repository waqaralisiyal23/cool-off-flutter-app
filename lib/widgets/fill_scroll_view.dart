import 'package:flutter/material.dart';

/// A column that fills the screen (so `Spacer`s push buttons to the bottom)
/// but scrolls when its content is taller: large system text, small phones.
class FillScrollView extends StatelessWidget {
  final Widget child;

  const FillScrollView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
