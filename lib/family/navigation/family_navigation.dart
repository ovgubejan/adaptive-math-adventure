import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/family_controller.dart';
import '../screens/child_home_shell.dart';
import '../screens/consent_update_screen.dart';
import '../screens/data_management_screen.dart';
import '../screens/family_loading_screen.dart';
import '../screens/parent_dashboard_screen.dart';
import '../screens/parent_settings_screen.dart';
import '../screens/pin_gate_screen.dart';
import '../screens/role_picker_screen.dart';
import '../screens/setup_flow_screen.dart';

/// Bir rotaya kimin girebileceği.
enum RouteAccess {
  /// Kurulum, rol seçimi ve PIN ekranı gibi geçiş ekranları. Kişisel veri
  /// göstermezler.
  gate,

  /// Çocuğun kullandığı ekranlar. Rol seçiminde çocuk seçilmeden açılmaz.
  child,

  /// Yalnızca ebeveyn PIN'i girildikten sonra açılan ekranlar.
  parent,
}

class FamilyRoutes {
  const FamilyRoutes._();

  static const loading = '/family/loading';
  static const setup = '/family/setup';
  static const consentUpdate = '/family/consent-update';
  static const rolePicker = '/family/role';
  static const pinGate = '/family/pin';
  static const parentHome = '/parent';
  static const parentSettings = '/parent/settings';
  static const parentData = '/parent/settings/data';

  /// Uygulamadaki HER rotanın erişim sınıfı (rota deseni -> sınıf).
  ///
  /// YENİ ROTA EKLEYENLER İÇİN: `app_router.dart` içine yeni bir rota
  /// eklediğinizde desenini buraya da ekleyin. Eklemezseniz
  /// `test/family/route_access_test.dart` başarısız olur ve rota çalışma
  /// zamanında açılmaz (rol seçimine yönlendirilir).
  ///
  /// - Çocuğun oynadığı ekranlar: [RouteAccess.child]
  /// - Çocuğun ilerlemesini, ayarları veya ebeveyne ait herhangi bir bilgiyi
  ///   gösteren ekranlar: [RouteAccess.parent] ve yolu `/parent` ile başlar.
  static const Map<String, RouteAccess> access = {
    // Oyun ekibi rotaları
    '/': RouteAccess.child,
    '/levels': RouteAccess.child,
    '/demo': RouteAccess.child,
    '/play/:levelId': RouteAccess.child,
    '/results': RouteAccess.child,
    // Ebeveyn modülü rotaları
    loading: RouteAccess.gate,
    setup: RouteAccess.gate,
    consentUpdate: RouteAccess.gate,
    rolePicker: RouteAccess.gate,
    pinGate: RouteAccess.gate,
    parentHome: RouteAccess.parent,
    parentSettings: RouteAccess.parent,
    parentData: RouteAccess.parent,
  };
}

/// Verilen duruma göre gidilmesi gereken yeri döner; olduğu yerde kalabiliyorsa
/// `null`.
///
/// [path] gidilmek istenen gerçek yol, [routePattern] eşleşen rotanın deseni
/// (ör. `/play/:levelId`); hiçbir rota eşleşmediyse `null` veya boş.
String? resolveFamilyRedirect({
  required bool isLoaded,
  required bool isSetupComplete,
  required bool isConsentCurrent,
  required FamilyRole role,
  required String path,
  required String? routePattern,
}) {
  String? goTo(String target) => path == target ? null : target;

  if (!isLoaded) return goTo(FamilyRoutes.loading);
  if (!isSetupComplete) return goTo(FamilyRoutes.setup);
  if (!isConsentCurrent) return goTo(FamilyRoutes.consentUpdate);

  // Kurulum tamam: kurulum ekranlarında kalınmaz.
  if (path == FamilyRoutes.loading ||
      path == FamilyRoutes.setup ||
      path == FamilyRoutes.consentUpdate) {
    return FamilyRoutes.rolePicker;
  }

  final isUnmatched = routePattern == null || routePattern.isEmpty;
  if (isUnmatched) {
    // Bilinmeyen adres: çocuk modunda uygulamanın kendi hata ekranı
    // gösterilir, aksi hâlde rol seçimine dönülür.
    return role == FamilyRole.child ? null : FamilyRoutes.rolePicker;
  }

  switch (FamilyRoutes.access[routePattern]) {
    case RouteAccess.gate:
      return null;
    case RouteAccess.child:
      return role == FamilyRole.child ? null : FamilyRoutes.rolePicker;
    case RouteAccess.parent:
      return role == FamilyRole.parent ? null : FamilyRoutes.pinGate;
    case null:
      // Sınıflandırılmamış rota: güvenli tarafta kal ve açma.
      assert(() {
        debugPrint(
          '[family] "$routePattern" rotası FamilyRoutes.access içinde '
          'sınıflandırılmamış; açılmadı.',
        );
        return true;
      }());
      return FamilyRoutes.rolePicker;
  }
}

/// Ebeveyn modülünün yönlendiriciye (GoRouter) verdiği her şey.
class FamilyNavigation {
  final FamilyController controller;

  const FamilyNavigation(this.controller);

  /// Modül bağlanmamışsa (ör. eski testlerde) `null` döner; uygulama o
  /// durumda ebeveyn modülü yokmuş gibi çalışır.
  static FamilyNavigation? maybeOf(BuildContext context) =>
      Provider.of<FamilyNavigation?>(context, listen: false);

  /// Uygulama açılışında rol [FamilyRole.none] olduğu için açılış ekranından
  /// başlanır. Geliştirme sırasında (hot reload yönlendiriciyi yeniden
  /// kurduğunda) seçili rol korunur ve geliştirici olduğu bölümde kalır.
  String get initialLocation => switch (controller.role) {
    FamilyRole.child => '/',
    FamilyRole.parent => FamilyRoutes.parentHome,
    FamilyRole.none => FamilyRoutes.loading,
  };

  Listenable get refreshListenable => controller;

  String? redirect(BuildContext context, GoRouterState state) =>
      resolveFamilyRedirect(
        isLoaded: controller.isLoaded,
        isSetupComplete: controller.isSetupComplete,
        isConsentCurrent: controller.isConsentCurrent,
        role: controller.role,
        path: state.uri.path,
        routePattern: state.fullPath,
      );

  /// Çocuğun ana ekranını, rol seçimine dönüş düğmesiyle sarar.
  Widget wrapChildHome(Widget child) => ChildHomeShell(child: child);

  List<RouteBase> get routes => [
    GoRoute(
      path: FamilyRoutes.loading,
      builder: (context, state) => const FamilyLoadingScreen(),
    ),
    GoRoute(
      path: FamilyRoutes.setup,
      builder: (context, state) => const SetupFlowScreen(),
    ),
    GoRoute(
      path: FamilyRoutes.consentUpdate,
      builder: (context, state) => const ConsentUpdateScreen(),
    ),
    GoRoute(
      path: FamilyRoutes.rolePicker,
      builder: (context, state) => const RolePickerScreen(),
    ),
    GoRoute(
      path: FamilyRoutes.pinGate,
      builder: (context, state) => const PinGateScreen(),
    ),
    GoRoute(
      path: FamilyRoutes.parentHome,
      builder: (context, state) => const ParentDashboardScreen(),
      routes: [
        GoRoute(
          path: 'settings',
          builder: (context, state) => const ParentSettingsScreen(),
          routes: [
            GoRoute(
              path: 'data',
              builder: (context, state) => const DataManagementScreen(),
            ),
          ],
        ),
      ],
    ),
  ];
}
