import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../content/level_catalog.dart';
import '../screens/level_selection_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/play_session_screen.dart';
import '../screens/session_results_screen.dart';

GoRouter createAppRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
    GoRoute(
      path: '/levels',
      builder: (context, state) => LevelSelectionScreen(
        showUnavailableMessage: state.uri.queryParameters['unavailable'] == '1',
      ),
    ),
    GoRoute(
      path: '/demo',
      builder: (context, state) =>
          const PlaySessionScreen(levelId: 'activity-demo', demoMode: true),
    ),
    GoRoute(
      path: '/play/:levelId',
      redirect: (context, state) {
        final levelId = state.pathParameters['levelId'];
        return levelId != null && LevelCatalog.canLaunch(levelId)
            ? null
            : '/levels?unavailable=1';
      },
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: PlaySessionScreen(levelId: state.pathParameters['levelId']!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const SessionResultsScreen(),
    ),
  ],
  errorBuilder: (context, state) =>
      LevelSelectionScreen(showUnavailableMessage: true),
);
