import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metin tabanlı basit anahtar-değer deposu.
///
/// Ebeveyn modülünün yerel depoları doğrudan `shared_preferences` veya güvenli
/// depoya değil bu arayüze yazar. Böylece testlerde bellek içi depo,
/// uygulamada gerçek depo kullanılır.
abstract interface class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<Set<String>> keys();
}

/// Testler için bellek içi depo.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values;

  InMemoryKeyValueStore([Map<String, String>? initialValues])
    : _values = {...?initialValues};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<Set<String>> keys() async => _values.keys.toSet();
}

/// `shared_preferences` üzerinde çalışan depo. Uygulamanın diğer yerel
/// depolarıyla (oturum sonuçları, uyarlama ilerlemesi) aynı kutuyu paylaşır;
/// bu yüzden anahtar önekleri önemlidir.
class SharedPreferencesKeyValueStore implements KeyValueStore {
  final Future<SharedPreferences> _preferences;

  SharedPreferencesKeyValueStore({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async {
    final value = (await _preferences).get(key);
    return value is String ? value : null;
  }

  @override
  Future<void> write(String key, String value) async {
    final saved = await (await _preferences).setString(key, value);
    if (!saved) throw StateError('"$key" yerel depoya yazılamadı.');
  }

  @override
  Future<void> delete(String key) async {
    await (await _preferences).remove(key);
  }

  @override
  Future<Set<String>> keys() async => (await _preferences).getKeys();
}

/// İşletim sisteminin güvenli deposu (Android Keystore / iOS Keychain).
///
/// Web'de (Chrome'da deneme) tarayıcı deposunu kullanır ve Android'deki
/// kadar güvenli DEĞİLDİR; web yalnızca geliştirme ve deneme ortamıdır.
class SecureKeyValueStore implements KeyValueStore {
  final FlutterSecureStorage _storage;

  SecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<Set<String>> keys() async => (await _storage.readAll()).keys.toSet();
}
