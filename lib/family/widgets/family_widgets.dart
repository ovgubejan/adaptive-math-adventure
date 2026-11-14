import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../family_config.dart';

String _two(int value) => value.toString().padLeft(2, '0');

/// 14.11.2026
String formatDate(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.day)}.${_two(local.month)}.${local.year}';
}

/// 14.11.2026 09:05
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${formatDate(local)} ${_two(local.hour)}:${_two(local.minute)}';
}

/// Geliştirici modu açıkken ekranın üstünde görünen uyarı şeridi.
class DevModeBanner extends StatelessWidget {
  const DevModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final devMode = context.select<FamilyController, bool>(
      (controller) => controller.devMode,
    );
    if (!devMode) return const SizedBox.shrink();
    return Material(
      color: Colors.deepOrange,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            'GELİŞTİRİCİ MODU — test verisi, PIN: ${FamilyConfig.devPin}',
            key: const ValueKey('family-dev-banner'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ebeveyn modülü ekranlarının ortak iskeleti: ortalanmış, genişliği
/// sınırlı, kaydırılabilir içerik.
class FamilyPage extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? leading;
  final Color? backgroundColor;
  final double maxWidth;

  const FamilyPage({
    required this.children,
    this.title,
    this.actions = const [],
    this.leading,
    this.backgroundColor,
    this.maxWidth = 560,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    return Scaffold(
      backgroundColor: backgroundColor ?? palette.backgroundSettings,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              leading: leading,
              automaticallyImplyLeading: false,
              actions: actions,
              backgroundColor: backgroundColor ?? palette.backgroundSettings,
            ),
      body: Column(
        children: [
          const DevModeBanner(),
          Expanded(
            child: SafeArea(
              top: title == null,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rakam tuşları ve girilen hane göstergesi. Fiziksel klavyeyle de çalışır
/// (Chrome'da deneme için).
class PinPad extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const PinPad({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  void _add(String digit) {
    if (!enabled || value.length >= FamilyConfig.pinLength) return;
    onChanged(value + digit);
  }

  void _removeLast() {
    if (!enabled || value.isEmpty) return;
    onChanged(value.substring(0, value.length - 1));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _removeLast();
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (character != null && RegExp(r'^[0-9]$').hasMatch(character)) {
      _add(character);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    Widget key(Widget label, {VoidCallback? onTap, Key? widgetKey}) => Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 68,
        height: 56,
        child: OutlinedButton(
          key: widgetKey,
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: palette.trueWhite,
            padding: EdgeInsets.zero,
          ),
          child: label,
        ),
      ),
    );
    Widget digit(String value) => key(
      Text(value, style: const TextStyle(fontSize: 22)),
      onTap: () => _add(value),
      widgetKey: ValueKey('pin-key-$value'),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '${value.length} / ${FamilyConfig.pinLength} hane girildi',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < FamilyConfig.pinLength; index++)
                  Container(
                    margin: const EdgeInsets.all(8),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < value.length
                          ? palette.darkPen
                          : Colors.transparent,
                      border: Border.all(color: palette.darkPen, width: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final value in row) digit(value)],
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 80),
              digit('0'),
              key(
                const Icon(Icons.backspace_outlined, semanticLabel: 'Sil'),
                onTap: _removeLast,
                widgetKey: const ValueKey('pin-key-backspace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// PIN sonucu için kullanıcıya gösterilecek metin; kabul edildiyse `null`.
String? pinResultMessage(PinCheckResult result, DateTime now) =>
    switch (result) {
      PinAccepted() => null,
      PinRejected(:final remainingAttempts) =>
        'PIN yanlış. Kalan deneme: $remainingAttempts',
      PinLocked(:final until) =>
        'Çok fazla yanlış deneme. '
            '${until.difference(now).inSeconds.clamp(1, 9999)} saniye sonra '
            'tekrar deneyin.',
    };

/// Başlık + içerik kartı.
class FamilyCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const FamilyCard({required this.children, this.title, super.key});

  @override
  Widget build(BuildContext context) => Card(
    color: Palette().trueWhite,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          ...children,
        ],
      ),
    ),
  );
}

void showFamilyMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
