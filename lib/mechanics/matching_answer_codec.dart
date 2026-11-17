/// Encodes a complete one-to-one card matching as a permutation rank.
///
/// Card IDs are sorted before ranking, so the answer does not depend on the
/// order in which cards are displayed or supplied to this codec. For a fixed
/// pair count, every valid mapping has a distinct rank from `0` to `n! - 1`.
class MatchingAnswerCodec {
  const MatchingAnswerCodec();

  static const int minimumPairCount = 2;
  static const int maximumPairCount = 18;

  /// Returns the zero-based Lehmer rank for a completed matching.
  ///
  /// Throws [ArgumentError] when the card IDs or mapping do not form a
  /// permutation, or when the pair count is outside the supported range.
  int encodeCompletedMapping({
    required Iterable<String> leftCardIds,
    required Iterable<String> rightCardIds,
    required Map<String, String> matches,
  }) {
    final leftIds = _validatedSortedIds(leftCardIds, 'leftCardIds');
    final rightIds = _validatedSortedIds(rightCardIds, 'rightCardIds');

    if (leftIds.length != rightIds.length) {
      throw ArgumentError('Left and right card counts must be equal.');
    }
    if (leftIds.length < minimumPairCount ||
        leftIds.length > maximumPairCount) {
      throw ArgumentError.value(
        leftIds.length,
        'pairCount',
        'Expected $minimumPairCount-$maximumPairCount pairs.',
      );
    }

    final leftSet = leftIds.toSet();
    final rightSet = rightIds.toSet();
    final assignedRights = matches.values.toSet();
    if (matches.length != leftIds.length ||
        matches.keys.toSet().length != matches.length ||
        matches.keys.toSet().difference(leftSet).isNotEmpty ||
        leftSet.difference(matches.keys.toSet()).isNotEmpty ||
        assignedRights.length != matches.length ||
        assignedRights.difference(rightSet).isNotEmpty ||
        rightSet.difference(assignedRights).isNotEmpty) {
      throw ArgumentError(
        'matches must map every left card to a distinct right card exactly once.',
      );
    }

    final availableRights = List<String>.of(rightIds);
    var rank = 0;
    for (var index = 0; index < leftIds.length; index++) {
      final rightId = matches[leftIds[index]]!;
      final rightIndex = availableRights.indexOf(rightId);
      if (rightIndex < 0) {
        throw ArgumentError('matches contains an invalid right card ID.');
      }
      rank += rightIndex * _factorial(leftIds.length - index - 1);
      availableRights.removeAt(rightIndex);
    }
    return rank;
  }

  List<String> _validatedSortedIds(Iterable<String> ids, String name) {
    final result = ids.toList()..sort();
    if (result.any((id) => id.trim().isEmpty)) {
      throw ArgumentError.value(ids, name, 'Card IDs must not be empty.');
    }
    if (result.toSet().length != result.length) {
      throw ArgumentError.value(ids, name, 'Card IDs must be unique.');
    }
    return result;
  }

  int _factorial(int value) {
    var result = 1;
    for (var factor = 2; factor <= value; factor++) {
      result *= factor;
    }
    return result;
  }
}
