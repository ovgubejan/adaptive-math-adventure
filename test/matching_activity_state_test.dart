import 'package:adaptive_math_adventure/mechanics/matching_activity_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MatchingActivityState initialState() => MatchingActivityState.initial(
    leftCardIds: const ['number_2', 'number_3'],
    rightCardIds: const ['apples_2', 'bananas_3'],
  );

  test('selecting a left card records the selection only', () {
    final state = initialState().selectLeft('number_2');

    expect(state.selectedLeftId, 'number_2');
    expect(state.matches, isEmpty);
    expect(state.isComplete, isFalse);
    expect(state.answerCode, isNull);
  });

  test('right-first selection is completed when a left card is selected', () {
    final state = initialState().selectRight('apples_2').selectLeft('number_2');

    expect(state.matches, const {'number_2': 'apples_2'});
    expect(state.selectedLeftId, isNull);
    expect(state.selectedRightId, isNull);
  });

  test('completes a pair without submitting an answer', () {
    final state = initialState().selectLeft('number_2').selectRight('apples_2');

    expect(state.matches, const {'number_2': 'apples_2'});
    expect(state.isComplete, isFalse);
    expect(state.answerCode, isNull);
    expect(state.isSubmitted, isFalse);
  });

  test('an incorrect match remains a valid local match', () {
    final state = initialState()
        .selectLeft('number_2')
        .selectRight('bananas_3');

    expect(state.matches, const {'number_2': 'bananas_3'});
    expect(state.isComplete, isFalse);
    expect(state.isSubmitted, isFalse);
  });

  test('a matched left card can be selected and rematched', () {
    final state = initialState()
        .selectLeft('number_2')
        .selectRight('bananas_3')
        .selectLeft('number_2');

    expect(state.matches, isEmpty);
    expect(state.selectedLeftId, 'number_2');
    final revised = state.selectRight('apples_2');
    expect(revised.matches, const {'number_2': 'apples_2'});
  });

  test(
    'a right card already assigned to a different left stays unavailable',
    () {
      final state = initialState()
          .selectLeft('number_2')
          .selectRight('apples_2')
          .selectLeft('number_3');

      expect(state.selectRight('apples_2'), same(state));
      expect(state.matches, const {'number_2': 'apples_2'});
      expect(state.selectedLeftId, 'number_3');
    },
  );

  test('completion is derived from a full one-to-one arrangement', () {
    final state = initialState()
        .selectLeft('number_2')
        .selectRight('apples_2')
        .selectLeft('number_3')
        .selectRight('bananas_3');

    expect(state.isComplete, isTrue);
    expect(state.answerCode, 0);
    expect(state.canSubmit, isTrue);
  });

  test('incomplete submission is prevented without changing state', () {
    final state = initialState().selectLeft('number_2');

    expect(state.submit(), same(state));
    expect(state.isSubmitted, isFalse);
    expect(state.answerCode, isNull);
  });

  test('final submission can only happen once', () {
    final complete = initialState()
        .selectLeft('number_2')
        .selectRight('apples_2')
        .selectLeft('number_3')
        .selectRight('bananas_3');
    final submitted = complete.submit();

    expect(submitted.isSubmitted, isTrue);
    expect(submitted.answerCode, 0);
    expect(submitted.submit(), same(submitted));
    expect(submitted.selectLeft('number_2'), same(submitted));
  });
}
