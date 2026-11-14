import 'package:flutter/material.dart';

import 'family/navigation/family_navigation.dart';
import 'navigation/app_router.dart';
import 'style/palette.dart';

class AdaptiveMathAdventureApp extends StatelessWidget {
  const AdaptiveMathAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    return MaterialApp.router(
      title: 'Adaptive Math Adventure',
      theme:
          ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: palette.darkPen,
              surface: palette.backgroundMain,
            ),
            textTheme: TextTheme(bodyMedium: TextStyle(color: palette.ink)),
            useMaterial3: true,
          ).copyWith(
            scaffoldBackgroundColor: palette.backgroundMain,
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      routerConfig: createAppRouter(family: FamilyNavigation.maybeOf(context)),
    );
  }
}
