import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PIN'i tek yönlü özetler (PBKDF2-HMAC-SHA256).
///
/// Not: 4 haneli bir PIN yalnızca 10.000 olasılık içerir; özetleme PIN'in
/// düz metin olarak saklanmasını önler ama tek başına güçlü bir koruma
/// değildir. Asıl koruma özetin işletim sisteminin güvenli deposunda
/// durması ve yanlış deneme sınırıdır.
class PinHasher {
  static const String algorithm = 'pbkdf2-hmac-sha256';

  final int iterations;
  final Random _random;

  PinHasher({this.iterations = 10000, Random? random})
    : _random = random ?? Random.secure();

  /// Rastgele 16 baytlık tuz (base64).
  String newSalt() =>
      base64Encode(List<int>.generate(16, (_) => _random.nextInt(256)));

  /// [pin] için 32 baytlık özet (base64). [salt] base64 olmalıdır.
  String hash(String pin, String salt, {int? iterations}) {
    final rounds = iterations ?? this.iterations;
    if (rounds < 1) throw ArgumentError.value(rounds, 'iterations');
    final hmac = Hmac(sha256, utf8.encode(pin));
    var block = hmac.convert([...base64Decode(salt), 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block);
    for (var round = 1; round < rounds; round++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= block[index];
      }
    }
    return base64Encode(result);
  }

  /// Uzunluk dışında zamanlama bilgisi sızdırmayan karşılaştırma.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var index = 0; index < a.length; index++) {
      difference |= a.codeUnitAt(index) ^ b.codeUnitAt(index);
    }
    return difference == 0;
  }
}
