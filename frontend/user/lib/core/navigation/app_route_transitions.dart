import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRouteTransitionStyle {
  fade,
  fadeSlide,
  none,
}

class AppRouteTransitions {
  const AppRouteTransitions._();

  static const Duration _forwardDuration = Duration(milliseconds: 280);
  static const Duration _reverseDuration = Duration(milliseconds: 220);

  static Page<T> buildPage<T>({
    required GoRouterState state,
    required Widget child,
    AppRouteTransitionStyle style = AppRouteTransitionStyle.fadeSlide,
  }) {
    switch (style) {
      case AppRouteTransitionStyle.none:
        return NoTransitionPage<T>(key: state.pageKey, child: child);
      case AppRouteTransitionStyle.fade:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          transitionDuration: _forwardDuration,
          reverseTransitionDuration: _reverseDuration,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(opacity: curvedAnimation, child: child);
          },
        );
      case AppRouteTransitionStyle.fadeSlide:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          transitionDuration: _forwardDuration,
          reverseTransitionDuration: _reverseDuration,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(curvedAnimation);
            final opacityAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation);

            return FadeTransition(
              opacity: opacityAnimation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
        );
    }
  }
}
