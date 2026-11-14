import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/family/application/family_controller.dart';
import 'package:adaptive_math_adventure/family/content/consent_text.dart';
import 'package:adaptive_math_adventure/family/data/key_value_store.dart';
import 'package:adaptive_math_adventure/family/data/local_family_repositories.dart';
import 'package:adaptive_math_adventure/family/family_config.dart';
import 'package:adaptive_math_adventure/family/navigation/family_navigation.dart';
import 'package:adaptive_math_adventure/family/screens/consent_update_screen.dart';
import 'package:adaptive_math_adventure/family/screens/data_management_screen.dart';
import 'package:adaptive_math_adventure/family/screens/legal_text_screen.dart';
import 'package:adaptive_math_adventure/family/screens/parent_dashboard_screen.dart';
import 'package:adaptive_math_adventure/family/screens/parent_settings_screen.dart';
import 'package:adaptive_math_adventure/family/screens/pin_gate_screen.dart';
import 'package:adaptive_math_adventure/family/screens/role_picker_screen.dart';
import 'package:adaptive_math_adventure/family/screens/setup_flow_screen.dart';
import 'package:adaptive_math_adventure/persistence/local_session_result_persistence.dart';
import 'package:adaptive_math_adventure/screens/level_selection_screen.dart';
import 'package:adaptive_math_adventure/screens/main_menu_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'family_test_harness.dart';

Future<void> _seedSession(String id, DateTime completedAt, int correct) =>
    LocalSessionResultPersistence().saveResult(
      SessionResult(
        sessionId: id,
        levelId: 'level-01',
        startedAt: completedAt.subtract(const Duration(minutes: 3)),
        completedAt: completedAt,
        evidence: [
          for (var index = 0; index < 5; index++)
            QuestionEvidence(
              questionId: '$id-q$index',
              skillTag: index.isEven ? 'counting-sets' : 'number-sequence',
              difficulty: 1,
              attempts: [
                AnswerAttempt(
                  answer: 1,
                  isCorrect: index < correct,
                  responseTime: const Duration(seconds: 3),
                  hintUsed: false,
                ),
              ],
            ),
        ],
      ),
    );

Future<void> _openParentArea(WidgetTester tester, [String? pin]) async {
  await tapKey(tester, 'role-parent');
  await enterPinOnPad(tester, pin ?? familyTestPin);
}

/// Onay penceresinde PIN'i yazar ve onaylar.
Future<void> _confirmWithPin(WidgetTester tester, [String? pin]) async {
  await tester.enterText(
    find.byKey(const ValueKey('confirm-pin')),
    pin ?? familyTestPin,
  );
  await tapKey(tester, 'confirm-accept');
}

