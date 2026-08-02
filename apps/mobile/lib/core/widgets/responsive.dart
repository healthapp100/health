import 'package:flutter/material.dart';

/// Material 3's window-size-class breakpoints (compact/medium/expanded), used app-wide so every
/// screen agrees on what counts as "phone" vs "tablet" vs "desktop" instead of each screen
/// picking its own width cutoff.
enum WindowSizeClass { compact, medium, expanded }

WindowSizeClass windowSizeClassOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 840) return WindowSizeClass.expanded;
  if (width >= 600) return WindowSizeClass.medium;
  return WindowSizeClass.compact;
}

bool isCompact(BuildContext context) => windowSizeClassOf(context) == WindowSizeClass.compact;

/// Centers content and caps its width on tablet/desktop so text lines and cards don't stretch
/// edge-to-edge on a wide window — every top-level feature screen's body should be wrapped in
/// this. No-op (full width) on phone-sized (compact) windows.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveContent({super.key, required this.child, this.maxWidth = 900});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Column count for grid-shaped content (Home's quick actions, Track's vitals summary) that
/// should show more columns as the window widens, rather than staying a fixed 2/4-wide grid
/// that leaves large empty margins on a tablet or desktop window.
int responsiveGridColumns(
  BuildContext context, {
  int compact = 2,
  int medium = 3,
  int expanded = 4,
}) {
  return switch (windowSizeClassOf(context)) {
    WindowSizeClass.compact => compact,
    WindowSizeClass.medium => medium,
    WindowSizeClass.expanded => expanded,
  };
}
