import 'package:flutter/material.dart';

class CustomPageTransitions {
  // Transición de deslizamiento suave desde la derecha
  static Widget slideFromRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  // Transición de deslizamiento suave desde la izquierda
  static Widget slideFromLeft(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  // Transición de escala con rotación suave
  static Widget scaleWithRotation(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.elasticOut)),
      child: RotationTransition(
        turns: Tween<double>(
          begin: 0.5,
          end: 0.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // Transición de deslizamiento desde abajo con bounce
  static Widget slideFromBottom(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.bounceOut)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  // Transición de zoom con fade
  static Widget zoomWithFade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
      ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

class CustomPageRouteBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CustomPageTransitions.slideFromRight(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final String transitionType;
  final Duration duration;

  CustomPageRoute({
    required this.child,
    this.transitionType = 'slideFromRight',
    this.duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           switch (transitionType) {
             case 'slideFromLeft':
               return CustomPageTransitions.slideFromLeft(
                 context,
                 animation,
                 secondaryAnimation,
                 child,
               );
             case 'scaleWithRotation':
               return CustomPageTransitions.scaleWithRotation(
                 context,
                 animation,
                 secondaryAnimation,
                 child,
               );
             case 'slideFromBottom':
               return CustomPageTransitions.slideFromBottom(
                 context,
                 animation,
                 secondaryAnimation,
                 child,
               );
             case 'zoomWithFade':
               return CustomPageTransitions.zoomWithFade(
                 context,
                 animation,
                 secondaryAnimation,
                 child,
               );
             default:
               return CustomPageTransitions.slideFromRight(
                 context,
                 animation,
                 secondaryAnimation,
                 child,
               );
           }
         },
       );
}
