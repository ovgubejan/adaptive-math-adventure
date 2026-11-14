import 'package:adaptive_math_adventure/family/data/key_value_store.dart';
import 'package:adaptive_math_adventure/family/data/local_family_repositories.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repository_contracts.dart';

/// Yerel depo uygulamalarını ortak sözleşme testlerinden geçirir.
///
/// SUNUCU EKİBİ İÇİN: Yeni depo uygulamanızı buraya ekleyin, örneğin:
///
/// ```dart
/// runChildProfileRepositoryContract(
///   'sunucu',
///   create: () => RemoteChildProfileRepository(fakeServer),
///   reset: () async => fakeServer.clear(),
/// );
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Bellek içi depo
  var memory = InMemoryKeyValueStore();
  Future<void> resetMemory() async => memory = InMemoryKeyValueStore();

  runChildProfileRepositoryContract(
    'yerel / bellek',
    create: () => LocalChildProfileRepository(memory),
    reset: resetMemory,
  );
  runConsentRepositoryContract(
    'yerel / bellek',
    create: () => LocalConsentRepository(memory),
    reset: resetMemory,
  );
  runParentPinRepositoryContract(
    'yerel / bellek',
    create: () => LocalParentPinRepository(memory),
    reset: resetMemory,
  );
  runTrashRepositoryContract(
    'yerel / bellek',
    create: () => LocalTrashRepository(memory),
    reset: resetMemory,
  );

  // shared_preferences (uygulamadaki gerçek genel depo)
  Future<void> resetPreferences() async =>
      SharedPreferences.setMockInitialValues({});

  runChildProfileRepositoryContract(
    'yerel / shared_preferences',
    create: () => LocalChildProfileRepository(SharedPreferencesKeyValueStore()),
    reset: resetPreferences,
  );
  runConsentRepositoryContract(
    'yerel / shared_preferences',
    create: () => LocalConsentRepository(SharedPreferencesKeyValueStore()),
    reset: resetPreferences,
  );
  runTrashRepositoryContract(
    'yerel / shared_preferences',
    create: () => LocalTrashRepository(SharedPreferencesKeyValueStore()),
    reset: resetPreferences,
  );

  // Güvenli depo (uygulamada PIN özetinin durduğu yer)
  runParentPinRepositoryContract(
    'yerel / güvenli depo',
    create: () => LocalParentPinRepository(SecureKeyValueStore()),
    reset: () async => FlutterSecureStorage.setMockInitialValues({}),
  );
}
