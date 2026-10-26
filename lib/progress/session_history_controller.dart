import 'package:flutter/foundation.dart';

import '../domain/adaptive_assessment.dart';
import '../domain/session_result.dart';
import '../persistence/adaptive_progress_repository.dart';
import '../persistence/session_result_persistence.dart';

class SessionHistoryController extends ChangeNotifier {
  final SessionResultPersistence _persistence;
  final AdaptiveProgressRepository? _adaptiveProgress;

  List<SessionResult> _results = const [];
  List<AdaptiveProgressState> _learningStates = const [];
  bool _isLoading = true;
  String? _errorMessage;

  SessionHistoryController(this._persistence, [this._adaptiveProgress]);

  List<SessionResult> get results => List.unmodifiable(_results);
  SessionResult? get latestResult => _results.isEmpty ? null : _results.first;
  List<AdaptiveProgressState> get learningStates =>
      List.unmodifiable(_learningStates);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _results = await _persistence.loadResults();
      _learningStates = await _adaptiveProgress?.loadAll() ?? const [];
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _errorMessage = 'Saved session history could not be loaded: $error';
      notifyListeners();
    }
  }
}
