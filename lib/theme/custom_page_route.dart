import 'package:flutter/material.dart';

enum PageTransitionType { fade, slideRight, slideBottom, scale, none }

class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final PageTransitionType transitionType;

  CustomPageRoute({
    required this.page,
    required this.transitionType,
    super.transitionDuration,
    super.reverseTransitionDuration,
    super.settings,
    super.fullscreenDialog,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           switch (transitionType) {
             case PageTransitionType.fade:
               return FadeTransition(opacity: animation, child: child);
             case PageTransitionType.slideRight:
               return SlideTransition(
                 position:
                     Tween<Offset>(
                       begin: const Offset(1.0, 0.0),
                       end: Offset.zero,
                     ).animate(
                       CurvedAnimation(
                         parent: animation,
                         curve: Curves.easeInOutQuart,
                       ),
                     ),
                 child: child,
               );
             case PageTransitionType.slideBottom:
               return SlideTransition(
                 position:
                     Tween<Offset>(
                       begin: const Offset(0.0, 1.0),
                       end: Offset.zero,
                     ).animate(
                       CurvedAnimation(
                         parent: animation,
                         curve: Curves.easeInOutQuart,
                       ),
                     ),
                 child: child,
               );
             case PageTransitionType.scale:
               return ScaleTransition(
                 scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                   CurvedAnimation(
                     parent: animation,
                     curve: Curves.easeOutBack,
                   ),
                 ),
                 child: FadeTransition(opacity: animation, child: child),
               );
             case PageTransitionType.none:
               return child;
           }
         },
       );
}
