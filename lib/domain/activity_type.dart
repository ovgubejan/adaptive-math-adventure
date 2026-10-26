enum ActivityType { counting, multipleChoice, dragAndDrop, matching, patterns }

extension ActivityTypeLabel on ActivityType {
  String get label => switch (this) {
    ActivityType.counting => 'Counting',
    ActivityType.multipleChoice => 'Multiple choice',
    ActivityType.dragAndDrop => 'Drag and drop',
    ActivityType.matching => 'Matching',
    ActivityType.patterns => 'Patterns',
  };
}
