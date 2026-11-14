import 'package:adaptive_math_adventure/family/application/family_controller.dart';
import 'package:adaptive_math_adventure/family/data/key_value_store.dart';
import 'package:adaptive_math_adventure/family/family_module.dart';
import 'package:adaptive_math_adventure/family/navigation/family_navigation.dart';
import 'package:adaptive_math_adventure/navigation/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

String _join(String parent, String child) {
  if (child.startsWith('/')) return child;
  return parent.endsWith('/') ? '$parent$child' : '$parent/$child';
}

Set<String> _patterns(List<RouteBase> routes, [String parent = '']) {
  final result = <String>{};
  for (final route in routes) {
    var path = parent;
    if (route is GoRoute) {
      path = _join(parent, route.path);
      result.add(path);
    }
    result.addAll(_patterns(route.routes, path));
  }
  return result;
}

String? _redirect({
  bool isLoaded = true,
  bool isSetupComplete = true,
  bool isConsentCurrent = true,
  FamilyRole role = FamilyRole.none,
  required String path,
  String? pattern,
}) => resolveFamilyRedirect(
  isLoaded: isLoaded,
  isSetupComplete: isSetupComplete,
  isConsentCurrent: isConsentCurrent,
  role: role,
  path: path,
  routePattern: pattern ?? path,
);

void main() {
  group('rota sınıflandırması', () {
    final module = FamilyModule.local(
      preferences: InMemoryKeyValueStore(),
      secureStore: InMemoryKeyValueStore(),
      devMode: false,
    );
    final patterns = _patterns(
      createAppRouter(family: module.navigation).configuration.routes,
    );

    // YENİ ROTA EKLEDİYSENİZ VE BU TEST BAŞARISIZ OLDUYSA:
    // lib/family/navigation/family_navigation.dart içindeki
    // FamilyRoutes.access tablosuna rotanızın desenini ekleyin.
    //   - Çocuğun oynadığı ekran        -> RouteAccess.child
    //   - Ebeveyne ait bilgi gösteren   -> RouteAccess.parent, yolu /parent/...
    test('uygulamadaki her rota sınıflandırılmıştır', () {
      final unclassified = patterns.difference(
        FamilyRoutes.access.keys.toSet(),
      );
      expect(
        unclassified,
        isEmpty,
        reason:
            'Sınıflandırılmamış rota(lar): $unclassified. '
            'FamilyRoutes.access tablosuna ekleyin.',
      );
    });

    test('tabloda artık var olmayan rota kalmamıştır', () {
      expect(FamilyRoutes.access.keys.toSet().difference(patterns), isEmpty);
    });

    test('/parent altındaki her rota ebeveyn korumalıdır ve tersi', () {
      for (final entry in FamilyRoutes.access.entries) {
        final underParent =
            entry.key == '/parent' || entry.key.startsWith('/parent/');
        expect(
          entry.value == RouteAccess.parent,
          underParent,
          reason: '${entry.key} -> ${entry.value}',
        );
      }
    });

    test('oyun rotaları çocuk rotasıdır', () {
      for (final path in [
        '/',
        '/levels',
        '/demo',
        '/play/:levelId',
        '/results',
      ]) {
        expect(FamilyRoutes.access[path], RouteAccess.child, reason: path);
      }
    });
  });

  group('yönlendirme kuralları', () {
    test('durum yüklenmeden hiçbir ekran açılmaz', () {
      expect(_redirect(isLoaded: false, path: '/'), FamilyRoutes.loading);
      expect(_redirect(isLoaded: false, path: '/parent'), FamilyRoutes.loading);
      expect(_redirect(isLoaded: false, path: FamilyRoutes.loading), isNull);
    });

    test('kurulum bitmeden her yol kuruluma gider', () {
      for (final path in ['/', '/levels', '/parent', FamilyRoutes.rolePicker]) {
        expect(
          _redirect(isSetupComplete: false, path: path),
          FamilyRoutes.setup,
          reason: path,
        );
      }
      expect(
        _redirect(isSetupComplete: false, path: FamilyRoutes.setup),
        isNull,
      );
    });

    test('rıza metni eskiyse önce yeniden onay istenir', () {
      for (final role in FamilyRole.values) {
        expect(
          _redirect(isConsentCurrent: false, role: role, path: '/'),
          FamilyRoutes.consentUpdate,
        );
        expect(
          _redirect(isConsentCurrent: false, role: role, path: '/parent'),
          FamilyRoutes.consentUpdate,
        );
      }
      expect(
        _redirect(isConsentCurrent: false, path: FamilyRoutes.consentUpdate),
        isNull,
      );
    });

    test('kurulum tamamken kurulum ekranlarında kalınmaz', () {
      for (final path in [
        FamilyRoutes.loading,
        FamilyRoutes.setup,
        FamilyRoutes.consentUpdate,
      ]) {
        expect(_redirect(path: path), FamilyRoutes.rolePicker, reason: path);
      }
    });

    test('çocuk ekranları yalnızca çocuk seçilince açılır', () {
      expect(_redirect(path: '/'), FamilyRoutes.rolePicker);
      expect(
        _redirect(role: FamilyRole.parent, path: '/levels'),
        FamilyRoutes.rolePicker,
      );
      expect(_redirect(role: FamilyRole.child, path: '/'), isNull);
      expect(
        _redirect(
          role: FamilyRole.child,
          path: '/play/level-01',
          pattern: '/play/:levelId',
        ),
        isNull,
      );
    });

    test('ebeveyn ekranları PIN girilmeden açılmaz', () {
      for (final path in [
        FamilyRoutes.parentHome,
        FamilyRoutes.parentSettings,
        FamilyRoutes.parentData,
      ]) {
        expect(_redirect(path: path), FamilyRoutes.pinGate, reason: path);
        expect(
          _redirect(role: FamilyRole.child, path: path),
          FamilyRoutes.pinGate,
          reason: path,
        );
        expect(_redirect(role: FamilyRole.parent, path: path), isNull);
      }
    });

    test('geçiş ekranları her rolde açıktır', () {
      for (final role in FamilyRole.values) {
        expect(_redirect(role: role, path: FamilyRoutes.rolePicker), isNull);
        expect(_redirect(role: role, path: FamilyRoutes.pinGate), isNull);
      }
    });

    test('sınıflandırılmamış rota hiçbir rolde açılmaz', () {
      for (final role in FamilyRole.values) {
        expect(
          _redirect(role: role, path: '/yeni-ekran'),
          FamilyRoutes.rolePicker,
          reason: '$role',
        );
      }
    });

    test('bilinmeyen adres çocuk modu dışında rol seçimine döner', () {
      expect(_redirect(path: '/yok', pattern: ''), FamilyRoutes.rolePicker);
      expect(
        _redirect(role: FamilyRole.parent, path: '/yok', pattern: ''),
        FamilyRoutes.rolePicker,
      );
      expect(
        _redirect(role: FamilyRole.child, path: '/yok', pattern: ''),
        isNull,
      );
    });
  });
}
