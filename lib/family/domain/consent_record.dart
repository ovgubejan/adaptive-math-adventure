import '../family_config.dart';

/// Ebeveynin verdiği açık rızanın kaydı.
///
/// Hangi metin sürümüne, ne zaman onay verildiğini saklar. Metin sürümü
/// değişirse uygulama yeniden onay ister.
class ConsentRecord {
  /// Onaylanan aydınlatma/rıza metninin sürümü (bkz. `ConsentText.version`).
  final String textVersion;
  final DateTime grantedAt;

  /// Rıza geri çekildiyse zamanı. Yerel yapıda geri çekme tüm veriyi hemen
  /// sildiği için bu alan pratikte hep `null` kalır; sunucu eşitlemesi için
  /// modelde tutulur.
  final DateTime? withdrawnAt;

  /// Geliştirici modunun oluşturduğu test kaydı mı? Gerçek bir ebeveyn
  /// onayı DEĞİLDİR ve öyle sayılmamalıdır.
  final bool isDevSeed;

  final Map<String, Object?> extra;

  const ConsentRecord({
    required this.textVersion,
    required this.grantedAt,
    this.withdrawnAt,
    this.isDevSeed = false,
    this.extra = const {},
  });

  static const _knownKeys = {
    'schemaVersion',
    'textVersion',
    'grantedAt',
    'withdrawnAt',
    'isDevSeed',
  };

  bool get isActive => withdrawnAt == null;

  Map<String, Object?> toJson() => {
    ...extra,
    'schemaVersion': FamilyConfig.schemaVersion,
    'textVersion': textVersion,
    'grantedAt': grantedAt.toIso8601String(),
    'withdrawnAt': withdrawnAt?.toIso8601String(),
    'isDevSeed': isDevSeed,
  };

  static ConsentRecord? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final textVersion = json['textVersion'];
    final grantedAtRaw = json['grantedAt'];
    final grantedAt = grantedAtRaw is String
        ? DateTime.tryParse(grantedAtRaw)
        : null;
    if (textVersion is! String || grantedAt == null) return null;
    final withdrawnAtRaw = json['withdrawnAt'];
    return ConsentRecord(
      textVersion: textVersion,
      grantedAt: grantedAt,
      withdrawnAt: withdrawnAtRaw is String
          ? DateTime.tryParse(withdrawnAtRaw)
          : null,
      isDevSeed: json['isDevSeed'] == true,
      extra: {
        for (final entry in json.entries)
          if (entry.key is String && !_knownKeys.contains(entry.key))
            entry.key as String: entry.value,
      },
    );
  }
}
