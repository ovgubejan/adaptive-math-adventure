/// Ebeveyn modülünün tek yerden yönetilen sabitleri.
///
/// Yaş aralığı, PIN kuralları ve saklama süresi gibi değerler kodun başka
/// yerlerine yazılmaz; değişmesi gerekirse yalnızca burası değiştirilir.
class FamilyConfig {
  const FamilyConfig._();

  /// Uygulamanın hedeflediği yaş aralığı (dahil).
  static const int minChildAge = 4;
  static const int maxChildAge = 8;

  static const int maxNicknameLength = 20;

  /// Ebeveyn PIN'i tam olarak bu kadar rakamdan oluşur.
  static const int pinLength = 4;

  /// Bu kadar art arda yanlış PIN denemesinden sonra giriş geçici kilitlenir.
  static const int maxPinAttempts = 5;
  static const Duration pinLockDuration = Duration(seconds: 30);

  /// Silinen ilerleme verisinin "Silinenler" içinde tutulduğu süre.
  static const int trashRetentionDays = 30;
  static const Duration trashRetention = Duration(days: trashRetentionDays);

  /// Modülün yerel depolama anahtarlarının öneki. Başka modüller bu öneki
  /// kullanmamalıdır.
  static const String storagePrefix = 'family_';

  /// Modülün kayıt biçimi sürümü. Kayıt alanları uyumsuz biçimde değişirse
  /// artırılır ve okuma tarafına geçiş kodu eklenir.
  static const int schemaVersion = 1;

  /// `flutter run --dart-define=FAMILY_DEV_MODE=true` ile açılır.
  /// Yalnızca debug derlemede etkilidir (bkz. `FamilyModule`).
  static const bool devModeRequested = bool.fromEnvironment('FAMILY_DEV_MODE');

  /// Geliştirici modunda oluşturulan test profilinin değerleri.
  static const String devNickname = 'Test Çocuk';
  static const int devAge = 6;
  static const String devPin = '0000';
}
