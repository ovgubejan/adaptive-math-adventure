import '../domain/adaptive_assessment.dart';

abstract interface class AdaptiveProgressRepository {
  Future<List<AdaptiveProgressState>> loadAll();

  Future<void> save(AdaptiveProgressState state);
}
