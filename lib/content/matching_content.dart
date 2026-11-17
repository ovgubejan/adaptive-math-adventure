import '../domain/activity_type.dart';
import '../domain/math_question.dart';
import '../mechanics/matching_answer_codec.dart';

class MatchingLeftCard {
  final String id;
  final String label;

  const MatchingLeftCard({required this.id, required this.label});
}

class MatchingRightCard {
  final String id;
  final String visual;
  final int quantity;

  const MatchingRightCard({
    required this.id,
    required this.visual,
    required this.quantity,
  });
}

class MatchingContent {
  final String prompt;
  final List<MatchingLeftCard> leftCards;
  final List<MatchingRightCard> rightCards;
  final Map<String, String> correctPairs;

  const MatchingContent._({
    required this.prompt,
    required this.leftCards,
    required this.rightCards,
    required this.correctPairs,
  });

  factory MatchingContent.fromQuestion(MathQuestion question) {
    if (question.activityType != ActivityType.matching) {
      throw FormatException(
        'MatchingContent cannot parse ${question.activityType.label}.',
      );
    }

    final prompt = _requiredText(question.data, 'prompt');
    final leftCards = _readLeftCards(question.data['leftCards']);
    final rightCards = _readRightCards(question.data['rightCards']);
    final pairCount = leftCards.length;
    if (pairCount < 2 || pairCount > 6) {
      throw FormatException(
        'Matching question ${question.id} must have 2 to 6 pairs.',
      );
    }
    if (rightCards.length != pairCount) {
      throw FormatException(
        'Matching question ${question.id} must have equal numbers of left and right cards.',
      );
    }

    final leftIds = leftCards.map((card) => card.id).toList();
    final rightIds = rightCards.map((card) => card.id).toList();
    _requireUniqueIds(leftIds, 'leftCards', question.id);
    _requireUniqueIds(rightIds, 'rightCards', question.id);
    final correctPairs = _readCorrectPairs(
      question.data['correctPairs'],
      leftIds: leftIds.toSet(),
      rightIds: rightIds.toSet(),
      questionId: question.id,
    );

    final answerCode = const MatchingAnswerCodec().encodeCompletedMapping(
      leftCardIds: leftIds,
      rightCardIds: rightIds,
      matches: correctPairs,
    );
    if (answerCode != question.correctAnswer) {
      throw FormatException(
        'Matching question ${question.id} has a correctAnswer that does not match correctPairs.',
      );
    }

    return MatchingContent._(
      prompt: prompt,
      leftCards: List.unmodifiable(leftCards),
      rightCards: List.unmodifiable(rightCards),
      correctPairs: Map.unmodifiable(correctPairs),
    );
  }
}

String _requiredText(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Matching content $key must be a non-empty string.');
  }
  return value.trim();
}

List<MatchingLeftCard> _readLeftCards(Object? raw) {
  if (raw is! List) {
    throw const FormatException('Matching content leftCards must be a list.');
  }
  return [
    for (final item in raw)
      MatchingLeftCard(
        id: _requiredText(_asStringObjectMap(item, 'leftCards'), 'id'),
        label: _requiredText(_asStringObjectMap(item, 'leftCards'), 'label'),
      ),
  ];
}

List<MatchingRightCard> _readRightCards(Object? raw) {
  if (raw is! List) {
    throw const FormatException('Matching content rightCards must be a list.');
  }
  return [
    for (final item in raw)
      _parseRightCard(_asStringObjectMap(item, 'rightCards')),
  ];
}

MatchingRightCard _parseRightCard(Map<String, Object?> card) {
  final quantity = card['quantity'];
  if (quantity is! int || quantity < 1 || quantity > 20) {
    throw const FormatException(
      'Matching right card quantity must be an integer from 1 to 20.',
    );
  }
  return MatchingRightCard(
    id: _requiredNullableText(card['id'], 'right card id'),
    visual: _requiredNullableText(card['visual'], 'right card visual'),
    quantity: quantity,
  );
}

Map<String, String> _readCorrectPairs(
  Object? raw, {
  required Set<String> leftIds,
  required Set<String> rightIds,
  required String questionId,
}) {
  if (raw is! List) {
    throw const FormatException(
      'Matching content correctPairs must be a list.',
    );
  }

  final result = <String, String>{};
  final usedRightIds = <String>{};
  for (final item in raw) {
    final pair = _asStringObjectMap(item, 'correctPairs');
    final leftId = _requiredNullableText(pair['leftId'], 'correctPairs.leftId');
    final rightId = _requiredNullableText(
      pair['rightId'],
      'correctPairs.rightId',
    );
    if (!leftIds.contains(leftId) || !rightIds.contains(rightId)) {
      throw FormatException(
        'Matching question $questionId has a correct pair with an unknown card ID.',
      );
    }
    if (result.containsKey(leftId)) {
      throw FormatException(
        'Matching question $questionId uses left card "$leftId" more than once in correctPairs.',
      );
    }
    if (!usedRightIds.add(rightId)) {
      throw FormatException(
        'Matching question $questionId uses right card "$rightId" more than once in correctPairs.',
      );
    }
    result[leftId] = rightId;
  }
  if (result.length != leftIds.length ||
      usedRightIds.length != rightIds.length) {
    throw FormatException(
      'Matching question $questionId must include every left and right card exactly once in correctPairs.',
    );
  }
  return result;
}

void _requireUniqueIds(List<String> ids, String field, String questionId) {
  if (ids.toSet().length != ids.length) {
    throw FormatException(
      'Matching question $questionId must have unique IDs in $field.',
    );
  }
}

Map<String, Object?> _asStringObjectMap(Object? raw, String field) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw FormatException(
      'Each matching $field entry must be an object with string keys.',
    );
  }
  return raw.map((key, value) => MapEntry(key as String, value));
}

String _requiredNullableText(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Matching $field must be a non-empty string.');
  }
  return value.trim();
}
