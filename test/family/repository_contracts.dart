// Ebeveyn modülü depo arayüzlerinin ORTAK SÖZLEŞME TESTLERİ.
//
// SUNUCU EKİBİ İÇİN: Bir depo arayüzünün yeni bir uygulamasını (ör. sunucuya
// bağlanan) yazdığınızda buradaki işlevi o uygulama için de çağırın
// (bkz. repository_contract_test.dart). Testler geçiyorsa uygulamanın geri
// kalanı yeni deponuzla çalışır.
//
// Her `create` çağrısı AYNI kalıcı depoya bağlı yeni bir nesne dönmelidir;
// böylece "uygulama yeniden açıldı" durumu sınanır. `reset` depoyu boşaltır.

import 'package:adaptive_math_adventure/family/data/family_repositories.dart';
import 'package:adaptive_math_adventure/family/domain/child_profile.dart';
import 'package:adaptive_math_adventure/family/domain/consent_record.dart';
import 'package:adaptive_math_adventure/family/domain/trash_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void runChildProfileRepositoryContract(
  String name, {
  required ChildProfileRepository Function() create,
  required Future<void> Function() reset,
}) {
  group('ChildProfileRepository sözleşmesi — $name', () {
    setUp(reset);

    final profile = ChildProfile(
      nickname: 'Ali',
      age: 6,
      createdAt: DateTime.utc(2026, 11, 14, 9),
      updatedAt: DateTime.utc(2026, 11, 14, 9),
    );

    test('kayıt yokken null döner', () async {
      expect(await create().load(), isNull);
    });

    test('kaydedilen profil yeniden açılınca aynen okunur', () async {
      await create().save(profile);
      final loaded = await create().load();
      expect(loaded?.nickname, 'Ali');
      expect(loaded?.age, 6);
      expect(loaded?.createdAt, profile.createdAt);
    });

    test('kaydetmek öncekinin üzerine yazar', () async {
      await create().save(profile);
      await create().save(profile.copyWith(nickname: 'Ayşe', age: 7));
      final loaded = await create().load();
      expect(loaded?.nickname, 'Ayşe');
      expect(loaded?.age, 7);
    });

    test('silince kayıt kalmaz; olmayan kaydı silmek hata vermez', () async {
      await create().save(profile);
      await create().delete();
      expect(await create().load(), isNull);
      await create().delete();
    });
  });
}

void runConsentRepositoryContract(
  String name, {
  required ConsentRepository Function() create,
  required Future<void> Function() reset,
}) {
  group('ConsentRepository sözleşmesi — $name', () {
    setUp(reset);

    final record = ConsentRecord(
      textVersion: 'v-test',
      grantedAt: DateTime.utc(2026, 11, 14, 9),
    );

    test('kayıt yokken null döner', () async {
      expect(await create().load(), isNull);
    });

    test('rıza kaydı sürümü ve zamanıyla saklanır', () async {
      await create().save(record);
      final loaded = await create().load();
      expect(loaded?.textVersion, 'v-test');
      expect(loaded?.grantedAt, record.grantedAt);
      expect(loaded?.isActive, isTrue);
      expect(loaded?.isDevSeed, isFalse);
    });

    test('silince kayıt kalmaz', () async {
      await create().save(record);
      await create().delete();
      expect(await create().load(), isNull);
    });
  });
}

void runParentPinRepositoryContract(
  String name, {
  required ParentPinRepository Function() create,
  required Future<void> Function() reset,
}) {
  group('ParentPinRepository sözleşmesi — $name', () {
    setUp(reset);

    test('PIN yokken hasPin false, hiçbir PIN eşleşmez', () async {
      expect(await create().hasPin(), isFalse);
      expect(await create().matches('1234'), isFalse);
    });

    test('yalnızca doğru PIN eşleşir (yeniden açılınca da)', () async {
      await create().setPin('1234');
      expect(await create().hasPin(), isTrue);
      expect(await create().matches('1234'), isTrue);
      expect(await create().matches('1235'), isFalse);
      expect(await create().matches(''), isFalse);
    });

    test('geçersiz PIN reddedilir', () async {
      final repository = create();
      for (final invalid in ['', '123', '12345', '12a4', '١٢٣٤']) {
        await expectLater(repository.setPin(invalid), throwsArgumentError);
      }
      expect(await repository.hasPin(), isFalse);
    });

    test('PIN değişince eskisi geçersiz olur', () async {
      await create().setPin('1234');
      await create().setPin('9876');
      expect(await create().matches('1234'), isFalse);
      expect(await create().matches('9876'), isTrue);
    });

    test('deneme durumu saklanır; PIN belirlenince sıfırlanır', () async {
      final until = DateTime.utc(2026, 11, 14, 9, 0, 30);
      await create().saveAttemptState(
        PinAttemptState(failedAttempts: 3, lockedUntil: until),
      );
      final loaded = await create().loadAttemptState();
      expect(loaded.failedAttempts, 3);
      expect(loaded.lockedUntil, until);

      await create().setPin('1234');
      final afterSet = await create().loadAttemptState();
      expect(afterSet.failedAttempts, 0);
      expect(afterSet.lockedUntil, isNull);
    });

    test('clear PIN\'i ve deneme durumunu siler', () async {
      await create().setPin('1234');
      await create().saveAttemptState(const PinAttemptState(failedAttempts: 2));
      await create().clear();
      expect(await create().hasPin(), isFalse);
      expect((await create().loadAttemptState()).failedAttempts, 0);
    });
  });
}

void runTrashRepositoryContract(
  String name, {
  required TrashRepository Function() create,
  required Future<void> Function() reset,
}) {
  group('TrashRepository sözleşmesi — $name', () {
    setUp(reset);

    TrashEntry entry(String id, DateTime deletedAt) => TrashEntry(
      id: id,
      deletedAt: deletedAt,
      reason: TrashReason.progressReset,
      childNickname: 'Ali',
      snapshots: {'module-$id': 'snapshot-$id'},
    );

    test('boşken boş liste döner', () async {
      expect(await create().loadAll(), isEmpty);
    });

    test('kayıtlar en yeni silinen başta olacak şekilde okunur', () async {
      await create().add(entry('eski', DateTime.utc(2026, 11, 1)));
      await create().add(entry('yeni', DateTime.utc(2026, 11, 10)));
      await create().add(entry('orta', DateTime.utc(2026, 11, 5)));
      final loaded = await create().loadAll();
      expect(loaded.map((item) => item.id), ['yeni', 'orta', 'eski']);
      expect(loaded.first.snapshots, {'module-yeni': 'snapshot-yeni'});
      expect(loaded.first.childNickname, 'Ali');
      expect(loaded.first.reason, TrashReason.progressReset);
    });

    test('remove yalnızca verilen kaydı siler', () async {
      await create().add(entry('a', DateTime.utc(2026, 11, 1)));
      await create().add(entry('b', DateTime.utc(2026, 11, 2)));
      await create().remove('a');
      await create().remove('yok');
      expect((await create().loadAll()).map((item) => item.id), ['b']);
    });

    test('clear hepsini siler', () async {
      await create().add(entry('a', DateTime.utc(2026, 11, 1)));
      await create().clear();
      expect(await create().loadAll(), isEmpty);
    });
  });
}
