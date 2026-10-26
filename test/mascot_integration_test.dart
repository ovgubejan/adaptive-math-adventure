import 'package:adaptive_math_adventure/content/question_repository.dart';
import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/persistence/session_result_persistence.dart';
import 'package:adaptive_math_adventure/presentation/mascot/mascot_controller.dart';
import 'package:adaptive_math_adventure/presentation/mascot/mascot_event.dart';
import 'package:adaptive_math_adventure/presentation/mascot/mascot_session_event_bridge.dart';
import 'package:adaptive_math_adventure/presentation/mascot/mascot_state.dart';
import 'package:adaptive_math_adventure/presentation/mascot/mascot_widget.dart';
import 'package:adaptive_math_adventure/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryPersistence implements SessionResultPersistence {
  final List<SessionResult> results = [];

  @override
  Future<List<SessionResult>> loadResults() async => List.of(results);

  @override
  Future<void> saveResult(SessionResult result) async => results.add(result);
}

void main() {
  testWidgets('correct and incorrect answers select appropriate expressions', (
    tester,
  ) async {
    final mascot = MascotController();
    addTearDown(mascot.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: mascot,
            builder: (context, _) => MascotWidget(
              state: mascot.state,
              celebrationId: mascot.celebrationId,
              size: 100,
            ),
          ),
        ),
      ),
    );

    mascot.handleEvent(MascotEvent.correctAnswer);
    await tester.pump();
    expect(mascot.state, MascotState.happy);
    expect(find.byKey(const ValueKey('celebration-sparkle')), findsOneWidget);

    mascot.handleEvent(MascotEvent.incorrectAnswer);
    await tester.pump();
    expect(mascot.state, MascotState.encouraging);
    expect(find.byKey(const ValueKey('celebration-sparkle')), findsNothing);
    await tester.pump(MascotController.feedbackDuration);
    expect(mascot.state, MascotState.idle);
  });

  testWidgets('consecutive correct events replay the celebration', (
    tester,
  ) async {
    final mascot = MascotController();
    addTearDown(mascot.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: mascot,
            builder: (context, _) => MascotWidget(
              state: mascot.state,
              celebrationId: mascot.celebrationId,
            ),
          ),
        ),
      ),
    );

    mascot.handleEvent(MascotEvent.correctAnswer);
    await tester.pump();
    final firstCelebrationId = mascot.celebrationId;
    mascot.handleEvent(MascotEvent.correctAnswer);
    await tester.pump();

    expect(mascot.celebrationId, firstCelebrationId + 1);
    expect(find.byKey(const ValueKey('celebration-sparkle')), findsOneWidget);
    await tester.pump(MascotController.feedbackDuration);
  });

  testWidgets('sleeping has priority over gameplay celebrations', (
    tester,
  ) async {
    final mascot = MascotController();
    addTearDown(mascot.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: mascot,
            builder: (context, _) => MascotWidget(
              state: mascot.state,
              celebrationId: mascot.celebrationId,
            ),
          ),
        ),
      ),
    );

    mascot.handleEvent(MascotEvent.screenTimeLockActivated);
    mascot.handleEvent(MascotEvent.correctAnswer);
    mascot.handleEvent(MascotEvent.sessionCompleted);
    await tester.pump();

    expect(mascot.state, MascotState.sleeping);
    expect(find.byKey(const ValueKey('celebration-sparkle')), findsNothing);
    expect(find.byKey(const ValueKey(MascotState.sleeping)), findsOneWidget);
  });

  testWidgets('widget does not animate a celebration while sleeping', (
    tester,
  ) async {
    var celebrationId = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              MascotWidget(
                state: MascotState.sleeping,
                celebrationId: celebrationId,
              ),
              TextButton(
                onPressed: () => setState(() => celebrationId++),
                child: const Text('Send celebration'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Send celebration'));
    await tester.pump();

    expect(find.byKey(const ValueKey('celebration-sparkle')), findsNothing);
    expect(
      find.byKey(const ValueKey<MascotState>(MascotState.sleeping)),
      findsOneWidget,
    );
  });

  testWidgets('animation controllers dispose when mascot widget is removed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MascotWidget(state: MascotState.idle)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(tester.takeException(), isNull);
  });

  test(
    'session events update mascot without changing answer decisions',
    () async {
      final session = SessionController(
        questionRepository: QuestionRepository(),
        persistence: _MemoryPersistence(),
      );
      final mascot = MascotController();
      final bridge = MascotSessionEventBridge(session, mascot)..attach();
      addTearDown(bridge.dispose);
      addTearDown(session.dispose);
      addTearDown(mascot.dispose);

      await session.startSession('level-01');
      expect(mascot.state, MascotState.idle);
      final incorrect = session.submitAnswer(-1);
      expect(incorrect, isFalse);
      expect(mascot.state, MascotState.encouraging);

      await session.advance();
      expect(mascot.state, MascotState.idle);
      final correct = session.submitAnswer(
        session.currentQuestion!.correctAnswer,
      );
      expect(correct, isTrue);
      expect(mascot.state, MascotState.happy);

      for (var index = 2; index < session.questionCount; index++) {
        await session.advance();
        session.submitAnswer(session.currentQuestion!.correctAnswer);
      }
      await session.advance();

      expect(session.status, SessionStatus.completed);
      expect(session.result?.correctCount, session.questionCount - 1);
      expect(mascot.state, MascotState.happy);
    },
  );
}
