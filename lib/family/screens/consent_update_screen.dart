import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../progress/session_history_controller.dart';
import '../application/family_controller.dart';
import '../widgets/destructive_confirmation.dart';
import '../widgets/family_widgets.dart';
import 'legal_text_screen.dart';

/// Aydınlatma metninin sürümü değiştiğinde gösterilir. Ebeveyn yeni metni
/// PIN'iyle onaylayana kadar uygulamanın geri kalanı açılmaz.
class ConsentUpdateScreen extends StatefulWidget {
  const ConsentUpdateScreen({super.key});

  @override
  State<ConsentUpdateScreen> createState() => _ConsentUpdateScreenState();
}

class _ConsentUpdateScreenState extends State<ConsentUpdateScreen> {
  final _pinController = TextEditingController();
  bool _accepted = false;
  bool _busy = false;
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final controller = context.read<FamilyController>();
    setState(() {
      _busy = true;
      _pinError = null;
    });
    try {
      final result = await controller.checkPin(_pinController.text);
      if (result is PinAccepted) {
        await controller.renewConsent();
        // Onay kaydedilince yönlendirici rol seçimi ekranını açar.
        return;
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _pinController.clear();
        _pinError = pinResultMessage(result, controller.now);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _pinError = 'Onay kaydedilemedi: $error';
      });
    }
  }

  Future<void> _decline() async {
    final controller = context.read<FamilyController>();
    final history = context.read<SessionHistoryController?>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: 'Onay vermiyorum',
      consequences: const [
        'Çocuğunuzun profili ve tüm oyun ilerlemesi bu cihazdan hemen ve '
            'kalıcı olarak silinir.',
        '"Silinenler" içindeki kayıtlar da silinir; geri alınamaz.',
      ],
      afterwards: const [
        'Uygulamayı kullanmaya devam etmek için kurulumu baştan yapmanız '
            've yeni metni onaylamanız gerekir.',
      ],
      confirmLabel: 'Verileri sil',
    );
    if (confirmed == null) return;
    try {
      await controller.withdrawConsent();
      await history?.load();
    } catch (error) {
      if (mounted) showFamilyMessage(context, 'Silinemedi: $error');
    }
  }

  @override
  Widget build(BuildContext context) => FamilyPage(
    children: [
      const Text(
        'Aydınlatma metni güncellendi',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Uygulamanın işlediği veriler veya işleme biçimi değişti. Devam '
        'etmeden önce bir ebeveynin yeni metni okuyup onaylaması gerekiyor.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      ConsentForm(
        accepted: _accepted,
        onAcceptedChanged: (value) => setState(() => _accepted = value),
      ),
      const SizedBox(height: 8),
      PinTextField(
        key: const ValueKey('consent-update-pin'),
        controller: _pinController,
        label: 'Ebeveyn PIN\'i',
        errorText: _pinError,
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: const ValueKey('consent-update-approve'),
        onPressed: _accepted && !_busy ? _approve : null,
        child: const Text('Onaylıyorum'),
      ),
      TextButton(
        key: const ValueKey('consent-update-decline'),
        onPressed: _busy ? null : _decline,
        child: const Text('Onay vermiyorum (tüm veriler silinir)'),
      ),
    ],
  );
}
