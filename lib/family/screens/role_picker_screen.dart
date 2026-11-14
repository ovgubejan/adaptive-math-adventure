import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../presentation/mascot/mascot_state.dart';
import '../../presentation/mascot/mascot_widget.dart';
import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../navigation/family_navigation.dart';
import '../widgets/family_widgets.dart';

/// "Ben Ali'yim", "Ben Ahmet'im", "Ben Umut'um" — takma ada Türkçe ses
/// uyumuna göre ek getirir.
String iAmLabel(String nickname) {
  const vowelToSuffix = {
    'a': 'ı', 'ı': 'ı', 'A': 'ı', 'I': 'ı', //
    'e': 'i', 'i': 'i', 'E': 'i', 'İ': 'i',
    'o': 'u', 'u': 'u', 'O': 'u', 'U': 'u',
    'ö': 'ü', 'ü': 'ü', 'Ö': 'ü', 'Ü': 'ü',
  };
  final name = nickname.trim();
  if (name.isEmpty) return 'Ben çocuğum';
  final characters = name.runes.map(String.fromCharCode).toList();
  var suffixVowel = 'i';
  for (final character in characters.reversed) {
    final match = vowelToSuffix[character];
    if (match != null) {
      suffixVowel = match;
      break;
    }
  }
  final endsWithVowel = vowelToSuffix.containsKey(characters.last);
  return 'Ben $name\'${endsWithVowel ? 'y' : ''}${suffixVowel}m';
}

/// Uygulama her açıldığında gösterilen ekran: çocuk mu, ebeveyn mi?
class RolePickerScreen extends StatefulWidget {
  const RolePickerScreen({super.key});

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends State<RolePickerScreen> {
  @override
  void initState() {
    super.initState();
    // Bu ekrana her gelindiğinde ebeveyn bölümü yeniden kilitlenir.
    final controller = context.read<FamilyController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.returnToRolePicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    final controller = context.watch<FamilyController>();
    final nickname = controller.profile?.nickname ?? '';
    return FamilyPage(
      backgroundColor: palette.backgroundMain,
      maxWidth: 420,
      children: [
        const SizedBox(height: 8),
        const Center(child: MascotWidget(state: MascotState.idle, size: 140)),
        const SizedBox(height: 8),
        Text(
          'Matematik Macerası',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.darkPen,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 28),
        // Çocuk düğmesi büyük ve renkli, ebeveyn düğmesi küçük ve sade:
        // okuma bilmeyen çocuk da kendi düğmesini kolayca bulsun.
        FilledButton.icon(
          key: const ValueKey('role-child'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(84),
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            controller.enterChildMode();
            context.go('/');
          },
          icon: const Icon(Icons.play_circle_fill, size: 40),
          label: Text(iAmLabel(nickname)),
        ),
        const SizedBox(height: 28),
        Center(
          child: OutlinedButton.icon(
            key: const ValueKey('role-parent'),
            onPressed: () => context.go(FamilyRoutes.pinGate),
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('Ben ebeveynim'),
          ),
        ),
      ],
    );
  }
}
