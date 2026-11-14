import '../domain/child_profile.dart';
import '../domain/consent_record.dart';
import '../domain/trash_entry.dart';

/// Ebeveyn modülünün depo arayüzleri.
///
/// SUNUCU EKİBİ İÇİN: Bu arayüzlerin imzaları sözleşmedir. Sunucu desteği
/// eklenirken imzalar değiştirilmez; aynı arayüzü uygulayan yeni bir sınıf
/// yazılır ve `test/family/repository_contracts.dart` içindeki ortak testler
/// o sınıf için de çalıştırılır. Ayrıntı: docs/ebeveyn-modulu/.

abstract interface class ChildProfileRepository {
  /// Kayıt yoksa veya okunamayacak kadar bozuksa `null`.
  Future<ChildProfile?> load();

  Future<void> save(ChildProfile profile);

  Future<void> delete();
}

abstract interface class ConsentRepository {
  Future<ConsentRecord?> load();

  Future<void> save(ConsentRecord record);

  Future<void> delete();
}

/// Art arda yanlış PIN denemelerinin durumu.
class PinAttemptState {
  final int failedAttempts;
  final DateTime? lockedUntil;

  const PinAttemptState({this.failedAttempts = 0, this.lockedUntil});

  static const none = PinAttemptState();
}

abstract interface class ParentPinRepository {
  Future<bool> hasPin();

  /// PIN'i saklar. PIN'in kendisi asla düz metin olarak saklanmaz.
  Future<void> setPin(String pin);

  /// Verilen PIN kayıtlı PIN ile aynı mı?
  Future<bool> matches(String pin);

  Future<PinAttemptState> loadAttemptState();

  Future<void> saveAttemptState(PinAttemptState state);

  /// PIN'i ve deneme durumunu siler.
  Future<void> clear();
}

abstract interface class TrashRepository {
  /// En yeni silinen en başta olacak şekilde tüm kayıtlar.
  Future<List<TrashEntry>> loadAll();

  Future<void> add(TrashEntry entry);

  Future<void> remove(String id);

  Future<void> clear();
}
