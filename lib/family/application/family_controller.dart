import 'dart:math';

import 'package:flutter/foundation.dart';

import '../content/consent_text.dart';
import '../data/child_data_module.dart';
import '../data/family_repositories.dart';
import '../data/local_family_repositories.dart';
import '../domain/child_profile.dart';
import '../domain/consent_record.dart';
import '../domain/trash_entry.dart';
import '../family_config.dart';

/// Uygulamanın o an kimin elinde olduğu. Uygulama her açıldığında [none]
/// ile başlar ve rol seçimi ekranı gösterilir.
enum FamilyRole { none, child, parent }

sealed class PinCheckResult {
  const PinCheckResult();
}

class PinAccepted extends PinCheckResult {
  const PinAccepted();
}

class PinRejected extends PinCheckResult {
  /// Geçici kilitlenmeden önce kalan deneme hakkı.
  final int remainingAttempts;

  const PinRejected(this.remainingAttempts);
}

class PinLocked extends PinCheckResult {
  final DateTime until;

  const PinLocked(this.until);
}

/// "Her şeyi sil" sırasında cihazda kalan diğer yerel verileri temizleyen
/// işlev. [keepTrash] doğruysa Silinenler kaydı korunur.
typedef DeviceWipe = Future<void> Function({required bool keepTrash});

/// Ebeveyn modülünün tek durum sahibi: kurulum, rıza, PIN, rol ve silme
/// işlemleri buradan geçer. Ekranlar depolara doğrudan dokunmaz.
class FamilyController extends ChangeNotifier {
  final ChildProfileRepository _profiles;
  final ConsentRepository _consents;
  final ParentPinRepository _pins;
  final TrashRepository _trash;
  final ChildDataRegistry _childData;
  final DeviceWipe? _wipeDevice;
  final DateTime Function() _clock;
  final Random _random = Random();

  /// Geliştirici modu açık mı? (Yalnızca debug derlemede açılabilir.)
  final bool devMode;

  /// Şu an geçerli olan rıza metni sürümü.
  final String consentTextVersion;

  FamilyController({
    required this._profiles,
    required this._consents,
    required this._pins,
    required this._trash,
    required this._childData,
    this._wipeDevice,
    DateTime Function()? clock,
    this.devMode = false,
    this.consentTextVersion = ConsentText.version,
  }) : _clock = clock ?? DateTime.now;

  bool _isLoaded = false;
  String? _loadError;
  ChildProfile? _profile;
  ConsentRecord? _consent;
  bool _hasPin = false;
  FamilyRole _role = FamilyRole.none;
  List<TrashEntry> _trashEntries = const [];

  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;
  ChildProfile? get profile => _profile;
  ConsentRecord? get consent => _consent;
  FamilyRole get role => _role;
  List<TrashEntry> get trashEntries => List.unmodifiable(_trashEntries);
  List<ChildDataModule> get childDataModules => _childData.modules;
  DateTime get now => _clock();

  /// Kurulum tamam mı? Profil, geçerli (geri çekilmemiş) rıza ve PIN'in
  /// üçü de varsa tamamdır.
  bool get isSetupComplete =>
      _profile != null && (_consent?.isActive ?? false) && _hasPin;

  /// Kayıtlı rıza şu anki metin sürümü için mi verilmiş?
  bool get isConsentCurrent => _consent?.textVersion == consentTextVersion;

  bool get isParentUnlocked => _role == FamilyRole.parent;

