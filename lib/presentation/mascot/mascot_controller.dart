import 'dart:async';

import 'package:flutter/foundation.dart';

import 'mascot_event.dart';
import 'mascot_state.dart';

class MascotController extends ChangeNotifier {
  static const feedbackDuration = Duration(milliseconds: 1400);
  static const completionDuration = Duration(milliseconds: 2200);

  MascotState _state = MascotState.idle;
  int _celebrationId = 0;
  bool _screenTimeLocked = false;
  Timer? _feedbackTimer;

  MascotState get state => _state;
  int get celebrationId => _celebrationId;
  bool get screenTimeLocked => _screenTimeLocked;

  void handleEvent(MascotEvent event) {
    if (event == MascotEvent.screenTimeLockActivated) {
      _screenTimeLocked = true;
      _feedbackTimer?.cancel();
      _setState(MascotState.sleeping);
      return;
    }
    if (event == MascotEvent.screenTimeLockReleased) {
      _screenTimeLocked = false;
      _feedbackTimer?.cancel();
      _setState(MascotState.idle);
      return;
    }
    if (_screenTimeLocked) return;

    switch (event) {
      case MascotEvent.sessionStarted:
      case MascotEvent.questionTransition:
        _feedbackTimer?.cancel();
        _setState(MascotState.idle);
      case MascotEvent.correctAnswer:
        _celebrate(completion: false);
      case MascotEvent.incorrectAnswer:
        _feedbackTimer?.cancel();
        _setState(MascotState.encouraging);
        _returnToIdleAfter(feedbackDuration);
      case MascotEvent.sessionCompleted:
        _celebrate(completion: true);
      case MascotEvent.screenTimeLockActivated:
      case MascotEvent.screenTimeLockReleased:
        break;
    }
  }

  void _celebrate({required bool completion}) {
    _state = MascotState.happy;
    _celebrationId++;
    notifyListeners();
    _returnToIdleAfter(completion ? completionDuration : feedbackDuration);
  }

  void _returnToIdleAfter(Duration duration) {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(duration, () {
      if (_screenTimeLocked) return;
      _setState(MascotState.idle);
    });
  }

  void _setState(MascotState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }
}
