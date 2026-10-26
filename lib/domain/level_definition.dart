import 'activity_type.dart';

class LevelDefinition {
  final String id;
  final int number;
  final String learningTopic;
  final String learningObjective;
  final List<ActivityType> availableActivityTypes;
  final String questionSetReference;
  final String? unlockAfterLevelId;
  final bool isImplemented;

  const LevelDefinition({
    required this.id,
    required this.number,
    required this.learningTopic,
    required this.learningObjective,
    required this.availableActivityTypes,
    required this.questionSetReference,
    required this.unlockAfterLevelId,
    required this.isImplemented,
  });
}
