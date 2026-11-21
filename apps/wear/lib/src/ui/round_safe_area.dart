import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Insets [child] so it fits inside the circle inscribed in the screen.
///
/// On a round display the corners of the bounding square are invisible; the
/// largest visible square has side `diameter / sqrt(2)`. On square screens
/// set [round] to false to use only a small margin.
class RoundSafeArea extends StatelessWidget {
  const RoundSafeArea({super.key, required this.child, this.round = true});

  final Widget child;
  final bool round;

  /// Fraction of the side lost on each edge on a round screen (~0.146).
  static final double roundInsetFraction = (1 - 1 / math.sqrt2) / 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final inset = round ? side * roundInsetFraction : side * 0.04;
        return Padding(padding: EdgeInsets.all(inset), child: child);
      },
    );
  }
}
