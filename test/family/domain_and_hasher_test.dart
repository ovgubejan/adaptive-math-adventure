import 'dart:convert';

import 'package:adaptive_math_adventure/family/data/key_value_store.dart';
import 'package:adaptive_math_adventure/family/data/local_family_repositories.dart';
import 'package:adaptive_math_adventure/family/data/pin_hasher.dart';
import 'package:adaptive_math_adventure/family/domain/child_profile.dart';
import 'package:adaptive_math_adventure/family/domain/consent_record.dart';
import 'package:adaptive_math_adventure/family/domain/trash_entry.dart';
import 'package:adaptive_math_adventure/family/family_config.dart';
import 'package:flutter_test/flutter_test.dart';

String _hex(String base64Value) => base64Decode(
  base64Value,
).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('yaş ve takma ad kuralları', () {
    test('hedef yaş aralığı 4-8', () {
      expect(FamilyConfig.minChildAge, 4);
      expect(FamilyConfig.maxChildAge, 8);
      expect(ChildProfile.validateAge(3), isNotNull);
      expect(ChildProfile.validateAge(4), isNull);
      expect(ChildProfile.validateAge(8), isNull);
      expect(ChildProfile.validateAge(9), isNotNull);
      expect(ChildProfile.validateAge(null), isNotNull);
    });

    test('takma ad boş veya çok uzun olamaz', () {
      expect(ChildProfile.validateNickname('   '), isNotNull);
      expect(ChildProfile.validateNickname('Ali'), isNull);
      expect(
        ChildProfile.validateNickname('a' * FamilyConfig.maxNicknameLength),
        isNull,
      );
      expect(
        ChildProfile.validateNickname(
          'a' * (FamilyConfig.maxNicknameLength + 1),
        ),
        isNotNull,
      );
    });
  });

  group('şema toleransı', () {
    test('profil sürüm numarasıyla yazılır', () {
      final json = ChildProfile(
        nickname: 'Ali',
        age: 6,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ).toJson();
      expect(json['schemaVersion'], FamilyConfig.schemaVersion);
    });

    test('bilinmeyen alanlar okunur ve geri yazılırken korunur', () {
      final profile = ChildProfile.tryFromJson({
        'schemaVersion': 99,
        'nickname': 'Ali',
        'age': 6,
        'createdAt': '2026-11-14T09:00:00.000Z',
        'updatedAt': '2026-11-14T09:00:00.000Z',
        'serverId': 'abc-123',
        'avatar': {'color': 'blue'},
      });
      expect(profile, isNotNull);
      final rewritten = profile!.copyWith(age: 7).toJson();
      expect(rewritten['serverId'], 'abc-123');
      expect(rewritten['avatar'], {'color': 'blue'});
      expect(rewritten['age'], 7);

      final consent = ConsentRecord.tryFromJson({
        'textVersion': 'v1',
        'grantedAt': '2026-11-14T09:00:00.000Z',
        'syncedAt': '2026-11-15T09:00:00.000Z',
      });
      expect(consent!.toJson()['syncedAt'], '2026-11-15T09:00:00.000Z');
    });

    test('eksik veya bozuk kayıt çökme yerine null döner', () {
      expect(ChildProfile.tryFromJson(null), isNull);
      expect(ChildProfile.tryFromJson('metin'), isNull);
      expect(ChildProfile.tryFromJson({'nickname': 'Ali'}), isNull);
      expect(ChildProfile.tryFromJson({'nickname': 5, 'age': 6}), isNull);
      expect(ConsentRecord.tryFromJson({'textVersion': 'v1'}), isNull);
      expect(ConsentRecord.tryFromJson([1, 2]), isNull);
      expect(TrashEntry.tryFromJson({'id': 'a'}), isNull);
    });

    test('eksik tarih alanları profili geçersiz kılmaz', () {
      final profile = ChildProfile.tryFromJson({'nickname': 'Ali', 'age': 6});
      expect(profile?.nickname, 'Ali');
    });

    test('depodaki bozuk JSON çökme yerine "kayıt yok" sayılır', () async {
      final store = InMemoryKeyValueStore({
        LocalChildProfileRepository.storageKey: '{bozuk',
        LocalConsentRepository.storageKey: 'null',
        LocalTrashRepository.storageKey: '{"liste":"değil"}',
        LocalParentPinRepository.pinKey: '[]',
      });
      expect(await LocalChildProfileRepository(store).load(), isNull);
      expect(await LocalConsentRepository(store).load(), isNull);
      expect(await LocalTrashRepository(store).loadAll(), isEmpty);
      expect(await LocalParentPinRepository(store).hasPin(), isFalse);
    });

    test('geri çekilmiş rıza etkin sayılmaz', () {
      final consent = ConsentRecord.tryFromJson({
        'textVersion': 'v1',
        'grantedAt': '2026-11-14T09:00:00.000Z',
        'withdrawnAt': '2026-11-15T09:00:00.000Z',
      });
      expect(consent!.isActive, isFalse);
    });
  });

  group('Silinenler kaydı', () {
    final deletedAt = DateTime.utc(2026, 11, 1, 12);
    final entry = TrashEntry(
      id: 'a',
      deletedAt: deletedAt,
      reason: TrashReason.fullDeletion,
      snapshots: const {'m': 's'},
    );

    test('saklama süresi 30 gündür', () {
      expect(FamilyConfig.trashRetention, const Duration(days: 30));
      expect(entry.expiresAt, DateTime.utc(2026, 12, 1, 12));
    });

    test('süre dolmadan geçerli, dolduğu anda süresi dolmuş sayılır', () {
      expect(entry.isExpired(deletedAt), isFalse);
      expect(
        entry.isExpired(deletedAt.add(const Duration(days: 30, seconds: -1))),
        isFalse,
      );
      expect(entry.isExpired(deletedAt.add(const Duration(days: 30))), isTrue);
    });

    test('kalan gün yukarı yuvarlanır ve eksiye düşmez', () {
      expect(entry.daysLeft(deletedAt), 30);
      expect(entry.daysLeft(deletedAt.add(const Duration(hours: 1))), 30);
      expect(entry.daysLeft(deletedAt.add(const Duration(days: 29))), 1);
      expect(entry.daysLeft(deletedAt.add(const Duration(days: 45))), 0);
    });

    test('JSON gidiş-dönüşü ve bilinmeyen sebep toleransı', () {
      final decoded = TrashEntry.tryFromJson(
        jsonDecode(jsonEncode(entry.toJson())),
      );
      expect(decoded?.id, 'a');
      expect(decoded?.reason, TrashReason.fullDeletion);
      expect(decoded?.snapshots, {'m': 's'});

      final unknownReason = TrashEntry.tryFromJson({
        ...entry.toJson(),
        'reason': 'gelecekte-eklenen',
      });
      expect(unknownReason?.reason, TrashReason.progressReset);
    });
  });

  group('PIN özetleme', () {
    final salt = base64Encode(utf8.encode('salt'));

    test('PBKDF2-HMAC-SHA256 bilinen test vektörleriyle uyuşur', () {
      final hasher = PinHasher();
      expect(
        _hex(hasher.hash('password', salt, iterations: 1)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        _hex(hasher.hash('password', salt, iterations: 2)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('her PIN için yeni tuz üretilir', () {
      final hasher = PinHasher();
      expect(hasher.newSalt(), isNot(hasher.newSalt()));
      expect(base64Decode(hasher.newSalt()), hasLength(16));
    });

    test('PIN düz metin olarak saklanmaz', () async {
      final store = InMemoryKeyValueStore();
      await LocalParentPinRepository(store).setPin('4821');
      final stored =
          jsonDecode((await store.read(LocalParentPinRepository.pinKey))!)
              as Map<String, dynamic>;
      expect(stored.keys.toSet(), {
        'schemaVersion',
        'algorithm',
        'iterations',
        'salt',
        'hash',
      });
      expect(stored['algorithm'], PinHasher.algorithm);
      expect(stored['iterations'], greaterThanOrEqualTo(10000));
      expect(stored.values, isNot(contains('4821')));
    });

    test('aynı PIN iki kurulumda farklı özet verir (tuz sayesinde)', () async {
      final first = InMemoryKeyValueStore();
      final second = InMemoryKeyValueStore();
      await LocalParentPinRepository(first).setPin('4821');
      await LocalParentPinRepository(second).setPin('4821');
      expect(
        await first.read(LocalParentPinRepository.pinKey),
        isNot(await second.read(LocalParentPinRepository.pinKey)),
      );
    });

    test('isValidPin yalnızca dört ASCII rakamı kabul eder', () {
      expect(LocalParentPinRepository.isValidPin('0000'), isTrue);
      expect(LocalParentPinRepository.isValidPin('000'), isFalse);
      expect(LocalParentPinRepository.isValidPin('00000'), isFalse);
      expect(LocalParentPinRepository.isValidPin('12 4'), isFalse);
      expect(LocalParentPinRepository.isValidPin('１２３４'), isFalse);
    });

    test('constantTimeEquals', () {
      expect(PinHasher.constantTimeEquals('abc', 'abc'), isTrue);
      expect(PinHasher.constantTimeEquals('abc', 'abd'), isFalse);
      expect(PinHasher.constantTimeEquals('abc', 'ab'), isFalse);
    });
  });
}
