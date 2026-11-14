import '../family_config.dart';

enum TrashReason {
  /// Ebeveyn "İlerlemeyi sıfırla" dedi.
  progressReset,

  /// Ebeveyn "Her şeyi sil" dedi ve ilerlemenin geri alınabilir kalmasını
  /// seçti.
  fullDeletion,

  /// Silinenlerden bir kayıt geri yüklenirken o anki ilerleme buraya alındı.
  replacedByRestore,
}

/// "Silinenler" içindeki tek bir kayıt: silinen ilerleme verisinin anlık
/// görüntüsü. [FamilyConfig.trashRetention] sonunda kalıcı olarak silinir.
class TrashEntry {
  final String id;
  final DateTime deletedAt;
  final TrashReason reason;

  /// Silindiği andaki çocuk takma adı; listede göstermek için.
  final String? childNickname;

  /// Veri modülü kimliği -> o modülün verdiği anlık görüntü.
  final Map<String, String> snapshots;

  const TrashEntry({
    required this.id,
    required this.deletedAt,
    required this.reason,
    required this.snapshots,
    this.childNickname,
  });

  DateTime get expiresAt => deletedAt.add(FamilyConfig.trashRetention);

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  /// Kalıcı silinmeye kalan gün sayısı (yukarı yuvarlanır, en az 0).
  int daysLeft(DateTime now) {
    final remaining = expiresAt.difference(now);
    if (remaining.isNegative) return 0;
    return (remaining.inMinutes / Duration.minutesPerDay).ceil();
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': FamilyConfig.schemaVersion,
    'id': id,
    'deletedAt': deletedAt.toIso8601String(),
    'reason': reason.name,
    'childNickname': childNickname,
    'snapshots': snapshots,
  };

  static TrashEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final deletedAtRaw = json['deletedAt'];
    final deletedAt = deletedAtRaw is String
        ? DateTime.tryParse(deletedAtRaw)
        : null;
    final snapshots = json['snapshots'];
    if (id is! String || deletedAt == null || snapshots is! Map) return null;
    final nickname = json['childNickname'];
    return TrashEntry(
      id: id,
      deletedAt: deletedAt,
      reason: TrashReason.values.firstWhere(
        (reason) => reason.name == json['reason'],
        orElse: () => TrashReason.progressReset,
      ),
      childNickname: nickname is String ? nickname : null,
      snapshots: {
        for (final entry in snapshots.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      },
    );
  }
}
