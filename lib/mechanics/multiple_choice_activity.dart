import 'package:flutter/material.dart';

import '../domain/activity_answer.dart';
import '../domain/activity_content.dart';
import '../domain/activity_type.dart';
import '../domain/math_question.dart';
import '../presentation/counting_theme.dart';

class MultipleChoiceActivity extends StatelessWidget {
  final MathQuestion question;
  final CountingTheme theme;
  final ValueChanged<ActivityAnswer> onAnswer;
  final bool answerLocked;

  const MultipleChoiceActivity({
    required this.question,
    required this.theme,
    required this.onAnswer,
    this.answerLocked = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = ActivityContent.fromQuestion(question);
    if (question.activityType != ActivityType.multipleChoice) {
      throw FormatException(
        'MultipleChoiceActivity cannot render ${question.activityType.label}.',
      );
    }

    return Card(
      color: theme.background,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final answer in content.answerOptions)
                  ChoiceChip(
                    key: ValueKey('multiple-choice-$answer'),
                    label: Text('$answer'),
                    selected: false,
                    onSelected: answerLocked ? null : (_) => onAnswer(answer),
                    labelStyle: TextStyle(
                      color: theme.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
