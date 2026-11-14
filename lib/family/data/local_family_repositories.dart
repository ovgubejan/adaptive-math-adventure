import 'dart:convert';

import '../domain/child_profile.dart';
import '../domain/consent_record.dart';
import '../domain/trash_entry.dart';
import '../family_config.dart';
import 'family_repositories.dart';
import 'key_value_store.dart';
import 'pin_hasher.dart';

/// Depo arayüzlerinin cihazda çalışan (yerel) uygulamaları.
///
/// Sunucu desteği eklendiğinde bu sınıflar silinmez; çevrimdışı çalışma ve
/// önbellek için kalır.

Object? _decodeOrNull(String? encoded) {
  if (encoded == null) return null;
  try {
    return jsonDecode(encoded);
  } on FormatException {
    return null;
  }
}

class LocalChildProfileRepository implements ChildProfileRepository {
  static const storageKey = '${FamilyConfig.storagePrefix}child_profile_v1';

  final KeyValueStore _store;

  LocalChildProfileRepository(this._store);

  @override
  Future<ChildProfile?> load() async =>
      ChildProfile.tryFromJson(_decodeOrNull(await _store.read(storageKey)));

  @override
  Future<void> save(ChildProfile profile) =>
      _store.write(storageKey, jsonEncode(profile.toJson()));

  @override
  Future<void> delete() => _store.delete(storageKey);
}

class LocalConsentRepository implements ConsentRepository {
  static const storageKey = '${FamilyConfig.storagePrefix}consent_v1';

  final KeyValueStore _store;

  LocalConsentRepository(this._store);

  @override
  Future<ConsentRecord?> load() async =>
      ConsentRecord.tryFromJson(_decodeOrNull(await _store.read(storageKey)));

  @override
  Future<void> save(ConsentRecord record) =>
      _store.write(storageKey, jsonEncode(record.toJson()));

  @override
  Future<void> delete() => _store.delete(storageKey);
}

/// PIN özetini saklar. Uygulamada [SecureKeyValueStore] ile kullanılır.
class LocalParentPinRepository implements ParentPinRepository {
  static const pinKey = '${FamilyConfig.storagePrefix}parent_pin_v1';
  static const attemptsKey = '${FamilyConfig.storagePrefix}pin_attempts_v1';

  final KeyValueStore _store;
  final PinHasher _hasher;

  LocalParentPinRepository(this._store, {PinHasher? hasher})
    : _hasher = hasher ?? PinHasher();

  /// PIN tam olarak [FamilyConfig.pinLength] rakamdan mı oluşuyor?
  static bool isValidPin(String pin) =>
      pin.length == FamilyConfig.pinLength &&
      pin.codeUnits.every((unit) => unit >= 0x30 && unit <= 0x39);

  @override
  Future<bool> hasPin() async => await _readRecord() != null;

  @override
  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError(
        'PIN ${FamilyConfig.pinLength} rakamdan oluşmalıdır.',
      );
    }
    final salt = _hasher.newSalt();
    await _store.write(
      pinKey,
      jsonEncode({
        'schemaVersion': FamilyConfig.schemaVersion,
        'algorithm': PinHasher.algorithm,
        'iterations': _hasher.iterations,
        'salt': salt,
        'hash': _hasher.hash(pin, salt),
      }),
    );
    await saveAttemptState(PinAttemptState.none);
  }

  @override
  Future<bool> matches(String pin) async {
    final record = await _readRecord();
    if (record == null) return false;
    final candidate = _hasher.hash(
      pin,
      record.salt,
      iterations: record.iterations,
    );
    return PinHasher.constantTimeEquals(candidate, record.hash);
  }

  @override
  Future<PinAttemptState> loadAttemptState() async {
    final json = _decodeOrNull(await _store.read(attemptsKey));
    if (json is! Map) return PinAttemptState.none;
    final failed = json['failedAttempts'];
    final lockedUntil = json['lockedUntil'];
    return PinAttemptState(
      failedAttempts: failed is int && failed > 0 ? failed : 0,
      lockedUntil: lockedUntil is String
          ? DateTime.tryParse(lockedUntil)
          : null,
    );
  }

  @override
  Future<void> saveAttemptState(PinAttemptState state) async {
    if (state.failedAttempts == 0 && state.lockedUntil == null) {
      await _store.delete(attemptsKey);
      return;
    }
    await _store.write(
      attemptsKey,
      jsonEncode({
        'failedAttempts': state.failedAttempts,
        'lockedUntil': state.lockedUntil?.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> clear() async {
    await _store.delete(pinKey);
    await _store.delete(attemptsKey);
  }

  Future<({String salt, String hash, int iterations})?> _readRecord() async {
    final json = _decodeOrNull(await _store.read(pinKey));
    if (json is! Map) return null;
    final salt = json['salt'];
    final hash = json['hash'];
    final iterations = json['iterations'];
    if (salt is! String || hash is! String || iterations is! int) return null;
    if (iterations < 1) return null;
    return (salt: salt, hash: hash, iterations: iterations);
  }
}

class LocalTrashRepository implements TrashRepository {
  static const storageKey = '${FamilyConfig.storagePrefix}trash_v1';

  final KeyValueStore _store;

  LocalTrashRepository(this._store);

  @override
  Future<List<TrashEntry>> loadAll() async {
    final json = _decodeOrNull(await _store.read(storageKey));
    if (json is! List) return const [];
    final entries = [for (final item in json) ?TrashEntry.tryFromJson(item)]
      ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return entries;
  }

  @override
  Future<void> add(TrashEntry entry) async {
    final entries = await loadAll();
    await _save([entry, ...entries.where((item) => item.id != entry.id)]);
  }

  @override
  Future<void> remove(String id) async {
    final entries = await loadAll();
    await _save(entries.where((item) => item.id != id).toList());
  }

  @override
  Future<void> clear() => _store.delete(storageKey);

  Future<void> _save(List<TrashEntry> entries) async {
    if (entries.isEmpty) {
      await _store.delete(storageKey);
      return;
    }
    await _store.write(
      storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}
