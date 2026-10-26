import 'package:flutter/material.dart';

import '../domain/activity_content.dart';
import '../domain/activity_answer.dart';
import '../domain/math_question.dart';
import '../presentation/counting_theme.dart';

class CountingActivity extends StatelessWidget {
  final MathQuestion question;
  final CountingTheme theme;
  final ValueChanged<ActivityAnswer> onAnswer;
  final int? selectedAnswer;
  final bool answerLocked;

  const CountingActivity({
    required this.question,
    required this.theme,
    required this.onAnswer,
    this.selectedAnswer,
    this.answerLocked = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = ActivityContent.fromQuestion(question);
    final count = content.count!;
    final options = content.answerOptions;

    return Card(
      color: theme.background,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content.prompt,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                count,
                (index) => Icon(
                  theme.objectIcon,
                  key: ValueKey('counting-object-$index'),
                  size: 44,
                  color: theme.objectColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                for (final answer in options)
                  ChoiceChip(
                    label: Text('$answer'),
                    selected: selectedAnswer == answer,
                    onSelected: answerLocked ? null : (_) => onAnswer(answer),
                    labelStyle: TextStyle(
                      color: selectedAnswer == answer
                          ? Colors.white
                          : theme.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedColor: theme.accent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
