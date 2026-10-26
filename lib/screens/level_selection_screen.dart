import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../content/level_catalog.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  final bool showUnavailableMessage;

  const LevelSelectionScreen({this.showUnavailableMessage = false, super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      body: ResponsiveScreen(
        topMessageArea: showUnavailableMessage
            ? const Text(
                'That level is unknown, locked, or not available yet.',
                textAlign: TextAlign.center,
              )
            : const SizedBox.shrink(),
        squarishMainArea: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose a level',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: LevelCatalog.all.length,
                itemBuilder: (context, index) {
                  final level = LevelCatalog.all[index];
                  final canLaunch = LevelCatalog.canLaunch(level.id);
                  return ListTile(
                    key: ValueKey('level-${level.number}'),
                    enabled: canLaunch,
                    leading: CircleAvatar(child: Text(level.number.toString())),
                    title: Text(
                      'Level ${level.number}: ${level.learningTopic}',
                    ),
                    subtitle: Text(
                      canLaunch
                          ? level.learningObjective
                          : 'Locked - coming soon',
                    ),
                    trailing: Icon(
                      canLaunch ? Icons.play_arrow : Icons.lock_outline,
                    ),
                    onTap: canLaunch
                        ? () => context.go('/play/${level.id}')
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () => context.go('/'),
          child: const Text('Back'),
        ),
      ),
    );
  }
}
