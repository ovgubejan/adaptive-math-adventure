import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/session_result.dart';
import 'session_result_persistence.dart';

class LocalSessionResultPersistence implements SessionResultPersistence {
  static const _storageKey = 'adaptiveMathAdventure.sessionResults.v1';

  final Future<SharedPreferences> _preferences;

  LocalSessionResultPersistence({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  @override
  Future<List<SessionResult>> loadResults() async {
    final preferences = await _preferences;
    final stored = preferences.getString(_storageKey);
    if (stored == null) return const [];
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              SessionResult.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<void> saveResult(SessionResult result) async {
    final preferences = await _preferences;
    final results = await loadResults();
    final updated = [
      result,
      ...results.where((item) => item.sessionId != result.sessionId),
    ];
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Local session result could not be saved.');
    }
  }
}
