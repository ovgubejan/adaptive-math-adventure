// Ebeveyn modülü açıkken uygulamayı testte çalıştırmak için yardımcılar.
//
// OYUN/SEVİYE EKİBİ İÇİN: Uygulamanın tamamını (yönlendirici + ebeveyn
// modülü) pompalayan bir test yazacaksanız `pumpFamilyApp` kullanın; kurulum
// tamamlanmış ve çocuk modu seçilmiş olarak ana menüden başlamak için
// `startAs: FamilyTestStart.child` verin. Tek bir ekranı ya da
// `createAppRouter()`'ı ebeveyn modülü OLMADAN pompalayan mevcut testleriniz
// değişiklik gerektirmez.

import 'package:adaptive_math_adventure/app.dart';
import 'package:adaptive_math_adventure/family/data/key_value_store.dart';
import 'package:adaptive_math_adventure/family/family_module.dart';
import 'package:adaptive_math_adventure/persistence/adaptive_progress_repository.dart';
import 'package:adaptive_math_adventure/persistence/local_adaptive_progress_repository.dart';
import 'package:adaptive_math_adventure/persistence/local_session_result_persistence.dart';
import 'package:adaptive_math_adventure/persistence/session_result_persistence.dart';
import 'package:adaptive_math_adventure/progress/session_history_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum FamilyTestStart {
  /// Hiç kurulum yapılmamış: uygulama kurulum ekranıyla açılır.
  firstLaunch,

  /// Kurulum tamam: uygulama rol seçimi ekranıyla açılır.
  rolePicker,

  /// Kurulum tamam ve çocuk seçilmiş: uygulama ana menüyle açılır.
  child,
}

const familyTestNickname = 'Ali';
const familyTestAge = 6;
const familyTestPin = '1234';

/// Sürekli dönen animasyonlar (maskot) olduğu için `pumpAndSettle` yerine
/// sabit sayıda kare ilerletir.
Future<void> pumpFrames(WidgetTester tester, [int frames = 8]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapAndPump(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await pumpFrames(tester);
}

Future<void> tapKey(WidgetTester tester, String key) =>
    tapAndPump(tester, find.byKey(ValueKey(key)));

/// PIN tuş takımından [pin]'i girer.
Future<void> enterPinOnPad(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tapKey(tester, 'pin-key-$digit');
  }
}

GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

Future<void> goTo(WidgetTester tester, String location) async {
  routerOf(tester).go(location);
  await pumpFrames(tester);
}

/// Uygulamayı gerçek yerel depolarla (sahte shared_preferences üzerinde) ve
/// ebeveyn modülüyle birlikte çalıştırır.
///
/// [surfaceSize] ekranın mantıksal boyutudur; küçük telefon denemek için
/// örneğin `Size(360, 640)` verin.
///
/// Çağırmadan önce `SharedPreferences.setMockInitialValues({})` ile depoyu
/// sıfırlayın. Aynı [secureStore] ile yeniden çağırmak "uygulama kapatılıp
/// açıldı" durumunu canlandırır.
Future<FamilyModule> pumpFamilyApp(
  WidgetTester tester, {
  FamilyTestStart startAs = FamilyTestStart.rolePicker,
  KeyValueStore? secureStore,
  DateTime Function()? clock,
  bool devMode = false,
  Size surfaceSize = const Size(900, 2000),
  double devicePixelRatio = 1,
}) async {
  tester.view.physicalSize = surfaceSize * devicePixelRatio;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);

  final module = FamilyModule.local(
    preferences: SharedPreferencesKeyValueStore(),
    secureStore: secureStore ?? InMemoryKeyValueStore(),
    clock: clock,
    devMode: devMode,
  );
  await module.start();
  if (startAs != FamilyTestStart.firstLaunch &&
      !module.controller.isSetupComplete) {
    await module.controller.completeSetup(
      nickname: familyTestNickname,
      age: familyTestAge,
      pin: familyTestPin,
    );
  }

  final persistence = LocalSessionResultPersistence();
  final adaptiveProgress = LocalAdaptiveProgressRepository();
  // Önceki pompalamadan kalan ağacı at: yeni yönlendirici baştan kurulsun.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SessionResultPersistence>.value(value: persistence),
        Provider<AdaptiveProgressRepository>.value(value: adaptiveProgress),
        ChangeNotifierProvider(
          create: (_) =>
              SessionHistoryController(persistence, adaptiveProgress)..load(),
        ),
        ...module.providers,
      ],
      child: const AdaptiveMathAdventureApp(),
    ),
  );
  await pumpFrames(tester);

  if (startAs == FamilyTestStart.child) {
    await tapKey(tester, 'role-child');
  }
  return module;
}
