import 'package:flutter/material.dart';
import 'custom_page_route.dart';

/// RouteTransitions provides convenient methods for creating custom page routes
/// with predefined transitions. This ensures consistent navigation experience
/// throughout the app.
class RouteTransitions {
  RouteTransitions._(); // Private constructor to prevent instantiation

  /// Creates a route with slide from right transition (default)
  /// This is the standard transition for most page navigations
  static Route<T> slideRight<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return CustomPageRoute<T>(
      page: page,
      transitionType: PageTransitionType.slideRight,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      settings: settings,
    );
  }

  /// Creates a route with slide from bottom transition
  /// Best for modal-style pages or pages that feel like overlays
  static Route<T> slideBottom<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return CustomPageRoute<T>(
      page: page,
      transitionType: PageTransitionType.slideBottom,
      transitionDuration: duration ?? const Duration(milliseconds: 350),
      settings: settings,
      fullscreenDialog: true,
    );
  }

  /// Creates a route with fade transition
  /// Subtle transition for detail pages or secondary content
  static Route<T> fade<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return CustomPageRoute<T>(
      page: page,
      transitionType: PageTransitionType.fade,
      transitionDuration: duration ?? const Duration(milliseconds: 250),
      settings: settings,
    );
  }

  /// Creates a route with scale transition
  /// Dialog-style transition that scales up from center
  static Route<T> scale<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return CustomPageRoute<T>(
      page: page,
      transitionType: PageTransitionType.scale,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      settings: settings,
    );
  }

  /// Creates a route with no transition (instant navigation)
  /// Use sparingly, only when transitions would be distracting
  static Route<T> none<T>({required Widget page, RouteSettings? settings}) {
    return CustomPageRoute<T>(
      page: page,
      transitionType: PageTransitionType.none,
      transitionDuration: Duration.zero,
      settings: settings,
    );
  }

  /// Creates a route with custom duration and transition type
  static Route<T> custom<T>({
    required Widget page,
    required PageTransitionType transitionType,
    RouteSettings? settings,
    Duration? duration,
    Duration? reverseDuration,
  }) {
    return CustomPageRoute<T>(
      page: page,
      transitionType: transitionType,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      reverseTransitionDuration:
          reverseDuration ?? const Duration(milliseconds: 300),
      settings: settings,
    );
  }
}
