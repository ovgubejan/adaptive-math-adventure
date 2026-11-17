import 'package:flutter/material.dart';

import '../content/matching_content.dart';
import '../domain/activity_answer.dart';
import '../domain/math_question.dart';
import '../presentation/counting_theme.dart';
import 'matching_activity_state.dart';

/// Standalone tap-to-match activity. It does not depend on ActivityRenderer.
class MatchingActivity extends StatefulWidget {
  final MathQuestion question;
  final CountingTheme theme;
  final ValueChanged<ActivityAnswer> onAnswer;
  final bool answerLocked;

  const MatchingActivity({
    required this.question,
    required this.theme,
    required this.onAnswer,
    this.answerLocked = false,
    super.key,
  });

  @override
  State<MatchingActivity> createState() => _MatchingActivityState();
}

class _MatchingActivityState extends State<MatchingActivity> {
  late MatchingContent _content;
  late MatchingActivityState _activityState;

  @override
  void initState() {
    super.initState();
    _resetForQuestion();
  }

  @override
  void didUpdateWidget(covariant MatchingActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) _resetForQuestion();
  }

  void _resetForQuestion() {
    _content = MatchingContent.fromQuestion(widget.question);
    _activityState = MatchingActivityState.forContent(_content);
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.answerLocked || _activityState.isSubmitted;
    return Card(
      color: widget.theme.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _content.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap one number, then tap its picture group.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCardColumn(
                    context,
                    heading: 'Numbers',
                    children: [
                      for (final card in _content.leftCards)
                        _leftCard(card, locked),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCardColumn(
                    context,
                    heading: 'Pictures',
                    children: [
                      for (final card in _content.rightCards)
                        _rightCard(card, locked),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Matches: ${_activityState.matches.length} of ${_content.leftCards.length}',
              key: const ValueKey('matching-progress'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('matching-submit'),
                onPressed: locked || !_activityState.canSubmit ? null : _submit,
                icon: const Icon(Icons.check),
                label: const Text('Check matches'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardColumn(
    BuildContext context, {
    required String heading,
    required List<Widget> children,
  }) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(heading, style: Theme.of(context).textTheme.titleMedium),
      ),
      for (final child in children) ...[child, const SizedBox(height: 8)],
    ],
  );

  Widget _leftCard(MatchingLeftCard card, bool locked) {
    final selected = _activityState.selectedLeftId == card.id;
    final matched = _activityState.matches.containsKey(card.id);
    return _tapCard(
      key: ValueKey('matching-left-${card.id}'),
      semanticsLabel: 'Number ${card.label}${matched ? ', matched' : ''}',
      selected: selected,
      matched: matched,
      locked: locked,
      onTap: () => _updateState(_activityState.selectLeft(card.id)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              card.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : widget.theme.accent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (selected || matched) ...[
            const SizedBox(width: 4),
            Icon(
              selected ? Icons.radio_button_checked : Icons.check_circle,
              key: ValueKey(
                selected
                    ? 'matching-left-selected-${card.id}'
                    : 'matching-left-matched-${card.id}',
              ),
              color: selected ? Colors.white : widget.theme.objectColor,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _rightCard(MatchingRightCard card, bool locked) {
    final selected = _activityState.selectedRightId == card.id;
    final matched = _activityState.matches.containsValue(card.id);
    return _tapCard(
      key: ValueKey('matching-right-${card.id}'),
      semanticsLabel:
          '${card.quantity} ${_visualName(card.visual)}${matched ? ', matched' : ''}',
      selected: selected,
      matched: matched,
      locked: locked || (matched && !selected),
      onTap: () => _updateState(_activityState.selectRight(card.id)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 1,
            children: [
              for (var index = 0; index < card.quantity; index++)
                Text(
                  _visualGlyph(card.visual),
                  key: ValueKey('matching-visual-${card.id}-$index'),
                  style: const TextStyle(fontSize: 22),
                ),
            ],
          ),
          if (selected || matched)
            Icon(
              selected ? Icons.radio_button_checked : Icons.check_circle,
              key: ValueKey(
                selected
                    ? 'matching-right-selected-${card.id}'
                    : 'matching-right-matched-${card.id}',
              ),
              color: selected ? Colors.white : widget.theme.objectColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _tapCard({
    required Key key,
    required String semanticsLabel,
    required bool selected,
    required bool matched,
    required bool locked,
    required VoidCallback onTap,
    required Widget child,
  }) => Semantics(
    button: true,
    label: semanticsLabel,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(14),
        onTap: locked || widget.answerLocked || _activityState.isSubmitted
            ? null
            : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? widget.theme.accent
                  : matched
                  ? widget.theme.objectColor.withValues(alpha: 0.14)
                  : Colors.white,
              border: Border.all(
                color: selected
                    ? widget.theme.accent
                    : matched
                    ? widget.theme.objectColor
                    : widget.theme.accent.withValues(alpha: 0.45),
                width: selected || matched ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );

  void _updateState(MatchingActivityState nextState) {
    if (widget.answerLocked || _activityState.isSubmitted) return;
    if (identical(nextState, _activityState)) return;
    setState(() => _activityState = nextState);
  }

  void _submit() {
    if (widget.answerLocked || !_activityState.canSubmit) return;
    final nextState = _activityState.submit();
    final answerCode = nextState.answerCode;
    if (answerCode == null || identical(nextState, _activityState)) return;
    setState(() => _activityState = nextState);
    widget.onAnswer(answerCode);
  }
}

String _visualName(String visual) => visual.toLowerCase();

String _visualGlyph(String visual) => switch (visual.toLowerCase()) {
  'apple' => '🍎',
  'banana' => '🍌',
  'orange' => '🍊',
  'strawberry' => '🍓',
  'pear' => '🍐',
  'grape' => '🍇',
  'star' => '⭐',
  'flower' => '🌼',
  _ => visual,
};
