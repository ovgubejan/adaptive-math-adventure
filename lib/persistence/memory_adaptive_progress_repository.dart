import '../domain/adaptive_assessment.dart';
import 'adaptive_progress_repository.dart';

class MemoryAdaptiveProgressRepository implements AdaptiveProgressRepository {
  final Map<String, AdaptiveProgressState> _states = {};

  @override
  Future<List<AdaptiveProgressState>> loadAll() async =>
      List.unmodifiable(_states.values);

  @override
  Future<void> save(AdaptiveProgressState state) async {
    _states[state.levelId] = state;
  }
}
