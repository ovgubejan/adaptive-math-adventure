import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/adaptive_assessment.dart';
import 'adaptive_progress_repository.dart';

class LocalAdaptiveProgressRepository implements AdaptiveProgressRepository {
  static const _storageKey = 'adaptiveMathAdventure.learningProgress.v1';

  final Future<SharedPreferences> _preferences;

  LocalAdaptiveProgressRepository({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  @override
  Future<List<AdaptiveProgressState>> loadAll() async {
    final preferences = await _preferences;
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return const [];
    final states = jsonDecode(encoded) as List<dynamic>;
    return states
        .map(
          (item) => AdaptiveProgressState.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> save(AdaptiveProgressState state) async {
    final preferences = await _preferences;
    final states = await loadAll();
    final updated = [
      state,
      ...states.where((item) => item.levelId != state.levelId),
    ];
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Adaptive learning progress could not be saved.');
    }
  }
}
