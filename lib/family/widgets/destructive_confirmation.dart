import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../family_config.dart';
import 'family_widgets.dart';

/// Yalnızca rakam kabul eden, gizli PIN alanı.
class PinTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool autofocus;

  const PinTextField({
    required this.controller,
    required this.label,
    this.errorText,
    this.autofocus = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    obscureText: true,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(FamilyConfig.pinLength),
    ],
    decoration: InputDecoration(
      labelText: label,
      errorText: errorText,
      border: const OutlineInputBorder(),
    ),
  );
}

class DestructiveConfirmationResult {
  /// İsteğe bağlı seçenek kutusunun son değeri (kutu yoksa `false`).
  final bool optionValue;

  const DestructiveConfirmationResult({required this.optionValue});
}

/// Geri dönüşü zor işlemlerden önce gösterilen onay penceresi.
///
/// Ne olacağını ve sonrasında ne yapılması gerekeceğini açıkça yazar,
/// onay için ebeveyn PIN'ini yeniden ister. Vazgeçilirse `null` döner.
Future<DestructiveConfirmationResult?> showDestructiveConfirmation(
  BuildContext context, {
  required String title,
  required List<String> consequences,
  required String confirmLabel,
  List<String> afterwards = const [],
  String? optionLabel,
  bool optionInitialValue = false,
  List<String> Function(bool optionValue)? consequencesFor,
}) => showDialog<DestructiveConfirmationResult>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _DestructiveConfirmationDialog(
    title: title,
    consequences: consequences,
    afterwards: afterwards,
    confirmLabel: confirmLabel,
    optionLabel: optionLabel,
    optionInitialValue: optionInitialValue,
    consequencesFor: consequencesFor,
  ),
);

class _DestructiveConfirmationDialog extends StatefulWidget {
  final String title;
  final List<String> consequences;
  final List<String> afterwards;
  final String confirmLabel;
  final String? optionLabel;
  final bool optionInitialValue;
  final List<String> Function(bool optionValue)? consequencesFor;

  const _DestructiveConfirmationDialog({
    required this.title,
    required this.consequences,
    required this.afterwards,
    required this.confirmLabel,
    required this.optionLabel,
    required this.optionInitialValue,
    required this.consequencesFor,
  });

  @override
  State<_DestructiveConfirmationDialog> createState() =>
      _DestructiveConfirmationDialogState();
}

class _DestructiveConfirmationDialogState
    extends State<_DestructiveConfirmationDialog> {
  final _pinController = TextEditingController();
  late bool _option = widget.optionInitialValue;
  String? _pinError;
  bool _checking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final controller = context.read<FamilyController>();
    final navigator = Navigator.of(context);
    setState(() {
      _checking = true;
      _pinError = null;
    });
    final PinCheckResult result;
    try {
      result = await controller.checkPin(_pinController.text);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _pinError = 'PIN kontrol edilemedi: $error';
      });
      return;
    }
    if (!mounted) return;
    if (result is PinAccepted) {
      navigator.pop(DestructiveConfirmationResult(optionValue: _option));
      return;
    }
    setState(() {
      _checking = false;
      _pinController.clear();
      _pinError = pinResultMessage(result, controller.now);
    });
  }

  Widget _bullets(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(item)),
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final consequences = [
      ...widget.consequences,
      ...?widget.consequencesFor?.call(_option),
    ];
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ne olacak?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _bullets(consequences),
              if (widget.afterwards.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Sonrasında ne yapmanız gerekecek?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _bullets(widget.afterwards),
              ],
              if (widget.optionLabel != null)
                CheckboxListTile(
                  key: const ValueKey('confirm-option'),
                  value: _option,
                  onChanged: _checking
                      ? null
                      : (value) => setState(() => _option = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(widget.optionLabel!),
                ),
              const SizedBox(height: 12),
              PinTextField(
                key: const ValueKey('confirm-pin'),
                controller: _pinController,
                label: 'Onaylamak için PIN\'inizi girin',
                errorText: _pinError,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('confirm-cancel'),
          onPressed: _checking ? null : () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const ValueKey('confirm-accept'),
          style: FilledButton.styleFrom(backgroundColor: Palette().redPen),
          onPressed: _checking ? null : _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
