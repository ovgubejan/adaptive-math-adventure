import 'package:adaptive_math_adventure/content/level_catalog.dart';
import 'package:adaptive_math_adventure/navigation/app_router.dart';
import 'package:adaptive_math_adventure/screens/level_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only Level 1 can launch; placeholders remain locked', () {
    expect(LevelCatalog.all, hasLength(25));
    expect(LevelCatalog.canLaunch('level-01'), isTrue);
    expect(
      LevelCatalog.canLaunch('level-02', completedLevelIds: {'level-01'}),
      isFalse,
    );
    expect(LevelCatalog.canLaunch('not-a-level'), isFalse);
  });

  for (final location in ['/play/level-02', '/play/not-a-level']) {
    testWidgets('safely redirects $location', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: location),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LevelSelectionScreen), findsOneWidget);
      expect(
        find.textContaining('unknown, locked, or not available yet'),
        findsOneWidget,
      );
    });
  }
}
