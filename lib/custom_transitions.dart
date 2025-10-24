import 'package:flutter/material.dart';

class CustomPageTransitions {
  // Transición estilo Persona: Deslizamiento suave con fade elegante
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
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      ),
    );
  }

  // Transición estilo Persona: Deslizamiento desde izquierda con fade
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
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      ),
    );
  }

  // Transición estilo Persona: Zoom suave con fade elegante
  static Widget scaleWithRotation(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      ),
    );
  }

  // Transición estilo Persona: Deslizamiento desde abajo con fade
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
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      ),
    );
  }

  // Transición estilo Persona: Zoom con fade elegante
  static Widget zoomWithFade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      ),
    );
  }

  // Nueva transición estilo Persona: Slide con escala suave
  static Widget slideWithScale(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: child,
        ),
      ),
    );
  }

  // Nueva transición estilo Persona: Fade con escala mínima
  static Widget fadeWithScale(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.98,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  // Nueva transición estilo Persona: Slide diagonal suave
  static Widget slideDiagonal(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      ),
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
             case 'slideWithScale':
               return CustomPageTransitions.slideWithScale(
                 context,
                 animation,
                 secondaryAnimation,
                 child,
               );
             case 'fadeWithScale':
               return CustomPageTransitions.fadeWithScale(
                 context,
                 animation,
                 secondaryAnimation,
                 child,
               );
             case 'slideDiagonal':
               return CustomPageTransitions.slideDiagonal(
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
