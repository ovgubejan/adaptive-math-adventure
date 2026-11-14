import '../family_config.dart';

/// Çocuğun yerel profili. Bilinçli olarak yalnızca takma ad ve yaş tutar;
/// gerçek ad, doğum tarihi, e-posta, fotoğraf veya konum tutulmaz.
class ChildProfile {
  final String nickname;
  final int age;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Bu sürümün tanımadığı alanlar. Daha yeni bir sürümün (ör. sunucu
  /// eşitlemesi) yazdığı veriyi kaybetmemek için okunur ve geri yazılır.
  final Map<String, Object?> extra;

  const ChildProfile({
    required this.nickname,
    required this.age,
    required this.createdAt,
    required this.updatedAt,
    this.extra = const {},
  });

  static const _knownKeys = {
    'schemaVersion',
    'nickname',
    'age',
    'createdAt',
    'updatedAt',
  };

  /// Geçerliyse `null`, değilse kullanıcıya gösterilecek hata metni döner.
  static String? validateNickname(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Lütfen bir takma ad yazın.';
    if (trimmed.length > FamilyConfig.maxNicknameLength) {
      return 'Takma ad en fazla ${FamilyConfig.maxNicknameLength} karakter olabilir.';
    }
    return null;
  }

  static String? validateAge(int? age) {
    if (age == null) return 'Lütfen çocuğunuzun yaşını seçin.';
    if (age < FamilyConfig.minChildAge || age > FamilyConfig.maxChildAge) {
      return 'Yaş ${FamilyConfig.minChildAge}–${FamilyConfig.maxChildAge} arasında olmalıdır.';
    }
    return null;
  }

  ChildProfile copyWith({String? nickname, int? age, DateTime? updatedAt}) =>
      ChildProfile(
        nickname: nickname ?? this.nickname,
        age: age ?? this.age,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        extra: extra,
      );

  Map<String, Object?> toJson() => {
    ...extra,
    'schemaVersion': FamilyConfig.schemaVersion,
    'nickname': nickname,
    'age': age,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Bozuk veya eksik kayıtta `null` döner; bilinmeyen alanları korur.
  static ChildProfile? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final nickname = json['nickname'];
    final age = json['age'];
    if (nickname is! String || nickname.trim().isEmpty || age is! int) {
      return null;
    }
    final createdAt = _parseDate(json['createdAt']);
    return ChildProfile(
      nickname: nickname,
      age: age,
      createdAt: createdAt,
      updatedAt: _parseDate(json['updatedAt'], fallback: createdAt),
      extra: {
        for (final entry in json.entries)
          if (entry.key is String && !_knownKeys.contains(entry.key))
            entry.key as String: entry.value,
      },
    );
  }

  static DateTime _parseDate(Object? value, {DateTime? fallback}) =>
      (value is String ? DateTime.tryParse(value) : null) ??
      fallback ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