Future<void> _openDataManagement(WidgetTester tester) async {
  await _openParentArea(tester);
  await tapKey(tester, 'parent-settings');
  await tapKey(tester, 'settings-open-data');
  expect(find.byType(DataManagementScreen), findsOneWidget);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ilk açılış kurulumu', () {
    testWidgets('kurulum bitmeden oyun ekranlarına ulaşılamaz', (tester) async {
      await pumpFamilyApp(tester, startAs: FamilyTestStart.firstLaunch);
      expect(find.byType(SetupFlowScreen), findsOneWidget);

      for (final location in ['/', '/levels', '/play/level-01', '/parent']) {
        await goTo(tester, location);
        expect(find.byType(SetupFlowScreen), findsOneWidget, reason: location);
        expect(find.byType(MainMenuScreen), findsNothing, reason: location);
      }
    });

    testWidgets('rıza onaylanmadan çocuk bilgisi adımına geçilemez', (
      tester,
    ) async {
      final module = await pumpFamilyApp(
        tester,
        startAs: FamilyTestStart.firstLaunch,
      );
      await tapKey(tester, 'setup-start');

      expect(find.text(ConsentText.consentStatement), findsOneWidget);
      final continueButton = find.byKey(
        const ValueKey('setup-consent-continue'),
      );
      await tapAndPump(tester, continueButton);
      expect(find.byKey(const ValueKey('setup-nickname')), findsNothing);

      // Tam metin okunabilir.
      await tapKey(tester, 'consent-read-full');
      expect(find.byType(LegalTextScreen), findsOneWidget);
      expect(find.text(ConsentText.sections.first.title), findsOneWidget);
      await tapKey(tester, 'legal-close');

      await tapKey(tester, 'consent-checkbox');
      await tapAndPump(tester, continueButton);
      expect(find.byKey(const ValueKey('setup-nickname')), findsOneWidget);

      // Henüz hiçbir şey kaydedilmedi.
      expect(module.controller.isSetupComplete, isFalse);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });

    testWidgets('kurulum tamamlanınca rol seçimi açılır ve kayıtlar oluşur', (
      tester,
    ) async {
      final secure = InMemoryKeyValueStore();
      final module = await pumpFamilyApp(
        tester,
        startAs: FamilyTestStart.firstLaunch,
        secureStore: secure,
      );
      await tapKey(tester, 'setup-start');
      await tapKey(tester, 'consent-checkbox');
      await tapKey(tester, 'setup-consent-continue');

      // Eksik bilgiyle devam edilemez.
      await tapKey(tester, 'setup-child-continue');
      expect(find.byKey(const ValueKey('setup-error')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('setup-nickname')),
        'Ayşe',
      );
      for (
        var age = FamilyConfig.minChildAge;
        age <= FamilyConfig.maxChildAge;
        age++
      ) {
        expect(find.byKey(ValueKey('age-$age')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('age-3')), findsNothing);
      expect(find.byKey(const ValueKey('age-9')), findsNothing);
      await tapKey(tester, 'age-5');
      await tapKey(tester, 'setup-child-continue');

      // Tekrarı tutmayan PIN kabul edilmez.
      await enterPinOnPad(tester, '2580');
      await enterPinOnPad(tester, '2581');
      expect(find.byKey(const ValueKey('setup-error')), findsOneWidget);
      expect(module.controller.isSetupComplete, isFalse);

      await enterPinOnPad(tester, '2580');
      await enterPinOnPad(tester, '2580');

      expect(find.byType(RolePickerScreen), findsOneWidget);
      expect(find.text('Ben Ayşe\'yim'), findsOneWidget);
      expect(module.controller.profile?.nickname, 'Ayşe');
      expect(module.controller.profile?.age, 5);
      expect(module.controller.consent?.textVersion, ConsentText.version);
      expect(module.controller.consent?.isDevSeed, isFalse);
      expect(await secure.read(LocalParentPinRepository.pinKey), isNotNull);
      expect(await module.controller.checkPin('2580'), isA<PinAccepted>());
    });

    testWidgets('uygulama yeniden açılınca kurulum tekrar sorulmaz', (
      tester,
    ) async {
      final secure = InMemoryKeyValueStore();
      await pumpFamilyApp(tester, secureStore: secure);
      expect(find.byType(RolePickerScreen), findsOneWidget);

      final reopened = await pumpFamilyApp(tester, secureStore: secure);
      expect(find.byType(RolePickerScreen), findsOneWidget);
      expect(find.byType(SetupFlowScreen), findsNothing);
      expect(reopened.controller.role, FamilyRole.none);
    });
  });

  group('rol seçimi', () {
    testWidgets('çocuk PIN girmeden ana menüye ulaşır ve adıyla karşılanır', (
      tester,
    ) async {
      await pumpFamilyApp(tester);
      expect(find.text('Ben Ali\'yim'), findsOneWidget);

      await tapKey(tester, 'role-child');
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(find.text('Merhaba, Ali!'), findsOneWidget);

      // Oyun tarafının kendi gezinmesi eskisi gibi çalışır.
      await tapAndPump(tester, find.text('Play'));
      expect(find.byType(LevelSelectionScreen), findsOneWidget);
      await tapAndPump(tester, find.text('Back'));
      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('çocuk modunda ebeveyn ekranlarına gidilemez', (tester) async {
      await pumpFamilyApp(tester, startAs: FamilyTestStart.child);
      for (final location in [
        FamilyRoutes.parentHome,
        FamilyRoutes.parentSettings,
        FamilyRoutes.parentData,
      ]) {
        await goTo(tester, location);
        expect(find.byType(PinGateScreen), findsOneWidget, reason: location);
        expect(find.byType(ParentDashboardScreen), findsNothing);
        expect(find.byType(ParentSettingsScreen), findsNothing);
        expect(find.byType(DataManagementScreen), findsNothing);
        await tapKey(tester, 'pin-gate-back');
        await tapKey(tester, 'role-child');
      }
    });

    testWidgets('rol seçilmeden oyun ekranları açılmaz', (tester) async {
      await pumpFamilyApp(tester);
      for (final location in ['/', '/levels', '/play/level-01', '/results']) {
        await goTo(tester, location);
        expect(find.byType(RolePickerScreen), findsOneWidget, reason: location);
      }
    });

    testWidgets('ana menüden rol seçimine dönülebilir', (tester) async {
      final module = await pumpFamilyApp(
        tester,
        startAs: FamilyTestStart.child,
      );
      await tapKey(tester, 'family-switch-role');
      expect(find.byType(RolePickerScreen), findsOneWidget);
      expect(module.controller.role, FamilyRole.none);
    });
  });

  group('ebeveyn girişi', () {
    testWidgets('yanlış PIN reddedilir, doğru PIN paneli açar', (tester) async {
      final module = await pumpFamilyApp(tester);
      await _openParentArea(tester, '0000');
      expect(find.byType(PinGateScreen), findsOneWidget);
      expect(find.textContaining('PIN yanlış'), findsOneWidget);
      expect(module.controller.isParentUnlocked, isFalse);

      await enterPinOnPad(tester, familyTestPin);
      expect(find.byType(ParentDashboardScreen), findsOneWidget);
      expect(find.text('Ali — gidişat'), findsOneWidget);
    });

    testWidgets('çıkışta ebeveyn bölümü yeniden kilitlenir', (tester) async {
      final module = await pumpFamilyApp(tester);
      await _openParentArea(tester);
      expect(module.controller.isParentUnlocked, isTrue);

      await tapKey(tester, 'parent-exit');
      expect(find.byType(RolePickerScreen), findsOneWidget);
      expect(module.controller.isParentUnlocked, isFalse);

      await goTo(tester, FamilyRoutes.parentHome);
      expect(find.byType(PinGateScreen), findsOneWidget);
    });

    testWidgets('çok fazla yanlış deneme girişi geçici kilitler', (
      tester,
    ) async {
      var now = DateTime(2026, 11, 14, 10);
      await pumpFamilyApp(tester, clock: () => now);
      await tapKey(tester, 'role-parent');
      for (var attempt = 0; attempt < FamilyConfig.maxPinAttempts; attempt++) {
        await enterPinOnPad(tester, '0000');
      }
      expect(find.textContaining('Çok fazla yanlış deneme'), findsOneWidget);

      await enterPinOnPad(tester, familyTestPin);
      expect(find.byType(ParentDashboardScreen), findsNothing);

      now = now.add(FamilyConfig.pinLockDuration);
      await enterPinOnPad(tester, familyTestPin);
      expect(find.byType(ParentDashboardScreen), findsOneWidget);
    });
  });

  group('ebeveyn paneli', () {
    testWidgets('oturum yokken boş durum gösterilir', (tester) async {
      await pumpFamilyApp(tester);
      await _openParentArea(tester);
      expect(
        find.textContaining('Henüz tamamlanmış bir oturum yok'),
        findsWidgets,
      );
    });

    testWidgets('çocuğun gidişatını sekmelerde gösterir', (tester) async {
      await _seedSession('s1', DateTime(2026, 11, 10, 17, 30), 2);
      await _seedSession('s2', DateTime(2026, 11, 12, 18, 5), 4);
      await pumpFamilyApp(tester);
      await _openParentArea(tester);

      // Özet: 2 oturum, 6 doğru, 4 yanlış.
      expect(find.text('Oturum'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Son oynama: 12.11.2026 18:05'), findsOneWidget);
      expect(find.text('Öneri'), findsOneWidget);

      await tapAndPump(tester, find.text('Seviyeler'));
      expect(
        find.text('2 oturum • 6 doğru • 4 yanlış • 0 ipucu'),
        findsOneWidget,
      );
      expect(find.text('Nesneleri sayma'), findsOneWidget);
      expect(find.text('Sayı sırası (önceki / sonraki)'), findsOneWidget);

      await tapAndPump(tester, find.text('Geçmiş'));
      expect(find.text('12.11.2026 18:05'), findsOneWidget);
      expect(find.text('4/5 doğru'), findsOneWidget);
      expect(find.text('2/5 doğru'), findsOneWidget);

      await tapAndPump(tester, find.text('Gelişim'));
      expect(find.byKey(const ValueKey('accuracy-chart')), findsOneWidget);

      await tapAndPump(tester, find.text('İpuçları'));
      expect(find.text('Kısa ve sık oynayın'), findsOneWidget);
    });

    testWidgets('profil düzenlenebilir ve PIN değiştirilebilir', (
      tester,
    ) async {
      final module = await pumpFamilyApp(tester);
      await _openParentArea(tester);
      await tapKey(tester, 'parent-settings');
      expect(find.text('Takma ad: Ali\nYaş: 6'), findsOneWidget);

      await tapKey(tester, 'settings-edit-profile');
      await tester.enterText(
        find.byKey(const ValueKey('profile-nickname')),
        'Umut',
      );
      await tapKey(tester, 'age-8');
      await tapKey(tester, 'profile-save');
      expect(find.text('Takma ad: Umut\nYaş: 8'), findsOneWidget);

      await tapKey(tester, 'settings-change-pin');
      await tester.enterText(find.byKey(const ValueKey('pin-current')), '0000');
      await tester.enterText(find.byKey(const ValueKey('pin-new')), '4321');
      await tester.enterText(find.byKey(const ValueKey('pin-repeat')), '4321');
      await tapKey(tester, 'pin-save');
      // Mevcut PIN yanlış: değişmedi.
      expect(
        await module.controller.checkPin(familyTestPin),
        isA<PinAccepted>(),
      );

      await tester.enterText(
        find.byKey(const ValueKey('pin-current')),
        familyTestPin,
      );
      await tapKey(tester, 'pin-save');
      expect(await module.controller.checkPin('4321'), isA<PinAccepted>());

      await tapKey(tester, 'settings-back');
      await tapKey(tester, 'parent-exit');
      expect(find.text('Ben Umut\'um'), findsOneWidget);
    });
  });

  group('veri silme', () {
    testWidgets(
      'onay penceresi sonuçları anlatır; vazgeçince hiçbir şey olmaz',
      (tester) async {
        await _seedSession('s1', DateTime(2026, 11, 10), 3);
        await pumpFamilyApp(tester);
        await _openDataManagement(tester);

        await tapKey(tester, 'data-reset-progress');
        expect(find.text('Ne olacak?'), findsOneWidget);
        expect(find.text('Sonrasında ne yapmanız gerekecek?'), findsOneWidget);
        await tapKey(tester, 'confirm-cancel');
        expect(
          await LocalSessionResultPersistence().loadResults(),
          hasLength(1),
        );
      },
    );

    testWidgets('PIN yazmadan onaylamak deneme hakkı harcamaz', (tester) async {
      await _seedSession('s1', DateTime(2026, 11, 10), 3);
      final module = await pumpFamilyApp(tester);
      await _openDataManagement(tester);

      await tapKey(tester, 'data-reset-progress');
      for (var press = 0; press < FamilyConfig.maxPinAttempts + 2; press++) {
        await tapKey(tester, 'confirm-accept');
      }
      expect(find.textContaining('haneli PIN'), findsOneWidget);
      expect(await LocalSessionResultPersistence().loadResults(), hasLength(1));

      // Kilit oluşmadı: doğru PIN hemen kabul edilir.
      await _confirmWithPin(tester);
      expect(await LocalSessionResultPersistence().loadResults(), isEmpty);
      expect(module.controller.trashEntries, hasLength(1));
    });

    testWidgets('yanlış PIN ile silme yapılamaz', (tester) async {
      await _seedSession('s1', DateTime(2026, 11, 10), 3);
      await pumpFamilyApp(tester);
      await _openDataManagement(tester);

      await tapKey(tester, 'data-reset-progress');
      await _confirmWithPin(tester, '0000');
      expect(find.textContaining('PIN yanlış'), findsOneWidget);
      expect(await LocalSessionResultPersistence().loadResults(), hasLength(1));
    });

    testWidgets('ilerleme sıfırlanır, Silinenler\'den geri yüklenir', (
      tester,
    ) async {
      await _seedSession('s1', DateTime(2026, 11, 10), 3);
      final module = await pumpFamilyApp(tester);
      await _openDataManagement(tester);
      expect(find.byKey(const ValueKey('trash-empty')), findsOneWidget);

      await tapKey(tester, 'data-reset-progress');
      await _confirmWithPin(tester);
      expect(await LocalSessionResultPersistence().loadResults(), isEmpty);
      expect(module.controller.isSetupComplete, isTrue);
      final entry = module.controller.trashEntries.single;
      expect(find.textContaining('30 gün kaldı'), findsOneWidget);

      await tapKey(tester, 'trash-restore-${entry.id}');
      await _confirmWithPin(tester);
      expect(
        (await LocalSessionResultPersistence().loadResults()).single.sessionId,
        's1',
      );
      expect(find.byKey(const ValueKey('trash-empty')), findsOneWidget);
    });

    testWidgets('"şimdi kalıcı olarak sil" beklemeden siler', (tester) async {
      await _seedSession('s1', DateTime(2026, 11, 10), 3);
      final module = await pumpFamilyApp(tester);
      await _openDataManagement(tester);
      await tapKey(tester, 'data-reset-progress');
      await _confirmWithPin(tester);

      final entry = module.controller.trashEntries.single;
      await tapKey(tester, 'trash-purge-${entry.id}');
      await _confirmWithPin(tester);
      expect(module.controller.trashEntries, isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString(
          LocalTrashRepository.storageKey,
        ),
        isNull,
      );
    });

    testWidgets(
      'her şeyi sil: kuruluma döner, ilerleme geri alınabilir kalır',
      (tester) async {
        await _seedSession('s1', DateTime(2026, 11, 10), 3);
        final secure = InMemoryKeyValueStore();
        final module = await pumpFamilyApp(tester, secureStore: secure);
        await _openDataManagement(tester);

        await tapKey(tester, 'data-delete-everything');
        await _confirmWithPin(tester);

        expect(find.byType(SetupFlowScreen), findsOneWidget);
        expect(module.controller.isSetupComplete, isFalse);
        expect(await secure.keys(), isEmpty);
        expect((await SharedPreferences.getInstance()).getKeys(), {
          LocalTrashRepository.storageKey,
        });
        expect(module.controller.trashEntries, hasLength(1));
      },
    );

    testWidgets('her şeyi sil (kutu işaretsiz): cihazda hiçbir şey kalmaz', (
      tester,
    ) async {
      await _seedSession('s1', DateTime(2026, 11, 10), 3);
      final secure = InMemoryKeyValueStore();
      await pumpFamilyApp(tester, secureStore: secure);
      await _openDataManagement(tester);

      await tapKey(tester, 'data-delete-everything');
      await tapKey(tester, 'confirm-option');
      expect(find.textContaining('Geri alınamaz'), findsOneWidget);
      await _confirmWithPin(tester);

      expect(find.byType(SetupFlowScreen), findsOneWidget);
      expect(await secure.keys(), isEmpty);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });

    testWidgets('rızayı geri çekmek her şeyi kalıcı siler', (tester) async {
      await _seedSession('s1', DateTime(2026, 11, 10), 3);
      final secure = InMemoryKeyValueStore();
      final module = await pumpFamilyApp(tester, secureStore: secure);
      await module.controller.resetProgress();
      await _seedSession('s2', DateTime(2026, 11, 11), 3);

      await _openParentArea(tester);
      await tapKey(tester, 'parent-settings');
      await tapKey(tester, 'settings-withdraw-consent');
      await _confirmWithPin(tester);

      expect(find.byType(SetupFlowScreen), findsOneWidget);
      expect(await secure.keys(), isEmpty);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });

    testWidgets('silmeden sonra ana menüde eski oturum görünmez', (
      tester,
    ) async {
      await _seedSession('s1', DateTime(2026, 11, 10), 3);
      await pumpFamilyApp(tester);
      await tapKey(tester, 'role-child');
      expect(find.text('Last session'), findsOneWidget);

      await tapKey(tester, 'family-switch-role');
      await _openDataManagement(tester);
      await tapKey(tester, 'data-reset-progress');
      await _confirmWithPin(tester);
      await tapKey(tester, 'data-back');
      await tapKey(tester, 'settings-back');
      await tapKey(tester, 'parent-exit');
      await tapKey(tester, 'role-child');
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(find.text('Last session'), findsNothing);
    });
  });

  group('rıza metni güncellemesi', () {
    testWidgets('eski sürüm rızada yeniden onay istenir', (tester) async {
      // Eski bir metin sürümüyle verilmiş rıza kaydı.
      final secure = InMemoryKeyValueStore();
      final first = await pumpFamilyApp(tester, secureStore: secure);
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(LocalConsentRepository.storageKey)!;
      await preferences.setString(
        LocalConsentRepository.storageKey,
        stored.replaceFirst(ConsentText.version, 'eski-surum'),
      );
      expect(first.controller.isConsentCurrent, isTrue);

      final module = await pumpFamilyApp(tester, secureStore: secure);
      expect(find.byType(ConsentUpdateScreen), findsOneWidget);
      await goTo(tester, '/');
      expect(find.byType(ConsentUpdateScreen), findsOneWidget);

      // PIN'siz veya kutusuz onaylanamaz.
      await tapKey(tester, 'consent-checkbox');
      await tester.enterText(
        find.byKey(const ValueKey('consent-update-pin')),
        '0000',
      );
      await tapKey(tester, 'consent-update-approve');
      expect(module.controller.isConsentCurrent, isFalse);

      await tester.enterText(
        find.byKey(const ValueKey('consent-update-pin')),
        familyTestPin,
      );
      await tapKey(tester, 'consent-update-approve');
      expect(module.controller.isConsentCurrent, isTrue);
      expect(find.byType(RolePickerScreen), findsOneWidget);
    });
  });

  group('Android geri tuşu', () {
    Future<void> pressBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await pumpFrames(tester);
    }

    testWidgets('kurulumda bir önceki adıma döner', (tester) async {
      await pumpFamilyApp(tester, startAs: FamilyTestStart.firstLaunch);
      await tapKey(tester, 'setup-start');
      await tapKey(tester, 'consent-checkbox');
      await tapKey(tester, 'setup-consent-continue');
      expect(find.byKey(const ValueKey('setup-nickname')), findsOneWidget);

      await pressBack(tester);
      expect(find.byKey(const ValueKey('consent-checkbox')), findsOneWidget);
      await pressBack(tester);
      expect(find.byKey(const ValueKey('setup-start')), findsOneWidget);
    });

    testWidgets('PIN ekranından rol seçimine döner', (tester) async {
      await pumpFamilyApp(tester);
      await tapKey(tester, 'role-parent');
      expect(find.byType(PinGateScreen), findsOneWidget);
      await pressBack(tester);
      expect(find.byType(RolePickerScreen), findsOneWidget);
    });

    testWidgets('ebeveyn panelinden çıkar ve bölümü kilitler', (tester) async {
      final module = await pumpFamilyApp(tester);
      await _openParentArea(tester);
      await pressBack(tester);
      expect(find.byType(RolePickerScreen), findsOneWidget);
      expect(module.controller.isParentUnlocked, isFalse);
    });

    testWidgets('veri yönetiminden ayarlara, ayarlardan panele döner', (
      tester,
    ) async {
      await pumpFamilyApp(tester);
      await _openDataManagement(tester);
      await pressBack(tester);
      expect(find.byType(DataManagementScreen), findsNothing);
      expect(find.byType(ParentSettingsScreen), findsOneWidget);
      await pressBack(tester);
      expect(find.byType(ParentSettingsScreen), findsNothing);
      expect(find.byType(ParentDashboardScreen), findsOneWidget);
    });
  });

  group('geliştirici modu', () {
    testWidgets('kurulumu atlar ve şerit gösterir', (tester) async {
      final module = await pumpFamilyApp(
        tester,
        startAs: FamilyTestStart.firstLaunch,
        devMode: true,
      );
      expect(find.byType(RolePickerScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('family-dev-banner')), findsOneWidget);
      expect(module.controller.consent?.isDevSeed, isTrue);

      await _openParentArea(tester, FamilyConfig.devPin);
      expect(find.byType(ParentDashboardScreen), findsOneWidget);
    });

    testWidgets('kapalıyken şerit görünmez', (tester) async {
      await pumpFamilyApp(tester);
      expect(find.byKey(const ValueKey('family-dev-banner')), findsNothing);
    });
  });
}
