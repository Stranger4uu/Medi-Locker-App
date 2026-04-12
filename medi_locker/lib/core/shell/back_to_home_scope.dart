import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackToHomeScope extends StatelessWidget {
  final Widget child;
  final bool exitOnHome;
  final String homeRoute;

  const BackToHomeScope({
    super.key,
    required this.child,
    this.exitOnHome = false,
    this.homeRoute = '/home',
  });

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return PopScope(
      canPop: exitOnHome && currentLocation == homeRoute,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: child,
    );
  }
}
