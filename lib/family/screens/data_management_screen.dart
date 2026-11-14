import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../progress/session_history_controller.dart';
import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../domain/trash_entry.dart';
import '../family_config.dart';
import '../navigation/family_navigation.dart';
import '../widgets/destructive_confirmation.dart';
import '../widgets/family_widgets.dart';

/// Veri yönetimi: ilerlemeyi sıfırlama, her şeyi silme ve Silinenler.
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  static const int _days = FamilyConfig.trashRetentionDays;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Süresi dolan kayıtlar ekran açılırken kalıcı olarak silinir.
    final controller = context.read<FamilyController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.purgeExpiredTrash();
    });
  }

  /// [action] çalışırken düğmeleri kilitler, sonra oyun tarafının önbelleğini
  /// tazeler ve sonucu bildirir.
  Future<void> _run(Future<void> Function() action, String doneMessage) async {
    final history = context.read<SessionHistoryController?>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    String message = doneMessage;
    try {
      await action();
      await history?.load();
    } catch (error) {
      message = 'İşlem tamamlanamadı: $error';
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _resetProgress() async {
    final controller = context.read<FamilyController>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: 'İlerlemeyi sıfırla',
      consequences: const [
        'Tüm oturum geçmişi ve öğrenme ilerlemesi silinir; çocuğunuz en '
            'baştan başlar.',
        'Silinen ilerleme $_days gün boyunca "Silinenler" bölümünde durur '
            've bu sürede geri yüklenebilir. Sonra kalıcı olarak silinir.',
        'Çocuk profili, PIN ve rızanız değişmez.',
      ],
      afterwards: const ['Bir şey yapmanız gerekmez.'],
      confirmLabel: 'İlerlemeyi sıfırla',
    );
    if (confirmed == null) return;
    await _run(
      controller.resetProgress,
      'İlerleme sıfırlandı. $_days gün içinde Silinenler\'den geri '
      'yükleyebilirsiniz.',
    );
  }

  Future<void> _deleteEverything() async {
    final controller = context.read<FamilyController>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: 'Her şeyi sil',
      consequences: const [
        'Çocuk profili, PIN ve rıza kaydı hemen ve kalıcı olarak silinir.',
        'Uygulamanın bu cihazda sakladığı diğer tüm yerel veriler de '
            'silinir.',
      ],
      consequencesFor: (keep) => [
        keep
            ? 'Oyun ilerlemesi $_days gün boyunca "Silinenler" bölümünde '
                  'durur; yeniden kurulum yaparsanız bu sürede geri '
                  'yükleyebilirsiniz.'
            : 'Oyun ilerlemesi ve "Silinenler" içindeki her şey de hemen ve '
                  'kalıcı olarak silinir. Geri alınamaz.',
      ],
      afterwards: const [
        'Uygulama ilk kurulum ekranına döner.',
        'Yeniden kullanmak için rıza vermeniz, çocuk profili ve yeni bir PIN '
            'oluşturmanız gerekir.',
      ],
      optionLabel: 'Oyun ilerlemesini $_days gün boyunca geri alınabilir tut',
      optionInitialValue: true,
      confirmLabel: 'Her şeyi sil',
    );
    if (confirmed == null) return;
    await _run(
      () => controller.deleteEverything(
        keepProgressInTrash: confirmed.optionValue,
      ),
      'Veriler silindi.',
    );
  }

  Future<void> _restore(TrashEntry entry) async {
    final controller = context.read<FamilyController>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: 'Geri yükle',
      consequences: const [
        'Seçtiğiniz silinmiş ilerleme geri gelir.',
        'Şu anki ilerleme (varsa) kaybolmaz; "Silinenler" bölümüne taşınır.',
      ],
      confirmLabel: 'Geri yükle',
    );
    if (confirmed == null) return;
    await _run(
      () => controller.restoreFromTrash(entry.id),
      'İlerleme geri yüklendi.',
    );
  }

  Future<void> _purge(TrashEntry entry) async {
    final controller = context.read<FamilyController>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: 'Şimdi kalıcı olarak sil',
      consequences: const [
        'Bu kayıt hemen ve kalıcı olarak silinir. Geri alınamaz.',
      ],
      confirmLabel: 'Kalıcı olarak sil',
    );
    if (confirmed == null) return;
    await _run(
      () => controller.purgeFromTrash(entry.id),
      'Kayıt kalıcı olarak silindi.',
    );
  }

  Future<void> _emptyTrash() async {
    final controller = context.read<FamilyController>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: 'Silinenleri boşalt',
      consequences: const [
        '"Silinenler" içindeki tüm kayıtlar hemen ve kalıcı olarak silinir. '
            'Geri alınamaz.',
      ],
      confirmLabel: 'Tümünü kalıcı olarak sil',
    );
    if (confirmed == null) return;
    await _run(controller.emptyTrash, 'Silinenler boşaltıldı.');
  }

  static String _reasonLabel(TrashReason reason) => switch (reason) {
    TrashReason.progressReset => 'İlerleme sıfırlandı',
    TrashReason.fullDeletion => 'Her şey silindi',
    TrashReason.replacedByRestore => 'Geri yükleme sırasında yerine alındı',
  };

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    final controller = context.watch<FamilyController>();
    final entries = controller.trashEntries;
    final now = controller.now;
    return FamilyPage(
      title: 'Veri yönetimi',
      leading: IconButton(
        key: const ValueKey('data-back'),
        tooltip: 'Geri',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(FamilyRoutes.parentSettings),
      ),
      children: [
        FamilyCard(
          title: 'İlerlemeyi sıfırla',
          children: [
            const Text(
              'Çocuğunuz en baştan başlar. Profil, PIN ve rıza kalır. '
              'Silinen ilerleme $_days gün boyunca geri alınabilir.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const ValueKey('data-reset-progress'),
                onPressed: _busy ? null : _resetProgress,
                child: const Text('İlerlemeyi sıfırla'),
              ),
            ),
          ],
        ),
        FamilyCard(
          title: 'Her şeyi sil',
          children: [
            const Text(
              'Profil, PIN, rıza ve tüm veriler silinir; uygulama ilk kuruluma '
              'döner.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const ValueKey('data-delete-everything'),
                style: FilledButton.styleFrom(backgroundColor: palette.redPen),
                onPressed: _busy ? null : _deleteEverything,
                child: const Text('Her şeyi sil'),
              ),
            ),
          ],
        ),
        FamilyCard(
          title: 'Silinenler',
          children: [
            const Text(
              'Silinen ilerleme burada $_days gün tutulur, sonra uygulamanın '
              'bir sonraki açılışında kalıcı olarak silinir.',
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Text(
                'Silinenler boş.',
                key: ValueKey('trash-empty'),
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            for (final entry in entries) ...[
              const Divider(),
              Text(
                '${_reasonLabel(entry.reason)}'
                '${entry.childNickname == null ? '' : ' — ${entry.childNickname}'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Silinme: ${formatDateTime(entry.deletedAt)} • Kalıcı '
                'silinmeye ${entry.daysLeft(now)} gün kaldı',
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: ValueKey('trash-restore-${entry.id}'),
                    onPressed: _busy ? null : () => _restore(entry),
                    child: const Text('Geri yükle'),
                  ),
                  OutlinedButton(
                    key: ValueKey('trash-purge-${entry.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.redPen,
                    ),
                    onPressed: _busy ? null : () => _purge(entry),
                    child: const Text('Şimdi kalıcı olarak sil'),
                  ),
                ],
              ),
            ],
            if (entries.length > 1) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('trash-empty-all'),
                  style: TextButton.styleFrom(foregroundColor: palette.redPen),
                  onPressed: _busy ? null : _emptyTrash,
                  child: const Text('Silinenleri boşalt'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
