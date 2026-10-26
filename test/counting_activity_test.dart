import 'package:adaptive_math_adventure/content/level_catalog.dart';
import 'package:adaptive_math_adventure/content/question_repository.dart';
import 'package:adaptive_math_adventure/mechanics/counting_activity.dart';
import 'package:adaptive_math_adventure/presentation/counting_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final question = QuestionRepository()
      .questionsFor(LevelCatalog.byId('level-01')!)
      .first;

  testWidgets('same counting activity renders three interchangeable themes', (
    tester,
  ) async {
    for (final theme in CountingTheme.themes) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountingActivity(
              question: question,
              theme: theme,
              onAnswer: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CountingActivity), findsOneWidget);
      expect(find.byIcon(theme.objectIcon), findsNWidgets(3));
      expect(find.text('How many?'), findsOneWidget);
    }
    expect(
      CountingTheme.themes.map((theme) => theme.objectIcon).toSet(),
      hasLength(3),
    );
  });
}
