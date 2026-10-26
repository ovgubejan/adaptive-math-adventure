import '../domain/session_result.dart';

abstract interface class SessionResultPersistence {
  Future<List<SessionResult>> loadResults();

  Future<void> saveResult(SessionResult result);
}
