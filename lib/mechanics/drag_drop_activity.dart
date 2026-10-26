import 'package:flutter/material.dart';

import '../domain/activity_answer.dart';
import '../domain/activity_content.dart';
import '../domain/activity_type.dart';
import '../domain/math_question.dart';
import '../presentation/counting_theme.dart';

class DragDropActivity extends StatefulWidget {
  final MathQuestion question;
  final CountingTheme theme;
  final ValueChanged<ActivityAnswer> onAnswer;
  final bool answerLocked;

  const DragDropActivity({
    required this.question,
    required this.theme,
    required this.onAnswer,
    this.answerLocked = false,
    super.key,
  });

  @override
  State<DragDropActivity> createState() => _DragDropActivityState();
}

class _DragDropActivityState extends State<DragDropActivity> {
  int? _selectedAnswer;
  int? _droppedAnswer;
  bool _submitted = false;

  @override
  void didUpdateWidget(covariant DragDropActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _selectedAnswer = null;
      _droppedAnswer = null;
      _submitted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = ActivityContent.fromQuestion(widget.question);
    if (widget.question.activityType != ActivityType.dragAndDrop) {
      throw FormatException(
        'DragDropActivity cannot render ${widget.question.activityType.label}.',
      );
    }
    final locked = widget.answerLocked || _submitted;
    final displayedAnswer = _droppedAnswer ?? _selectedAnswer;

    return Card(
      color: widget.theme.background,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            DragTarget<int>(
              onWillAcceptWithDetails: (details) =>
                  !locked && content.answerOptions.contains(details.data),
              onAcceptWithDetails: (details) =>
                  _submit(details.data, dropped: true),
              builder: (context, candidates, rejected) {
                final hovering = candidates.isNotEmpty;
                return Semantics(
                  label:
                      'Answer target. Drop a number here or select a number below.',
                  child: Container(
                    key: const ValueKey('drag-answer-target'),
                    constraints: const BoxConstraints(
                      minWidth: 180,
                      minHeight: 76,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hovering
                          ? widget.theme.accent.withValues(alpha: 0.2)
                          : Colors.white,
                      border: Border.all(
                        color: hovering
                            ? widget.theme.accent
                            : widget.theme.objectColor,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        displayedAnswer == null
                            ? 'Drop answer here'
                            : 'Answer: $displayedAnswer',
                        style: TextStyle(
                          color: widget.theme.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final answer in content.answerOptions)
                  Draggable<int>(
                    data: answer,
                    maxSimultaneousDrags: locked ? 0 : 1,
                    feedback: _answerChip(answer, isFeedback: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _answerChip(answer),
                    ),
                    child: Semantics(
                      button: true,
                      label: 'Select answer $answer',
                      child: InkWell(
                        key: ValueKey('drag-answer-$answer'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: locked
                            ? null
                            : () => setState(() => _selectedAnswer = answer),
                        child: _answerChip(
                          answer,
                          selected: _selectedAnswer == answer,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('submit-selected-answer'),
              onPressed: locked || _selectedAnswer == null
                  ? null
                  : () => _submit(_selectedAnswer!),
              icon: const Icon(Icons.check),
              label: const Text('Submit selected answer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerChip(
    int answer, {
    bool selected = false,
    bool isFeedback = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? widget.theme.accent : Colors.white,
        border: Border.all(color: widget.theme.accent, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFeedback
            ? const [BoxShadow(color: Colors.black26, blurRadius: 8)]
            : null,
      ),
      child: Text(
        '$answer',
        style: TextStyle(
          color: selected ? Colors.white : widget.theme.accent,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _submit(int answer, {bool dropped = false}) {
    if (_submitted || widget.answerLocked) return;
    _submitted = true;
    if (dropped) {
      _droppedAnswer = answer;
    }
    setState(() {});
    widget.onAnswer(answer);
  }
}
