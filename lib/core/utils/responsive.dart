import 'package:flutter/widgets.dart';

/// Responsive breakpoint helpers used across all role shells.
class Breakpoints {
  Breakpoints._();
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1280;
}

extension ResponsiveContext on BuildContext {
  bool get isMobile => MediaQuery.sizeOf(this).width < Breakpoints.mobile;
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= Breakpoints.mobile &&
      MediaQuery.sizeOf(this).width < Breakpoints.tablet;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= Breakpoints.tablet;
  bool get isWide => MediaQuery.sizeOf(this).width >= Breakpoints.desktop;
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;
}
