import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../family_config.dart';
import '../navigation/family_navigation.dart';
import '../widgets/family_widgets.dart';

/// Ebeveyn bölümüne giriş: PIN sorar.
class PinGateScreen extends StatefulWidget {
  const PinGateScreen({super.key});

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  String _pin = '';
  String? _message;
  bool _checking = false;

  Future<void> _onChanged(String value) async {
    setState(() {
      _pin = value;
      if (value.isNotEmpty) _message = null;
    });
    if (value.length < FamilyConfig.pinLength || _checking) return;
    setState(() => _checking = true);
    final controller = context.read<FamilyController>();
    final PinCheckResult result;
    try {
      result = await controller.unlockParent(value);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _pin = '';
        _message = 'PIN kontrol edilemedi: $error';
      });
      return;
    }
    if (!mounted) return;
    if (result is PinAccepted) {
      context.go(FamilyRoutes.parentHome);
      return;
    }
    setState(() {
      _checking = false;
      _pin = '';
      _message = pinResultMessage(result, controller.now);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // Android geri tuşu uygulamadan çıkmak yerine rol seçimine döner.
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go(FamilyRoutes.rolePicker);
    },
    child: _buildPage(context),
  );

  Widget _buildPage(BuildContext context) => FamilyPage(
    maxWidth: 420,
    children: [
      const SizedBox(height: 24),
      Icon(Icons.lock_outline, size: 48, color: Palette().darkPen),
      const SizedBox(height: 8),
      const Text(
        'Ebeveyn girişi',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      const Text('PIN\'inizi girin', textAlign: TextAlign.center),
      const SizedBox(height: 16),
      if (_checking)
        const Center(child: CircularProgressIndicator())
      else
        Center(
          child: PinPad(value: _pin, onChanged: _onChanged),
        ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _message!,
            key: const ValueKey('pin-gate-message'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Palette().redPen),
          ),
        ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          key: const ValueKey('pin-gate-back'),
          onPressed: () => context.go(FamilyRoutes.rolePicker),
          child: const Text('Geri'),
        ),
      ),
    ],
  );
}
