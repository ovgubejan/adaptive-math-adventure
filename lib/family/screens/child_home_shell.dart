import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../navigation/family_navigation.dart';
import '../widgets/family_widgets.dart';

/// Çocuğun ana ekranını sarar: üstte takma adla selamlama ve rol seçimine
/// dönüş düğmesi gösterir. Sardığı ekranın kendisine dokunmaz.
class ChildHomeShell extends StatelessWidget {
  final Widget child;

  const ChildHomeShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    final nickname = context.select<FamilyController, String?>(
      (controller) => controller.profile?.nickname,
    );
    return Column(
      children: [
        const DevModeBanner(),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: child),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        if (nickname != null)
                          Expanded(
                            child: Text(
                              'Merhaba, $nickname!',
                              key: const ValueKey('family-child-greeting'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.inkFullOpacity,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            key: const ValueKey('family-switch-role'),
                            tooltip: 'Kullanıcı değiştir',
                            icon: Icon(
                              Icons.switch_account,
                              color: palette.darkPen,
                            ),
                            onPressed: () =>
                                context.go(FamilyRoutes.rolePicker),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
