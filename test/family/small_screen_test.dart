import 'dart:io';

import 'package:adaptive_math_adventure/app.dart';
import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/family/screens/data_management_screen.dart';
import 'package:adaptive_math_adventure/family/screens/parent_dashboard_screen.dart';
import 'package:adaptive_math_adventure/family/screens/parent_settings_screen.dart';
import 'package:adaptive_math_adventure/family/screens/role_picker_screen.dart';
import 'package:adaptive_math_adventure/persistence/local_session_result_persistence.dart';
import 'package:adaptive_math_adventure/screens/main_menu_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'family_test_harness.dart';

/// Küçük bir telefon ekranı (mantıksal piksel).
const _smallPhone = Size(360, 640);

/// `--dart-define=FAMILY_SCREENSHOT_DIR=<klasör>` verilirse her adımın ekran
/// görüntüsü o klasöre yazılır (elle gözden geçirmek için). Verilmezse test
/// yalnızca taşma (overflow) ve hata olmadığını sınar.
const _screenshotDir = String.fromEnvironment('FAMILY_SCREENSHOT_DIR');

Future<void> _shot(WidgetTester tester, String name) async {
  if (_screenshotDir.isEmpty) return;
  await expectLater(
    find.byType(AdaptiveMathAdventureApp),
    matchesGoldenFile(Uri.file('$_screenshotDir/$name.png')),
  );
}

Future<void> _seedSessions() async {
  for (var session = 0; session < 6; session++) {
    final completedAt = DateTime(2026, 11, 3 + session, 17, 30);
    await LocalSessionResultPersistence().saveResult(
      SessionResult(
        sessionId: 's$session',
        levelId: 'level-01',
        startedAt: completedAt.subtract(const Duration(minutes: 4)),
        completedAt: completedAt,
        evidence: [
          for (var index = 0; index < 5; index++)
            QuestionEvidence(
              questionId: 's$session-q$index',
              skillTag: const [
                'counting-sets',
                'number-sequence',
                'one-more-less',
                'missing-quantity',
                'counting-small-sets',
              ][index],
              difficulty: 1,
              attempts: [
                AnswerAttempt(
                  answer: 1,
                  isCorrect: index <= session ~/ 2 + 1,
                  responseTime: const Duration(seconds: 4),
                  hintUsed: index == 4,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    if (_screenshotDir.isEmpty) return;
    // Ekran görüntülerinde yazıların okunabilmesi için gerçek yazı tipleri.
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    Future<void> load(String family, List<String> paths) async {
      final loader = FontLoader(family);
      for (final path in paths) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final bytes = await file.readAsBytes();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    }

    final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
    await load('Roboto', [
      '$fonts/roboto-regular.ttf',
      '$fonts/roboto-bold.ttf',
      '$fonts/roboto-black.ttf',
      '$fonts/roboto-italic.ttf',
    ]);
    await load('MaterialIcons', ['$fonts/materialicons-regular.otf']);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Bir ekranda taşma olursa Flutter bunu test hatası olarak bildirir; bu
  // yüzden testin hatasız bitmesi "küçük telefonda taşma yok" demektir.
  testWidgets('kurulum akışı küçük telefon ekranına sığar', (tester) async {
    await pumpFamilyApp(
      tester,
      startAs: FamilyTestStart.firstLaunch,
      surfaceSize: _smallPhone,
      devicePixelRatio: 2,
    );
    await _shot(tester, '01-karsilama');
    await tapKey(tester, 'setup-start');
    await tapKey(tester, 'consent-checkbox');
    await _shot(tester, '02-riza');
    await tapKey(tester, 'consent-read-full');
    await _shot(tester, '03-tam-metin');
    await tapKey(tester, 'legal-close');
    await tapKey(tester, 'setup-consent-continue');
    await tester.enterText(find.byKey(const ValueKey('setup-nickname')), 'Ali');
    await tapKey(tester, 'age-6');
    await _shot(tester, '04-cocuk-profili');
    await tapKey(tester, 'setup-child-continue');
    await enterPinOnPad(tester, '12');
    await _shot(tester, '05-pin');
    await enterPinOnPad(tester, '34');
    await enterPinOnPad(tester, familyTestPin);
    expect(find.byType(RolePickerScreen), findsOneWidget);
    await _shot(tester, '06-rol-secimi');
  });

  testWidgets('çocuk ve ebeveyn ekranları küçük telefon ekranına sığar', (
    tester,
  ) async {
    await _seedSessions();
    await pumpFamilyApp(tester, surfaceSize: _smallPhone, devicePixelRatio: 2);

    await tapKey(tester, 'role-child');
    expect(find.byType(MainMenuScreen), findsOneWidget);
    await _shot(tester, '07-cocuk-ana-ekran');
    await tapKey(tester, 'family-switch-role');

    await tapKey(tester, 'role-parent');
    await enterPinOnPad(tester, '00');
    await _shot(tester, '08-pin-kapisi');
    await enterPinOnPad(tester, '00');
    await _shot(tester, '09-pin-yanlis');
    await enterPinOnPad(tester, familyTestPin);
    expect(find.byType(ParentDashboardScreen), findsOneWidget);
    await _shot(tester, '10-panel-ozet');

    for (final (index, tab) in const [
      'Seviyeler',
      'Geçmiş',
      'Gelişim',
      'İpuçları',
    ].indexed) {
      await tapAndPump(tester, find.text(tab));
      await _shot(tester, '1${index + 1}-panel-${tab.toLowerCase()}');
    }

    await tapKey(tester, 'parent-settings');
    expect(find.byType(ParentSettingsScreen), findsOneWidget);
    await _shot(tester, '15-ayarlar');
    await tapKey(tester, 'settings-edit-profile');
    await _shot(tester, '16-profil-duzenle');
    await tapAndPump(tester, find.text('Vazgeç'));
    await tapKey(tester, 'settings-change-pin');
    await _shot(tester, '17-pin-degistir');
    await tapAndPump(tester, find.text('Vazgeç'));
    await tapKey(tester, 'settings-withdraw-consent');
    await _shot(tester, '18-rizayi-geri-cek');
    await tapKey(tester, 'confirm-cancel');

    await tapKey(tester, 'settings-open-data');
    expect(find.byType(DataManagementScreen), findsOneWidget);
    await _shot(tester, '19-veri-yonetimi');
    await tapKey(tester, 'data-delete-everything');
    await _shot(tester, '20-her-seyi-sil-onay');
    await tapKey(tester, 'confirm-cancel');
    await tapKey(tester, 'data-reset-progress');
    await _shot(tester, '21-sifirla-onay');
    await tester.enterText(
      find.byKey(const ValueKey('confirm-pin')),
      familyTestPin,
    );
    await tapKey(tester, 'confirm-accept');
    await _shot(tester, '22-silinenler');
  });
}
