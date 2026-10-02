import 'package:flutter/material.dart';

/// Breakpoint for stacking side-by-side form fields / dense metric rows.
const double kNarrowBreakpoint = 380;

/// Minimum secondary body text size for mobile readability.
const double kMinBodySecondary = 12.0;

/// Minimum recommended touch target (Apple HIG / Material).
const double kMinTapTarget = 44.0;

/// True when the shortest layout width is below [kNarrowBreakpoint].
bool isNarrow(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kNarrowBreakpoint;

/// Ensures [child] is at least [min]×[min] for finger taps.
Widget ensureMinTapTarget({required Widget child, double min = kMinTapTarget}) {
  return ConstrainedBox(
    constraints: BoxConstraints(minWidth: min, minHeight: min),
    child: Center(child: child),
  );
}
