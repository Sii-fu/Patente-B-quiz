import 'package:flutter/material.dart';

/// Max content width for quiz/reading/form screens.
/// Prevents extreme horizontal stretching on tablets and desktop emulators
/// (e.g. Bluestacks, iPads) without changing the feel on normal phones.
const double kMaxContentWidth = 600.0;

/// Breakpoint: screens at or above this width are treated as "tablet or larger".
const double kTabletBreakpoint = 600.0;

/// Wraps [child] in a [Center] + [ConstrainedBox] (default [kMaxContentWidth]).
///
/// Drop this around any scrollable body or form that must not stretch
/// infinitely on wide displays:
/// ```dart
/// body: ResponsiveLayout(child: SingleChildScrollView(...))
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Exposes [isMobile] / [isTablet] breakpoints inside a [builder] callback.
///
/// Uses [LayoutBuilder] so it reacts to the **parent's constraints**, not the
/// raw screen size. This is safe inside lists, grids, and constrained
/// containers.
///
/// Example:
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, isMobile, isTablet) {
///     return isTablet
///         ? GridView(crossAxisCount: 3, ...)
///         : ListView(...);
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet)
      builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= kTabletBreakpoint;
        return builder(context, !isTablet, isTablet);
      },
    );
  }
}
