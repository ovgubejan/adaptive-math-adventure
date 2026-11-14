import 'dart:convert';

import 'key_value_store.dart';

/// Çocuğa ait veri tutan her modülün uygulaması gereken arayüz.
///
/// OYUN/SEVİYE EKİBİ İÇİN: Çocuk hakkında yeni bir veri saklamaya
/// başlarsanız (yeni oyunun skoru, rozetler, tercihleri vb.) o veriyi bir
/// [ChildDataModule] olarak `FamilyModule.defaultChildDataModules` listesine
/// ekleyin. Eklemezseniz ebeveyn "ilerlemeyi sıfırla" dediğinde veriniz
/// silinmez ve "Silinenler"den geri yüklenemez. Yerel `shared_preferences`
/// anahtarları için hazır [StorageKeysDataModule] tek satırla yeterlidir.
abstract interface class ChildDataModule {
  /// Kalıcı ve benzersiz kimlik. Silinenler kayıtlarında saklanır; sonradan
  /// DEĞİŞTİRMEYİN.
  String get id;

  /// Ebeveyne gösterilecek kısa ad.
  String get displayName;

  /// Modülün yerel depoda sahip olduğu anahtarlar (yoksa boş küme).
  /// Depolama denetimi bunu kullanır.
  Set<String> get ownedStorageKeys;

  /// Modülün çocuğa ait tüm verisinin anlık görüntüsü; veri yoksa `null`.
  Future<String?> exportSnapshot();

  /// Modülün çocuğa ait tüm verisini siler.
  Future<void> clear();

  /// [exportSnapshot] ile alınmış bir anlık görüntüyü geri yükler.
  Future<void> restoreSnapshot(String snapshot);
}

/// Belirli yerel depo anahtarlarını olduğu gibi yedekleyip silen modül.
///
/// Verinin iç yapısını bilmez; bu yüzden veri şeması değişse de çalışmaya
/// devam eder.
class StorageKeysDataModule implements ChildDataModule {
  @override
  final String id;

  @override
  final String displayName;

  @override
  final Set<String> ownedStorageKeys;

  final KeyValueStore store;

  StorageKeysDataModule({
    required this.id,
    required this.displayName,
    required Set<String> keys,
    required this.store,
  }) : ownedStorageKeys = Set.unmodifiable(keys);

  @override
  Future<String?> exportSnapshot() async {
    final values = <String, String>{};
    for (final key in ownedStorageKeys) {
      final value = await store.read(key);
      if (value != null) values[key] = value;
    }
    return values.isEmpty ? null : jsonEncode(values);
  }

  @override
  Future<void> clear() async {
    for (final key in ownedStorageKeys) {
      await store.delete(key);
    }
  }

  @override
  Future<void> restoreSnapshot(String snapshot) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(snapshot);
    } on FormatException {
      return;
    }
    if (decoded is! Map) return;
    for (final entry in decoded.entries) {
      final key = entry.key;
      final value = entry.value;
      // Yalnızca bu modülün hâlâ sahip olduğu anahtarlar geri yazılır.
      if (key is String && value is String && ownedStorageKeys.contains(key)) {
        await store.write(key, value);
      }
    }
  }
}

/// Kayıtlı tüm [ChildDataModule]'leri birlikte yöneten liste.
class ChildDataRegistry {
  final List<ChildDataModule> modules;

  ChildDataRegistry(List<ChildDataModule> modules)
    : modules = List.unmodifiable(modules) {
    final ids = <String>{};
    for (final module in modules) {
      if (!ids.add(module.id)) {
        throw ArgumentError('Veri modülü kimliği tekrar ediyor: ${module.id}');
      }
    }
  }

  Set<String> get ownedStorageKeys => {
    for (final module in modules) ...module.ownedStorageKeys,
  };

  /// Verisi olan modüllerin anlık görüntüleri (modül kimliği -> görüntü).
  Future<Map<String, String>> snapshotAll() async {
    final snapshots = <String, String>{};
    for (final module in modules) {
      final snapshot = await module.exportSnapshot();
      if (snapshot != null) snapshots[module.id] = snapshot;
    }
    return snapshots;
  }

  Future<void> clearAll() async {
    for (final module in modules) {
      await module.clear();
    }
  }

  /// Kimliği artık kayıtlı olmayan modüllerin görüntüleri yok sayılır.
  Future<void> restoreAll(Map<String, String> snapshots) async {
    for (final module in modules) {
      final snapshot = snapshots[module.id];
      if (snapshot != null) await module.restoreSnapshot(snapshot);
    }
  }
}
