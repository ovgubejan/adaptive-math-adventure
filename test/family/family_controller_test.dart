import 'package:adaptive_math_adventure/family/application/family_controller.dart';
import 'package:adaptive_math_adventure/family/content/consent_text.dart';
import 'package:adaptive_math_adventure/family/data/child_data_module.dart';
import 'package:adaptive_math_adventure/family/data/key_value_store.dart';
import 'package:adaptive_math_adventure/family/data/local_family_repositories.dart';
import 'package:adaptive_math_adventure/family/domain/trash_entry.dart';
import 'package:adaptive_math_adventure/family/family_config.dart';
import 'package:adaptive_math_adventure/family/family_module.dart';
import 'package:flutter_test/flutter_test.dart';

const _sessionsKey = 'adaptiveMathAdventure.sessionResults.v1';
const _progressKey = 'adaptiveMathAdventure.learningProgress.v1';

class _Harness {
  final prefs = InMemoryKeyValueStore();
  final secure = InMemoryKeyValueStore();
  DateTime now = DateTime(2026, 11, 14, 10);

  /// Aynı depolara bağlı yeni bir denetleyici ("uygulama yeniden açıldı").
  Future<FamilyController> open({bool devMode = false}) async {
    final controller = FamilyModule.local(
      preferences: prefs,
      secureStore: secure,
      clock: () => now,
      devMode: devMode,
    ).controller;
    await controller.load();
    return controller;
  }

  Future<FamilyController> openSetUp() async {
    final controller = await open();
    await controller.completeSetup(nickname: 'Ali', age: 6, pin: '1234');
    return controller;
  }

  Future<void> seedProgress([String marker = 'A']) async {
    await prefs.write(_sessionsKey, 'oturumlar-$marker');
    await prefs.write(_progressKey, 'ilerleme-$marker');
  }
}

