class ParentTip {
  final String title;
  final String body;

  const ParentTip(this.title, this.body);
}

/// Ebeveynlere yönelik genel öneriler.
///
/// Bunlar yalnızca öneridir; uygulamadaki hiçbir davranış bunlara bağlı
/// değildir. Tıbbi, psikolojik veya tanısal iddia içermez. İçerik danışman
/// hocanın incelemesinden geçmelidir (bkz.
/// docs/ebeveyn-modulu/EBEVEYN_IPUCLARI.md).
class ParentTips {
  const ParentTips._();

  static const String disclaimer =
      'Bu öneriler genel bilgilendirme amaçlıdır; uzman görüşünün yerini '
      'tutmaz. Çocuğunuzun gelişimiyle ilgili bir kaygınız varsa '
      'öğretmenine veya bir uzmana danışın.';

  static const List<ParentTip> tips = [
    ParentTip(
      'Kısa ve sık oynayın',
      'Tek bir uzun oturum yerine günde birkaç dakikalık kısa oturumlar '
          'küçük çocuklar için genellikle daha keyiflidir. Çocuğunuz '
          'yorulduğunda ara vermek sorun değildir.',
    ),
    ParentTip(
      'Yanlış cevap öğrenmenin parçasıdır',
      'Yanlış cevapta "olmadı" demek yerine "nasıl düşündün?" diye '
          'sorabilirsiniz. Amaç doğru sayısı değil, çocuğun denemeye devam '
          'etmesidir.',
    ),
    ParentTip(
      'Çabayı övün',
      '"Çok zekisin" yerine "çok güzel uğraştın" gibi çabayı öne çıkaran '
          'sözler, çocuğun zor sorulardan kaçmamasına yardımcı olabilir.',
    ),
    ParentTip(
      'Matematiği günlük hayata taşıyın',
      'Sofraya kaç tabak koyacağınızı birlikte sayın, merdivenleri '
          'sayarak çıkın, meyveleri paylaştırın. Oyundaki beceriler günlük '
          'hayatta pekişir.',
    ),
    ParentTip(
      'Yanında olun',
      'Özellikle küçük yaşlarda çocuğunuzla birlikte oynamak, soruları '
          'ona okumak ve ne yaptığını anlattırmak oyunu daha verimli kılar.',
    ),
    ParentTip(
      'Sayıları karşılaştırmayın, çocukları da',
      'Buradaki puanlar bir sınav sonucu değildir. Çocuğunuzu başka '
          'çocuklarla veya kardeşiyle kıyaslamak yerine kendi ilerlemesine '
          'bakın.',
    ),
    ParentTip(
      'İlerleme ekranını bir pusula gibi kullanın',
      'Zorlandığı bir konu görürseniz bunu bir eksik olarak değil, '
          'birlikte biraz daha oynayabileceğiniz bir alan olarak düşünün.',
    ),
  ];
}
