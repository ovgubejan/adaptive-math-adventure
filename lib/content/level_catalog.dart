import '../domain/activity_type.dart';
import '../domain/level_definition.dart';

class LevelCatalog {
  static const int plannedLevelCount = 25;

  static final List<LevelDefinition> all = List.unmodifiable([
    const LevelDefinition(
      id: 'level-01',
      number: 1,
      learningTopic: 'Counting and quantities',
      learningObjective:
          'Count collections and reason about number order and missing quantities.',
      availableActivityTypes: [
        ActivityType.counting,
        ActivityType.multipleChoice,
        ActivityType.dragAndDrop,
      ],
      questionSetReference: 'counting-level-1',
      unlockAfterLevelId: null,
      isImplemented: true,
    ),
    for (var number = 2; number <= plannedLevelCount; number++)
      LevelDefinition(
        id: 'level-${number.toString().padLeft(2, '0')}',
        number: number,
        learningTopic: 'Coming soon',
        learningObjective: 'Learning objective to be defined.',
        availableActivityTypes: const [],
        questionSetReference: 'question-set-level-$number',
        unlockAfterLevelId: 'level-${(number - 1).toString().padLeft(2, '0')}',
        isImplemented: false,
      ),
  ]);

  static LevelDefinition? byId(String id) {
    for (final level in all) {
      if (level.id == id) return level;
    }
    return null;
  }

  static bool canLaunch(String id, {Set<String> completedLevelIds = const {}}) {
    final level = byId(id);
    if (level == null || !level.isImplemented) return false;
    final prerequisite = level.unlockAfterLevelId;
    return prerequisite == null || completedLevelIds.contains(prerequisite);
  }
}
