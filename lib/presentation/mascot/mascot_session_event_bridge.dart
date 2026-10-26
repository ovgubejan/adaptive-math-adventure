import '../../session/session_controller.dart';
import 'mascot_controller.dart';
import 'mascot_event.dart';

class MascotSessionEventBridge {
  final SessionController _session;
  final MascotController _mascot;
  SessionStatus? _previousStatus;
  int? _previousQuestionIndex;
  bool _previousCanAdvance = false;

  MascotSessionEventBridge(this._session, this._mascot);

  void attach() {
    _session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  void dispose() {
    _session.removeListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    final status = _session.status;
    final index = _session.currentIndex;

    if (status == SessionStatus.active &&
        _previousStatus != SessionStatus.active) {
      _mascot.handleEvent(MascotEvent.sessionStarted);
    }
    if (status == SessionStatus.active &&
        _previousQuestionIndex != null &&
        _previousQuestionIndex != index) {
      _mascot.handleEvent(MascotEvent.questionTransition);
    }
    if (status == SessionStatus.active &&
        _session.canAdvance &&
        !_previousCanAdvance) {
      _mascot.handleEvent(
        _session.lastAnswerCorrect == true
            ? MascotEvent.correctAnswer
            : MascotEvent.incorrectAnswer,
      );
    }
    if (status == SessionStatus.completed &&
        _previousStatus != SessionStatus.completed) {
      _mascot.handleEvent(MascotEvent.sessionCompleted);
    }

    _previousStatus = status;
    _previousQuestionIndex = index;
    _previousCanAdvance = _session.canAdvance;
  }
}
