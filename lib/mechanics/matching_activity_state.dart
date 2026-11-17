import '../content/matching_content.dart';
import 'matching_answer_codec.dart';

/// Immutable local interaction state for a tap-to-match activity.
class MatchingActivityState {
  final List<String> leftCardIds;
  final List<String> rightCardIds;
  final Map<String, String> matches;
  final String? selectedLeftId;
  final String? selectedRightId;
  final bool isSubmitted;

  MatchingActivityState._({
    required List<String> leftCardIds,
    required List<String> rightCardIds,
    required Map<String, String> matches,
    required this.selectedLeftId,
    required this.selectedRightId,
    required this.isSubmitted,
  }) : leftCardIds = List.unmodifiable(leftCardIds),
       rightCardIds = List.unmodifiable(rightCardIds),
       matches = Map.unmodifiable(matches);

  factory MatchingActivityState.initial({
    required Iterable<String> leftCardIds,
    required Iterable<String> rightCardIds,
  }) {
    final left = leftCardIds.toList();
    final right = rightCardIds.toList();
    _validateIds(left, 'leftCardIds');
    _validateIds(right, 'rightCardIds');
    if (left.length != right.length || left.length < 2 || left.length > 18) {
      throw ArgumentError(
        'Matching state needs equal left and right card counts from 2 to 18.',
      );
    }
    return MatchingActivityState._(
      leftCardIds: left,
      rightCardIds: right,
      matches: const {},
      selectedLeftId: null,
      selectedRightId: null,
      isSubmitted: false,
    );
  }

  factory MatchingActivityState.forContent(MatchingContent content) =>
      MatchingActivityState.initial(
        leftCardIds: content.leftCards.map((card) => card.id),
        rightCardIds: content.rightCards.map((card) => card.id),
      );

  bool get isComplete =>
      matches.length == leftCardIds.length &&
      matches.keys.toSet().containsAll(leftCardIds) &&
      matches.values.toSet().length == rightCardIds.length &&
      matches.values.toSet().containsAll(rightCardIds);

  bool get canSubmit => isComplete && !isSubmitted;

  int? get answerCode {
    if (!isComplete) return null;
    return const MatchingAnswerCodec().encodeCompletedMapping(
      leftCardIds: leftCardIds,
      rightCardIds: rightCardIds,
      matches: matches,
    );
  }

  MatchingActivityState selectLeft(String leftId) {
    if (isSubmitted || !leftCardIds.contains(leftId)) return this;
    final nextMatches = Map<String, String>.of(matches);
    // Selecting an existing match frees its right card so the child can revise it.
    nextMatches.remove(leftId);

    if (selectedRightId != null) {
      return _completePair(
        leftId,
        selectedRightId!,
        matches: nextMatches,
        selectedLeftId: null,
        selectedRightId: null,
      );
    }
    if (selectedLeftId == leftId && !matches.containsKey(leftId)) {
      return _copyWith(
        matches: nextMatches,
        clearSelectedLeft: true,
        clearSelectedRight: true,
      );
    }
    return _copyWith(
      matches: nextMatches,
      selectedLeftId: leftId,
      clearSelectedRight: true,
    );
  }

  MatchingActivityState selectRight(String rightId) {
    if (isSubmitted ||
        !rightCardIds.contains(rightId) ||
        matches.containsValue(rightId)) {
      return this;
    }
    if (selectedLeftId != null) {
      return _completePair(
        selectedLeftId!,
        rightId,
        matches: Map<String, String>.of(matches),
        selectedLeftId: null,
        selectedRightId: null,
      );
    }
    if (selectedRightId == rightId) {
      return _copyWith(clearSelectedRight: true);
    }
    return _copyWith(selectedRightId: rightId, clearSelectedLeft: true);
  }

  /// Marks the activity submitted only after all pairs have been matched.
  /// Returns this unchanged when incomplete or already submitted.
  MatchingActivityState submit() {
    if (!canSubmit) return this;
    return _copyWith(isSubmitted: true);
  }

  MatchingActivityState _completePair(
    String leftId,
    String rightId, {
    required Map<String, String> matches,
    required String? selectedLeftId,
    required String? selectedRightId,
  }) {
    final assignedElsewhere = matches.entries.any(
      (entry) => entry.key != leftId && entry.value == rightId,
    );
    if (assignedElsewhere) {
      return _copyWith(
        matches: matches,
        selectedLeftId: selectedLeftId ?? leftId,
        selectedRightId: selectedRightId,
      );
    }
    matches[leftId] = rightId;
    return _copyWith(
      matches: matches,
      clearSelectedLeft: true,
      clearSelectedRight: true,
    );
  }

  MatchingActivityState _copyWith({
    Map<String, String>? matches,
    String? selectedLeftId,
    String? selectedRightId,
    bool clearSelectedLeft = false,
    bool clearSelectedRight = false,
    bool? isSubmitted,
  }) => MatchingActivityState._(
    leftCardIds: leftCardIds,
    rightCardIds: rightCardIds,
    matches: matches ?? this.matches,
    selectedLeftId: clearSelectedLeft
        ? null
        : selectedLeftId ?? this.selectedLeftId,
    selectedRightId: clearSelectedRight
        ? null
        : selectedRightId ?? this.selectedRightId,
    isSubmitted: isSubmitted ?? this.isSubmitted,
  );

  static void _validateIds(List<String> ids, String name) {
    if (ids.any((id) => id.trim().isEmpty) ||
        ids.toSet().length != ids.length) {
      throw ArgumentError.value(
        ids,
        name,
        'Card IDs must be unique and non-empty.',
      );
    }
  }
}