void main() {
  late _Harness harness;

  setUp(() => harness = _Harness());

  group('kurulum', () {
    test(
      'ilk açılışta kurulum tamamlanmamıştır ve hiçbir veri yoktur',
      () async {
        final controller = await harness.open();
        expect(controller.isLoaded, isTrue);
        expect(controller.isSetupComplete, isFalse);
        expect(controller.role, FamilyRole.none);
        expect(await harness.prefs.keys(), isEmpty);
        expect(await harness.secure.keys(), isEmpty);
      },
    );

    test('kurulum rıza, profil ve PIN\'i birlikte kaydeder', () async {
      final controller = await harness.openSetUp();
      expect(controller.isSetupComplete, isTrue);
      expect(controller.isConsentCurrent, isTrue);
      expect(controller.profile?.nickname, 'Ali');
      expect(controller.profile?.age, 6);
      expect(controller.consent?.textVersion, ConsentText.version);
      expect(controller.consent?.grantedAt, harness.now);
      expect(controller.consent?.isDevSeed, isFalse);
      expect(controller.role, FamilyRole.none);

      final reopened = await harness.open();
      expect(reopened.isSetupComplete, isTrue);
      expect(reopened.profile?.nickname, 'Ali');
    });

    test(
      'takma ad kırpılır; geçersiz girişte hiçbir şey kaydedilmez',
      () async {
        final controller = await harness.open();
        await expectLater(
          controller.completeSetup(nickname: ' ', age: 6, pin: '1234'),
          throwsArgumentError,
        );
        await expectLater(
          controller.completeSetup(nickname: 'Ali', age: 3, pin: '1234'),
          throwsArgumentError,
        );
        await expectLater(
          controller.completeSetup(nickname: 'Ali', age: 9, pin: '1234'),
          throwsArgumentError,
        );
        await expectLater(
          controller.completeSetup(nickname: 'Ali', age: 6, pin: '12'),
          throwsArgumentError,
        );
        expect(controller.isSetupComplete, isFalse);
        expect(await harness.prefs.keys(), isEmpty);
        expect(await harness.secure.keys(), isEmpty);

        await controller.completeSetup(
          nickname: '  Ali  ',
          age: 6,
          pin: '1234',
        );
        expect(controller.profile?.nickname, 'Ali');
      },
    );

    test('modülün tüm anahtarları family_ önekini taşır', () async {
      await harness.openSetUp();
      for (final key in [
        ...await harness.prefs.keys(),
        ...await harness.secure.keys(),
      ]) {
        expect(key, startsWith(FamilyConfig.storagePrefix));
      }
    });

    test('yarım kalmış kurulum tamamlanmış sayılmaz', () async {
      await harness.openSetUp();
      await harness.secure.delete(LocalParentPinRepository.pinKey);
      expect((await harness.open()).isSetupComplete, isFalse);
    });
  });

  group('rol ve PIN', () {
    test('kurulum yokken çocuk moduna geçilemez', () async {
      final controller = await harness.open();
      controller.enterChildMode();
      expect(controller.role, FamilyRole.none);
    });

    test('ebeveyn bölümü yalnızca doğru PIN ile açılır', () async {
      final controller = await harness.openSetUp();
      expect(await controller.unlockParent('0000'), isA<PinRejected>());
      expect(controller.isParentUnlocked, isFalse);
      expect(await controller.unlockParent('1234'), isA<PinAccepted>());
      expect(controller.isParentUnlocked, isTrue);

      controller.returnToRolePicker();
      expect(controller.role, FamilyRole.none);
      controller.enterChildMode();
      expect(controller.role, FamilyRole.child);
      expect(controller.isParentUnlocked, isFalse);
    });

    test('uygulama yeniden açılınca rol sıfırlanır', () async {
      final controller = await harness.openSetUp();
      await controller.unlockParent('1234');
      expect((await harness.open()).role, FamilyRole.none);
    });

    test('art arda yanlış denemeler girişi geçici olarak kilitler', () async {
      final controller = await harness.openSetUp();
      for (var attempt = 1; attempt < FamilyConfig.maxPinAttempts; attempt++) {
        final result = await controller.checkPin('0000');
        expect(
          (result as PinRejected).remainingAttempts,
          FamilyConfig.maxPinAttempts - attempt,
        );
      }
      final locked = await controller.checkPin('0000');
      expect(
        (locked as PinLocked).until,
        harness.now.add(FamilyConfig.pinLockDuration),
      );

      // Kilitliyken doğru PIN de kabul edilmez; yeniden açmak da kurtarmaz.
      expect(await controller.unlockParent('1234'), isA<PinLocked>());
      expect(controller.isParentUnlocked, isFalse);
      expect(await (await harness.open()).checkPin('1234'), isA<PinLocked>());

      harness.now = harness.now.add(FamilyConfig.pinLockDuration);
      expect(await controller.unlockParent('1234'), isA<PinAccepted>());
    });

    test('doğru PIN yanlış deneme sayacını sıfırlar', () async {
      final controller = await harness.openSetUp();
      await controller.checkPin('0000');
      await controller.checkPin('0000');
      await controller.checkPin('1234');
      final result = await controller.checkPin('0000');
      expect(
        (result as PinRejected).remainingAttempts,
        FamilyConfig.maxPinAttempts - 1,
      );
    });

    test('PIN değiştirilebilir, profil düzenlenebilir', () async {
      final controller = await harness.openSetUp();
      await controller.changePin('9876');
      expect(await controller.checkPin('1234'), isA<PinRejected>());
      expect(await controller.checkPin('9876'), isA<PinAccepted>());

      harness.now = harness.now.add(const Duration(days: 1));
      await controller.updateProfile(nickname: 'Ayşe', age: 7);
      final reopened = await harness.open();
      expect(reopened.profile?.nickname, 'Ayşe');
      expect(reopened.profile?.age, 7);
      expect(reopened.profile?.updatedAt, harness.now);
      await expectLater(
        controller.updateProfile(nickname: 'Ayşe', age: 12),
        throwsArgumentError,
      );
    });
  });

  group('ilerlemeyi sıfırlama ve Silinenler', () {
    test('sıfırlama veriyi Silinenler\'e taşır, profile dokunmaz', () async {
      final controller = await harness.openSetUp();
      await harness.seedProgress();
      await controller.resetProgress();

      expect(await harness.prefs.read(_sessionsKey), isNull);
      expect(await harness.prefs.read(_progressKey), isNull);
      expect(controller.isSetupComplete, isTrue);
      final entry = controller.trashEntries.single;
      expect(entry.reason, TrashReason.progressReset);
      expect(entry.childNickname, 'Ali');
      expect(entry.deletedAt, harness.now);
      expect(entry.snapshots.keys, {'sessionResults', 'adaptiveProgress'});
    });

    test('silinecek veri yoksa boş Silinenler kaydı oluşmaz', () async {
      final controller = await harness.openSetUp();
      await controller.resetProgress();
      expect(controller.trashEntries, isEmpty);
    });

    test(
      'geri yükleme veriyi aynen getirir ve kaydı Silinenler\'den çıkarır',
      () async {
        final controller = await harness.openSetUp();
        await harness.seedProgress('A');
        await controller.resetProgress();
        await controller.restoreFromTrash(controller.trashEntries.single.id);

        expect(await harness.prefs.read(_sessionsKey), 'oturumlar-A');
        expect(await harness.prefs.read(_progressKey), 'ilerleme-A');
        expect(controller.trashEntries, isEmpty);
      },
    );

    test(
      'geri yüklerken o anki ilerleme kaybolmaz, Silinenler\'e geçer',
      () async {
        final controller = await harness.openSetUp();
        await harness.seedProgress('A');
        await controller.resetProgress();
        final oldEntryId = controller.trashEntries.single.id;

        harness.now = harness.now.add(const Duration(days: 2));
        await harness.seedProgress('B');
        await controller.restoreFromTrash(oldEntryId);

        expect(await harness.prefs.read(_sessionsKey), 'oturumlar-A');
        final replaced = controller.trashEntries.single;
        expect(replaced.reason, TrashReason.replacedByRestore);

        await controller.restoreFromTrash(replaced.id);
        expect(await harness.prefs.read(_sessionsKey), 'oturumlar-B');
      },
    );

    test('süre dolunca kayıt uygulama açılışında kalıcı silinir', () async {
      final controller = await harness.openSetUp();
      await harness.seedProgress();
      await controller.resetProgress();

      harness.now = harness.now.add(
        FamilyConfig.trashRetention - const Duration(minutes: 1),
      );
      expect((await harness.open()).trashEntries, hasLength(1));

      harness.now = harness.now.add(const Duration(minutes: 1));
      expect((await harness.open()).trashEntries, isEmpty);
      expect(await harness.prefs.read(LocalTrashRepository.storageKey), isNull);
    });

    test('süresi dolmuş kayıt geri yüklenemez', () async {
      final controller = await harness.openSetUp();
      await harness.seedProgress();
      await controller.resetProgress();
      final id = controller.trashEntries.single.id;
      harness.now = harness.now.add(FamilyConfig.trashRetention);

      await expectLater(controller.restoreFromTrash(id), throwsStateError);
      expect(controller.trashEntries, isEmpty);
      expect(await harness.prefs.read(_sessionsKey), isNull);
    });

    test(
      '"şimdi kalıcı sil" ve "silinenleri boşalt" beklemeden siler',
      () async {
        final controller = await harness.openSetUp();
        await harness.seedProgress('A');
        await controller.resetProgress();
        harness.now = harness.now.add(const Duration(hours: 1));
        await harness.seedProgress('B');
        await controller.resetProgress();
        expect(controller.trashEntries, hasLength(2));

        await controller.purgeFromTrash(controller.trashEntries.first.id);
        expect(controller.trashEntries, hasLength(1));
        await controller.emptyTrash();
        expect(controller.trashEntries, isEmpty);
        expect(
          await harness.prefs.read(LocalTrashRepository.storageKey),
          isNull,
        );
      },
    );
  });

  group('her şeyi silme ve rızayı geri çekme', () {
    test('her şeyi sil (geri alınabilir): yalnızca Silinenler kalır', () async {
      final controller = await harness.openSetUp();
      await controller.unlockParent('1234');
      await harness.seedProgress('A');
      await harness.prefs.write('baskaModul.ayar', 'x');

      await controller.deleteEverything(keepProgressInTrash: true);

      expect(controller.isSetupComplete, isFalse);
      expect(controller.profile, isNull);
      expect(controller.consent, isNull);
      expect(controller.role, FamilyRole.none);
      expect(await harness.prefs.keys(), {LocalTrashRepository.storageKey});
      expect(await harness.secure.keys(), isEmpty);
      expect(controller.trashEntries.single.reason, TrashReason.fullDeletion);

      // Yeniden kurulumdan sonra ilerleme geri yüklenebilir.
      await controller.completeSetup(nickname: 'Ali', age: 6, pin: '5555');
      await controller.restoreFromTrash(controller.trashEntries.single.id);
      expect(await harness.prefs.read(_sessionsKey), 'oturumlar-A');
    });

    test('her şeyi sil (kalıcı): cihazda hiçbir şey kalmaz', () async {
      final controller = await harness.openSetUp();
      await harness.seedProgress('eski');
      await controller.resetProgress();
      await harness.seedProgress('yeni');
      await harness.prefs.write('baskaModul.ayar', 'x');

      await controller.deleteEverything(keepProgressInTrash: false);

      expect(await harness.prefs.keys(), isEmpty);
      expect(await harness.secure.keys(), isEmpty);
      expect(controller.trashEntries, isEmpty);
      expect((await harness.open()).isSetupComplete, isFalse);
    });

    test('rızayı geri çekmek Silinenler dahil her şeyi hemen siler', () async {
      final controller = await harness.openSetUp();
      await harness.seedProgress('eski');
      await controller.resetProgress();
      await harness.seedProgress('yeni');

      await controller.withdrawConsent();

      expect(await harness.prefs.keys(), isEmpty);
      expect(await harness.secure.keys(), isEmpty);
      expect(controller.isSetupComplete, isFalse);
    });

    test('silmeden sonra eski PIN ile hiçbir şey açılmaz', () async {
      final controller = await harness.openSetUp();
      await controller.deleteEverything(keepProgressInTrash: false);
      expect(await controller.unlockParent('1234'), isA<PinRejected>());
      expect(controller.isParentUnlocked, isFalse);
    });
  });

  group('rıza metni sürümü', () {
    FamilyController withVersion(String version) => FamilyController(
      profiles: LocalChildProfileRepository(harness.prefs),
      consents: LocalConsentRepository(harness.prefs),
      pins: LocalParentPinRepository(harness.secure),
      trash: LocalTrashRepository(harness.prefs),
      childData: ChildDataRegistry(const []),
      clock: () => harness.now,
      consentTextVersion: version,
    );

    test('metin sürümü değişince yeniden onay gerekir', () async {
      final first = withVersion('v1');
      await first.load();
      await first.completeSetup(nickname: 'Ali', age: 6, pin: '1234');
      expect(first.isConsentCurrent, isTrue);

      final second = withVersion('v2');
      await second.load();
      expect(second.isSetupComplete, isTrue);
      expect(second.isConsentCurrent, isFalse);
      second.enterChildMode();
      expect(second.role, FamilyRole.none);

      harness.now = harness.now.add(const Duration(days: 3));
      await second.renewConsent();
      expect(second.isConsentCurrent, isTrue);
      expect(second.consent?.textVersion, 'v2');
      expect(second.consent?.grantedAt, harness.now);
    });
  });

  group('geliştirici modu', () {
    test('kurulumu atlar ve kaydı test verisi olarak işaretler', () async {
      final controller = await harness.open(devMode: true);
      expect(controller.devMode, isTrue);
      expect(controller.isSetupComplete, isTrue);
      expect(controller.profile?.nickname, FamilyConfig.devNickname);
      expect(controller.consent?.isDevSeed, isTrue);
      expect(
        await controller.unlockParent(FamilyConfig.devPin),
        isA<PinAccepted>(),
      );
    });

    test('gerçek bir kurulumun üzerine yazmaz', () async {
      await harness.openSetUp();
      final controller = await harness.open(devMode: true);
      expect(controller.profile?.nickname, 'Ali');
      expect(controller.consent?.isDevSeed, isFalse);
      expect(await controller.checkPin('1234'), isA<PinAccepted>());
    });

    test('kapalıyken hiçbir test verisi oluşmaz', () async {
      final controller = await harness.open();
      expect(controller.devMode, isFalse);
      expect(controller.isSetupComplete, isFalse);
    });

    test('test derlemesinde varsayılan olarak kapalıdır', () {
      expect(FamilyConfig.devModeRequested, isFalse);
      expect(FamilyModule.devModeEnabled, isFalse);
    });
  });
}
