import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../progress/session_history_controller.dart';
import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../content/consent_text.dart';
import '../data/local_family_repositories.dart';
import '../domain/child_profile.dart';
import '../family_config.dart';
import '../navigation/family_navigation.dart';
import '../widgets/destructive_confirmation.dart';
import '../widgets/family_widgets.dart';
import 'legal_text_screen.dart';
import 'setup_flow_screen.dart' show AgeSelector;

/// Ebeveyn ayarları: çocuk profili, PIN, rıza ve veri yönetimine geçiş.
class ParentSettingsScreen extends StatelessWidget {
  const ParentSettingsScreen({super.key});

  Future<void> _withdrawConsent(BuildContext context) async {
    final controller = context.read<FamilyController>();
    final history = context.read<SessionHistoryController?>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: 'Rızayı geri çek',
      consequences: const [
        'Çocuğunuzun profili, tüm oyun ilerlemesi, PIN ve rıza kaydı bu '
            'cihazdan hemen ve kalıcı olarak silinir.',
        '"Silinenler" içindeki kayıtlar da silinir. Bu işlem geri alınamaz.',
      ],
      afterwards: const [
        'Uygulama ilk kurulum ekranına döner.',
        'Yeniden kullanmak için kurulumu baştan yapmanız ve rıza vermeniz '
            'gerekir.',
      ],
      confirmLabel: 'Rızayı geri çek ve sil',
    );
    if (confirmed == null) return;
    try {
      await controller.withdrawConsent();
      await history?.load();
    } catch (error) {
      if (context.mounted) showFamilyMessage(context, 'Silinemedi: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FamilyController>();
    final profile = controller.profile;
    final consent = controller.consent;
    return FamilyPage(
      title: 'Ayarlar',
      leading: IconButton(
        key: const ValueKey('settings-back'),
        tooltip: 'Geri',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(FamilyRoutes.parentHome),
      ),
      children: [
        FamilyCard(
          title: 'Çocuk profili',
          children: [
            Text(
              profile == null
                  ? 'Profil bulunamadı.'
                  : 'Takma ad: ${profile.nickname}\nYaş: ${profile.age}',
              key: const ValueKey('settings-profile-summary'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const ValueKey('settings-edit-profile'),
                onPressed: profile == null
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => _EditProfileDialog(profile: profile),
                      ),
                child: const Text('Düzenle'),
              ),
            ),
          ],
        ),
        FamilyCard(
          title: 'Ebeveyn PIN\'i',
          children: [
            const Text('PIN ebeveyn bölümünü korur. Unutulursa kurtarılamaz.'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const ValueKey('settings-change-pin'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _ChangePinDialog(),
                ),
                child: const Text('PIN\'i değiştir'),
              ),
            ),
          ],
        ),
        FamilyCard(
          title: 'Rıza',
          children: [
            Text(
              consent == null
                  ? 'Rıza kaydı bulunamadı.'
                  : 'Onay tarihi: ${formatDateTime(consent.grantedAt)}\n'
                        'Metin sürümü: ${consent.textVersion}'
                        '${consent.isDevSeed ? '\n(Geliştirici modu test kaydı — gerçek onay değildir.)' : ''}',
            ),
            if (ConsentText.isDraft)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  ConsentText.draftNotice,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('settings-read-legal'),
                  onPressed: () => LegalTextScreen.open(context),
                  child: const Text('Aydınlatma metnini oku'),
                ),
                OutlinedButton(
                  key: const ValueKey('settings-withdraw-consent'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette().redPen,
                  ),
                  onPressed: () => _withdrawConsent(context),
                  child: const Text('Rızayı geri çek'),
                ),
              ],
            ),
          ],
        ),
        FamilyCard(
          title: 'Veri yönetimi',
          children: [
            const Text(
              'İlerlemeyi sıfırlama, tüm verileri silme ve silinenleri geri '
              'yükleme.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const ValueKey('settings-open-data'),
                onPressed: () => context.go(FamilyRoutes.parentData),
                child: const Text('Veri yönetimini aç'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final ChildProfile profile;

  const _EditProfileDialog({required this.profile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final _nicknameController = TextEditingController(
    text: widget.profile.nickname,
  );
  late int? _age = widget.profile.age;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final error =
        ChildProfile.validateNickname(_nicknameController.text) ??
        ChildProfile.validateAge(_age);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final controller = context.read<FamilyController>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await controller.updateProfile(
        nickname: _nicknameController.text,
        age: _age!,
      );
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Kaydedilemedi: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Çocuk profili'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('profile-nickname'),
              controller: _nicknameController,
              maxLength: FamilyConfig.maxNicknameLength,
              decoration: const InputDecoration(
                labelText: 'Takma ad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Yaş'),
            const SizedBox(height: 8),
            AgeSelector(
              selected: _age,
              onSelected: (age) => setState(() => _age = age),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Palette().redPen)),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        key: const ValueKey('profile-save'),
        onPressed: _saving ? null : _save,
        child: const Text('Kaydet'),
      ),
    ],
  );
}

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog();

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _repeatController = TextEditingController();
  String? _currentError;
  String? _newError;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newPin = _newController.text;
    setState(() {
      _currentError = null;
      _newError = null;
    });
    if (!LocalParentPinRepository.isValidPin(newPin)) {
      setState(
        () => _newError =
            'Yeni PIN ${FamilyConfig.pinLength} rakamdan oluşmalıdır.',
      );
      return;
    }
    if (newPin != _repeatController.text) {
      setState(() => _newError = 'Yeni PIN\'ler aynı değil.');
      return;
    }
    final controller = context.read<FamilyController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final result = await controller.checkPin(_currentController.text);
      if (result is! PinAccepted) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _currentController.clear();
          _currentError = pinResultMessage(result, controller.now);
        });
        return;
      }
      await controller.changePin(newPin);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('PIN değiştirildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _newError = 'PIN değiştirilemedi: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('PIN\'i değiştir'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PinTextField(
              key: const ValueKey('pin-current'),
              controller: _currentController,
              label: 'Mevcut PIN',
              errorText: _currentError,
            ),
            const SizedBox(height: 12),
            PinTextField(
              key: const ValueKey('pin-new'),
              controller: _newController,
              label: 'Yeni PIN',
              errorText: _newError,
            ),
            const SizedBox(height: 12),
            PinTextField(
              key: const ValueKey('pin-repeat'),
              controller: _repeatController,
              label: 'Yeni PIN (tekrar)',
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        key: const ValueKey('pin-save'),
        onPressed: _saving ? null : _save,
        child: const Text('Kaydet'),
      ),
    ],
  );
}
