import 'activity_type.dart';
import 'math_question.dart';

class ActivityContent {
  final String prompt;
  final List<int> answerOptions;
  final int? count;

  const ActivityContent._({
    required this.prompt,
    required this.answerOptions,
    this.count,
  });

  factory ActivityContent.fromQuestion(MathQuestion question) {
    final prompt = _readPrompt(question.data);
    final options = _readOptions(question.data);
    if (options.isEmpty ||
        options.toSet().length != options.length ||
        !options.contains(question.correctAnswer)) {
      throw FormatException(
        'Question ${question.id} must have unique integer answer options '
        'including its correct answer.',
      );
    }

    switch (question.activityType) {
      case ActivityType.counting:
        final count = question.data['count'];
        if (count is! int || count < 1 || count > 20) {
          throw FormatException(
            'Counting question ${question.id} must have a count from 1 to 20.',
          );
        }
        return ActivityContent._(
          prompt: prompt,
          answerOptions: List.unmodifiable(options),
          count: count,
        );
      case ActivityType.multipleChoice:
      case ActivityType.dragAndDrop:
        return ActivityContent._(
          prompt: prompt,
          answerOptions: List.unmodifiable(options),
        );
      case ActivityType.matching:
      case ActivityType.patterns:
        throw FormatException(
          'Activity type ${question.activityType.label} is not supported yet.',
        );
    }
  }

  static String _readPrompt(Map<String, Object> data) {
    final prompt = data['prompt'];
    if (prompt is! String || prompt.trim().isEmpty) {
      throw const FormatException(
        'Question prompt must be a non-empty string.',
      );
    }
    return prompt;
  }

  static List<int> _readOptions(Map<String, Object> data) {
    final rawOptions = data['answerOptions'];
    if (rawOptions is! List || rawOptions.any((value) => value is! int)) {
      throw const FormatException(
        'Question answerOptions must be a list of integers.',
      );
    }
    return rawOptions.cast<int>();
  }
}
