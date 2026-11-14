import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'application/family_controller.dart';
import 'data/child_data_module.dart';
import 'data/key_value_store.dart';
import 'data/local_family_repositories.dart';
import 'family_config.dart';
import 'navigation/family_navigation.dart';

/// Ebeveyn modülünün uygulamaya bağlandığı TEK nokta.
///
/// `main.dart` yalnızca şunu yapar:
///
/// ```dart
/// final family = FamilyModule.local();
/// ... providers: [ ...diğerleri, ...family.providers ]
/// ```
///
/// Modülün geri kalanı `lib/family/` altındadır. Ayrıntı ve kurallar:
/// docs/ebeveyn-modulu/EBEVEYN_MODULU.md
class FamilyModule {
  final FamilyController controller;
  final FamilyNavigation navigation;
  final KeyValueStore _preferences;
  final ChildDataRegistry _registry;

  FamilyModule._(this.controller, this._preferences, this._registry)
    : navigation = FamilyNavigation(controller);

  /// Geliştirici modu yalnızca debug derlemede ve
  /// `--dart-define=FAMILY_DEV_MODE=true` verildiğinde açılır. Yayın
  /// (release) derlemesinde bu ifade derleme zamanında `false` olur.
  static bool get devModeEnabled => kDebugMode && FamilyConfig.devModeRequested;

  /// Çocuğa ait veri tutan yerel modüllerin listesi.
  ///
  /// OYUN/SEVİYE EKİBİ İÇİN: Çocuk hakkında yeni bir yerel veri saklamaya
  /// başladığınızda buraya bir satır ekleyin. `test/family/` altındaki
  /// depolama denetimi testi, kayıtsız anahtarları yakalamak için vardır.
  static List<ChildDataModule> defaultChildDataModules(KeyValueStore store) => [
    StorageKeysDataModule(
      id: 'sessionResults',
      displayName: 'Oturum geçmişi',
      // LocalSessionResultPersistence'ın depolama anahtarı.
      keys: {'adaptiveMathAdventure.sessionResults.v1'},
      store: store,
    ),
    StorageKeysDataModule(
      id: 'adaptiveProgress',
      displayName: 'Öğrenme ilerlemesi',
      // LocalAdaptiveProgressRepository'nin depolama anahtarı.
      keys: {'adaptiveMathAdventure.learningProgress.v1'},
      store: store,
    ),
  ];

  /// Cihazda yerel depolarla çalışan modül.
  ///
  /// [preferences] genel yerel depo (shared_preferences), [secureStore] PIN
  /// özeti için güvenli depodur. Testler bellek içi depo verebilir.
  factory FamilyModule.local({
    KeyValueStore? preferences,
    KeyValueStore? secureStore,
    List<ChildDataModule>? childDataModules,
    DateTime Function()? clock,
    bool? devMode,
  }) {
    final prefs = preferences ?? SharedPreferencesKeyValueStore();
    final secure = secureStore ?? SecureKeyValueStore();
    final registry = ChildDataRegistry(
      childDataModules ?? defaultChildDataModules(prefs),
    );
    final controller = FamilyController(
      profiles: LocalChildProfileRepository(prefs),
      consents: LocalConsentRepository(prefs),
      pins: LocalParentPinRepository(secure),
      trash: LocalTrashRepository(prefs),
      childData: registry,
      wipeDevice: ({required bool keepTrash}) =>
          _wipeLocalStorage(prefs, secure, keepTrash: keepTrash),
      clock: clock,
      devMode: devMode ?? devModeEnabled,
    );
    return FamilyModule._(controller, prefs, registry);
  }

  /// `MultiProvider` listesine eklenecek sağlayıcılar. Denetleyiciyi
  /// oluşturur ve kayıtlı durumu yüklemeye başlar.
  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<FamilyController>.value(value: controller),
    Provider<FamilyNavigation>.value(value: navigation),
  ];

  /// Kayıtlı durumu yükler. `main.dart` bunu beklemeden çağırır; yükleme
  /// bitene kadar yönlendirici açılış ekranını gösterir.
  Future<void> start() async {
    await controller.load();
    if (!kDebugMode) return;
    try {
      final unknown = await unregisteredStorageKeys(_preferences, _registry);
      if (unknown.isNotEmpty) {
        debugPrint(
          '[family] UYARI: Kayıtlı olmayan yerel depolama anahtarları: '
          '$unknown. Çocuğa ait veri içeriyorlarsa '
          'FamilyModule.defaultChildDataModules listesine ekleyin '
          '(docs/ebeveyn-modulu/OYUN_EKIBI_KILAVUZU.md).',
        );
      }
    } catch (error) {
      debugPrint('[family] Depolama denetimi yapılamadı: $error');
    }
  }

  /// Ne ebeveyn modülüne ne de kayıtlı bir veri modülüne ait olan yerel
  /// depolama anahtarları. Boş olması beklenir.
  static Future<Set<String>> unregisteredStorageKeys(
    KeyValueStore preferences,
    ChildDataRegistry registry,
  ) async {
    final owned = registry.ownedStorageKeys;
    return {
      for (final key in await preferences.keys())
        if (!key.startsWith(FamilyConfig.storagePrefix) && !owned.contains(key))
          key,
    };
  }

  /// "Her şeyi sil": uygulamanın yerel deposunda kalan HER anahtarı siler
  /// (kayıtsız modüllerin verisi dahil). Yalnızca [keepTrash] doğruysa
  /// Silinenler kaydı korunur.
  static Future<void> _wipeLocalStorage(
    KeyValueStore preferences,
    KeyValueStore secure, {
    required bool keepTrash,
  }) async {
    for (final key in await preferences.keys()) {
      if (keepTrash && key == LocalTrashRepository.storageKey) continue;
      await preferences.delete(key);
    }
    for (final key in await secure.keys()) {
      if (key.startsWith(FamilyConfig.storagePrefix)) await secure.delete(key);
    }
  }
}
