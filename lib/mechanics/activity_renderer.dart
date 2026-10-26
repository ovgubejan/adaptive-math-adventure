import 'package:flutter/widgets.dart';

import '../domain/activity_answer.dart';
import '../domain/activity_content.dart';
import '../domain/activity_type.dart';
import '../domain/math_question.dart';
import '../presentation/counting_theme.dart';
import 'counting_activity.dart';
import 'drag_drop_activity.dart';
import 'multiple_choice_activity.dart';

class ActivityRenderer extends StatelessWidget {
  final MathQuestion question;
  final CountingTheme theme;
  final ValueChanged<ActivityAnswer> onAnswer;
  final bool answerLocked;

  const ActivityRenderer({
    required this.question,
    required this.theme,
    required this.onAnswer,
    this.answerLocked = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ActivityContent.fromQuestion(question);
    return switch (question.activityType) {
      ActivityType.counting => CountingActivity(
        key: ValueKey(question.id),
        question: question,
        theme: theme,
        onAnswer: onAnswer,
        answerLocked: answerLocked,
      ),
      ActivityType.multipleChoice => MultipleChoiceActivity(
        key: ValueKey(question.id),
        question: question,
        theme: theme,
        onAnswer: onAnswer,
        answerLocked: answerLocked,
      ),
      ActivityType.dragAndDrop => DragDropActivity(
        key: ValueKey(question.id),
        question: question,
        theme: theme,
        onAnswer: onAnswer,
        answerLocked: answerLocked,
      ),
      _ => throw UnsupportedError(
        'No activity renderer registered for ${question.activityType.label}.',
      ),
    };
  }
}