  /// Depolardan durumu okur. Uygulama açılışında bir kez çağrılır.
  Future<void> load() async {
    _loadError = null;
    try {
      await _readState();
      if (devMode) await _applyDevSeed();
      await _purgeExpiredTrash();
    } catch (error) {
      _loadError = 'Kayıtlı bilgiler okunamadı: $error';
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _readState() async {
    _profile = await _profiles.load();
    _consent = await _consents.load();
    _hasPin = await _pins.hasPin();
    _trashEntries = await _trash.loadAll();
  }

  /// Geliştirici modunda kurulumu atlamak için test verisi oluşturur.
  /// Gerçek bir kurulum varsa ona dokunmaz.
  Future<void> _applyDevSeed() async {
    final now = _clock();
    if (!isSetupComplete) {
      await _consents.save(
        ConsentRecord(
          textVersion: consentTextVersion,
          grantedAt: now,
          isDevSeed: true,
        ),
      );
      await _profiles.save(
        ChildProfile(
          nickname: FamilyConfig.devNickname,
          age: FamilyConfig.devAge,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _pins.setPin(FamilyConfig.devPin);
      await _readState();
    } else if ((_consent?.isDevSeed ?? false) && !isConsentCurrent) {
      // Test rızası eski metin sürümünde kaldıysa sessizce yenilenir.
      await _consents.save(
        ConsentRecord(
          textVersion: consentTextVersion,
          grantedAt: now,
          isDevSeed: true,
        ),
      );
      _consent = await _consents.load();
    }
  }

  // ---------------------------------------------------------------------
  // Kurulum ve rıza
  // ---------------------------------------------------------------------

  /// İlk kurulumu tamamlar. Çağıran taraf ebeveynin rıza metnini onayladığını
  /// doğrulamış olmalıdır; rıza kaydı burada, veriyle birlikte oluşturulur.
  Future<void> completeSetup({
    required String nickname,
    required int age,
    required String pin,
  }) async {
    final nicknameError = ChildProfile.validateNickname(nickname);
    if (nicknameError != null) throw ArgumentError(nicknameError);
    final ageError = ChildProfile.validateAge(age);
    if (ageError != null) throw ArgumentError(ageError);
    if (!LocalParentPinRepository.isValidPin(pin)) {
      throw ArgumentError(
        'PIN ${FamilyConfig.pinLength} rakamdan oluşmalıdır.',
      );
    }
    final now = _clock();
    await _consents.save(
      ConsentRecord(textVersion: consentTextVersion, grantedAt: now),
    );
    await _profiles.save(
      ChildProfile(
        nickname: nickname.trim(),
        age: age,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _pins.setPin(pin);
    await _readState();
    _role = FamilyRole.none;
    notifyListeners();
  }

  /// Metin sürümü değiştiğinde ebeveynin yeni metni onayladığını kaydeder.
  /// Çağıran taraf önce PIN'i doğrulamış olmalıdır.
  Future<void> renewConsent() async {
    await _consents.save(
      ConsentRecord(textVersion: consentTextVersion, grantedAt: _clock()),
    );
    _consent = await _consents.load();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Rol ve PIN
  // ---------------------------------------------------------------------

  void enterChildMode() {
    if (!isSetupComplete || !isConsentCurrent) return;
    _role = FamilyRole.child;
    notifyListeners();
  }

  /// Rol seçimi ekranına döner; ebeveyn bölümü yeniden kilitlenir.
  void returnToRolePicker() {
    if (_role == FamilyRole.none) return;
    _role = FamilyRole.none;
    notifyListeners();
  }

  /// PIN'i doğrular ve yanlış deneme sayacını yönetir. Rolü değiştirmez.
  Future<PinCheckResult> checkPin(String pin) async {
    final now = _clock();
    var attempts = await _pins.loadAttemptState();
    final lockedUntil = attempts.lockedUntil;
    if (lockedUntil != null) {
      if (now.isBefore(lockedUntil)) return PinLocked(lockedUntil);
      attempts = PinAttemptState.none;
    }
    if (await _pins.matches(pin)) {
      await _pins.saveAttemptState(PinAttemptState.none);
      return const PinAccepted();
    }
    final failed = attempts.failedAttempts + 1;
    if (failed >= FamilyConfig.maxPinAttempts) {
      final until = now.add(FamilyConfig.pinLockDuration);
      await _pins.saveAttemptState(PinAttemptState(lockedUntil: until));
      return PinLocked(until);
    }
    await _pins.saveAttemptState(PinAttemptState(failedAttempts: failed));
    return PinRejected(FamilyConfig.maxPinAttempts - failed);
  }

  /// PIN doğruysa ebeveyn bölümünün kilidini açar.
  Future<PinCheckResult> unlockParent(String pin) async {
    final result = await checkPin(pin);
    if (result is PinAccepted && isSetupComplete) {
      _role = FamilyRole.parent;
      notifyListeners();
    }
    return result;
  }

  /// PIN'i değiştirir. Çağıran taraf önce mevcut PIN'i doğrulamış olmalıdır.
  Future<void> changePin(String newPin) async {
    await _pins.setPin(newPin);
    _hasPin = await _pins.hasPin();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String nickname,
    required int age,
  }) async {
    final current = _profile;
    if (current == null) throw StateError('Profil bulunamadı.');
    final nicknameError = ChildProfile.validateNickname(nickname);
    if (nicknameError != null) throw ArgumentError(nicknameError);
    final ageError = ChildProfile.validateAge(age);
    if (ageError != null) throw ArgumentError(ageError);
    await _profiles.save(
      current.copyWith(
        nickname: nickname.trim(),
        age: age,
        updatedAt: _clock(),
      ),
    );
    _profile = await _profiles.load();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Silme, Silinenler ve geri yükleme
  // ---------------------------------------------------------------------

  /// Çocuğun ilerleme verisini siler ve Silinenler'e taşır. Profil, rıza ve
  /// PIN kalır.
  Future<void> resetProgress() async {
    await _moveProgressToTrash(TrashReason.progressReset);
    await _childData.clearAll();
    _trashEntries = await _trash.loadAll();
    notifyListeners();
  }

  /// Profil, rıza, PIN ve ilerleme dahil her şeyi siler; uygulama ilk
  /// kuruluma döner.
  ///
  /// [keepProgressInTrash] doğruysa ilerleme verisi Silinenler'de
  /// [FamilyConfig.trashRetention] boyunca geri alınabilir kalır; yanlışsa
  /// Silinenler dahil her şey hemen ve kalıcı olarak silinir.
  Future<void> deleteEverything({required bool keepProgressInTrash}) async {
    if (keepProgressInTrash) {
      await _moveProgressToTrash(TrashReason.fullDeletion);
    } else {
      await _trash.clear();
    }
    await _childData.clearAll();
    await _profiles.delete();
    await _consents.delete();
    await _pins.clear();
    await _wipeDevice?.call(keepTrash: keepProgressInTrash);
    await _readState();
    _role = FamilyRole.none;
    notifyListeners();
  }

  /// Rızayı geri çeker: Silinenler dahil tüm veri hemen ve kalıcı olarak
  /// silinir. Rıza olmadan veri saklanmaz.
  Future<void> withdrawConsent() =>
      deleteEverything(keepProgressInTrash: false);

  /// Silinenlerdeki bir kaydı geri yükler. O anki ilerleme varsa kaybolmaz;
  /// Silinenler'e taşınır.
  Future<void> restoreFromTrash(String entryId) async {
    final entry = _trashEntries.where((item) => item.id == entryId).firstOrNull;
    if (entry == null) throw StateError('Silinen kayıt bulunamadı.');
    if (entry.isExpired(_clock())) {
      await _purgeExpiredTrash();
      notifyListeners();
      throw StateError('Bu kaydın saklama süresi dolmuş.');
    }
    await _moveProgressToTrash(TrashReason.replacedByRestore);
    await _childData.clearAll();
    await _childData.restoreAll(entry.snapshots);
    await _trash.remove(entry.id);
    _trashEntries = await _trash.loadAll();
    notifyListeners();
  }

  /// Silinenlerdeki tek bir kaydı beklemeden kalıcı olarak siler.
  Future<void> purgeFromTrash(String entryId) async {
    await _trash.remove(entryId);
    _trashEntries = await _trash.loadAll();
    notifyListeners();
  }

  /// Silinenlerdeki tüm kayıtları beklemeden kalıcı olarak siler.
  Future<void> emptyTrash() async {
    await _trash.clear();
    _trashEntries = await _trash.loadAll();
    notifyListeners();
  }

  /// Saklama süresi dolan kayıtları kalıcı olarak siler. Uygulama açılışında
  /// ve Silinenler ekranı açıldığında çağrılır.
  Future<void> purgeExpiredTrash() async {
    final before = _trashEntries.length;
    await _purgeExpiredTrash();
    if (_trashEntries.length != before) notifyListeners();
  }

  Future<void> _purgeExpiredTrash() async {
    final now = _clock();
    final entries = await _trash.loadAll();
    for (final entry in entries.where((item) => item.isExpired(now))) {
      await _trash.remove(entry.id);
    }
    _trashEntries = await _trash.loadAll();
  }

  Future<void> _moveProgressToTrash(TrashReason reason) async {
    final snapshots = await _childData.snapshotAll();
    if (snapshots.isEmpty) return;
    final now = _clock();
    await _trash.add(
      TrashEntry(
        id: '${now.microsecondsSinceEpoch}-${_random.nextInt(0x7fffffff)}',
        deletedAt: now,
        reason: reason,
        childNickname: _profile?.nickname,
        snapshots: snapshots,
      ),
    );
  }
}
