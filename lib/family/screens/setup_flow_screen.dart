import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/mascot/mascot_state.dart';
import '../../presentation/mascot/mascot_widget.dart';
import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../domain/child_profile.dart';
import '../family_config.dart';
import '../widgets/family_widgets.dart';
import 'legal_text_screen.dart';

enum _SetupStep { welcome, consent, child, pin, pinConfirm }

/// İlk açılış kurulumu: karşılama → aydınlatma ve rıza → çocuk profili → PIN.
///
/// Hiçbir şey son adım tamamlanana kadar kaydedilmez. Rıza onaylanmadan
/// çocuk bilgisi adımına geçilemez.
class SetupFlowScreen extends StatefulWidget {
  const SetupFlowScreen({super.key});

  @override
  State<SetupFlowScreen> createState() => _SetupFlowScreenState();
}

class _SetupFlowScreenState extends State<SetupFlowScreen> {
  final _nicknameController = TextEditingController();
  _SetupStep _step = _SetupStep.welcome;
  bool _consentAccepted = false;
  int? _age;
  String _pin = '';
  String _pinRepeat = '';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _goTo(_SetupStep step) => setState(() {
    _step = step;
    _error = null;
  });

  void _submitChild() {
    final error =
        ChildProfile.validateNickname(_nicknameController.text) ??
        ChildProfile.validateAge(_age);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _pin = '';
      _pinRepeat = '';
    });
    _goTo(_SetupStep.pin);
  }

  void _onPinChanged(String value) {
    setState(() => _pin = value);
    if (value.length == FamilyConfig.pinLength) _goTo(_SetupStep.pinConfirm);
  }

  Future<void> _onPinRepeatChanged(String value) async {
    setState(() => _pinRepeat = value);
    if (value.length < FamilyConfig.pinLength) return;
    if (value != _pin) {
      setState(() {
        _pin = '';
        _pinRepeat = '';
        _step = _SetupStep.pin;
        _error = 'PIN\'ler aynı değil. Lütfen yeniden belirleyin.';
      });
      return;
    }
    if (!_consentAccepted) {
      _goTo(_SetupStep.consent);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<FamilyController>().completeSetup(
        nickname: _nicknameController.text,
        age: _age!,
        pin: _pin,
      );
      // Kurulum tamamlanınca yönlendirici rol seçimi ekranını açar.
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _pinRepeat = '';
        _error = 'Kurulum kaydedilemedi: $error';
      });
    }
  }

  _SetupStep? get _previousStep => switch (_step) {
    _SetupStep.welcome => null,
    _SetupStep.consent => _SetupStep.welcome,
    _SetupStep.child => _SetupStep.consent,
    _SetupStep.pin => _SetupStep.child,
    _SetupStep.pinConfirm => _SetupStep.pin,
  };

  @override
  Widget build(BuildContext context) => PopScope(
    // Android geri tuşu kurulumda bir önceki adıma döner.
    canPop: _previousStep == null,
    onPopInvokedWithResult: (didPop, _) {
      final previous = _previousStep;
      if (!didPop && previous != null && !_saving) _goTo(previous);
    },
    child: _buildPage(context),
  );

  Widget _buildPage(BuildContext context) => FamilyPage(
    backgroundColor: Palette().backgroundMain,
    children: [
      ...switch (_step) {
        _SetupStep.welcome => _welcome(),
        _SetupStep.consent => _consent(),
        _SetupStep.child => _child(),
        _SetupStep.pin => _pinStep(
          title: 'Ebeveyn PIN\'i oluşturun',
          value: _pin,
          onChanged: _onPinChanged,
          back: _SetupStep.child,
        ),
        _SetupStep.pinConfirm => _pinStep(
          title: 'PIN\'i tekrar girin',
          value: _pinRepeat,
          onChanged: _onPinRepeatChanged,
          back: _SetupStep.pin,
        ),
      },
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            key: const ValueKey('setup-error'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Palette().redPen),
          ),
        ),
    ],
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Palette().darkPen,
        fontSize: 28,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  List<Widget> _welcome() => [
    const SizedBox(height: 12),
    const Center(child: MascotWidget(state: MascotState.idle, size: 140)),
    const SizedBox(height: 12),
    _heading('Matematik Macerası\'na hoş geldiniz!'),
    const Text(
      'Başlamadan önce kısa bir kurulum yapacağız. Bu kurulumu bir '
      'yetişkinin (anne, baba veya veli) yapması gerekir.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16),
    ),
    const SizedBox(height: 24),
    FilledButton(
      key: const ValueKey('setup-start'),
      onPressed: () => _goTo(_SetupStep.consent),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Başlayalım'),
      ),
    ),
  ];

  List<Widget> _consent() => [
    _heading('Ebeveyn bilgilendirmesi'),
    ConsentForm(
      accepted: _consentAccepted,
      onAcceptedChanged: (value) => setState(() => _consentAccepted = value),
    ),
    const SizedBox(height: 12),
    FilledButton(
      key: const ValueKey('setup-consent-continue'),
      onPressed: _consentAccepted ? () => _goTo(_SetupStep.child) : null,
      child: const Text('Devam'),
    ),
    TextButton(
      onPressed: () => _goTo(_SetupStep.welcome),
      child: const Text('Geri'),
    ),
  ];

  List<Widget> _child() => [
    _heading('Çocuğunuz kim?'),
    TextField(
      key: const ValueKey('setup-nickname'),
      controller: _nicknameController,
      maxLength: FamilyConfig.maxNicknameLength,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Takma ad',
        helperText: 'Gerçek adını yazmak zorunda değilsiniz.',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    const SizedBox(height: 16),
    const Text('Yaş', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    AgeSelector(
      selected: _age,
      onSelected: (age) => setState(() => _age = age),
    ),
    const SizedBox(height: 24),
    FilledButton(
      key: const ValueKey('setup-child-continue'),
      onPressed: _submitChild,
      child: const Text('Devam'),
    ),
    TextButton(
      onPressed: () => _goTo(_SetupStep.consent),
      child: const Text('Geri'),
    ),
  ];

  List<Widget> _pinStep({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
    required _SetupStep back,
  }) => [
    _heading(title),
    const Text(
      'Bu PIN ebeveyn bölümünü korur. Çocuğunuzun bilmediği '
      '${FamilyConfig.pinLength} rakam seçin ve unutmayın: PIN\'i '
      'kurtarmanın bir yolu yoktur.',
      textAlign: TextAlign.center,
    ),
    const SizedBox(height: 16),
    if (_saving)
      const Center(child: CircularProgressIndicator())
    else
      Center(
        child: PinPad(value: value, onChanged: onChanged),
      ),
    if (!_saving)
      TextButton(onPressed: () => _goTo(back), child: const Text('Geri')),
  ];
}

/// [FamilyConfig.minChildAge]–[FamilyConfig.maxChildAge] arası yaş seçimi.
class AgeSelector extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelected;

  const AgeSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (
        var age = FamilyConfig.minChildAge;
        age <= FamilyConfig.maxChildAge;
        age++
      )
        ChoiceChip(
          key: ValueKey('age-$age'),
          label: Text('$age'),
          selected: selected == age,
          onSelected: (_) => onSelected(age),
        ),
    ],
  );
}
