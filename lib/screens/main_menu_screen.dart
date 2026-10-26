import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../progress/session_history_controller.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    final history = context.watch<SessionHistoryController>();
    return Scaffold(
      backgroundColor: palette.backgroundMain,
      body: ResponsiveScreen(
        squarishMainArea: Center(
          child: Text(
            'Adaptive Math\nAdventure',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.darkPen,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        rectangularMenuArea: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyButton(
              onPressed: () => context.go('/levels'),
              child: const Text('Play'),
            ),
            const SizedBox(height: 12),
            MyButton(
              onPressed: () => context.go('/demo'),
              child: const Text('Try activity demo'),
            ),
            const SizedBox(height: 12),
            if (history.latestResult != null)
              MyButton(
                onPressed: () => context.go('/results'),
                child: const Text('Last session'),
              ),
            if (history.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  history.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
