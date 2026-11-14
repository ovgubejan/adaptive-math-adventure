import '../family_config.dart';

class ConsentSection {
  final String title;
  final String body;

  const ConsentSection(this.title, this.body);
}

/// Uygulamada gösterilen aydınlatma ve açık rıza metni.
///
/// !!! TASLAKTIR. Hukuki inceleme yapılmamıştır. Yayınlamadan önce bir
/// uzman tarafından gözden geçirilmelidir.
///
/// KURAL: Bu metin uygulamanın GERÇEKTE yaptığını anlatmalıdır. Toplanan
/// veri, saklama yeri veya süresi değişirse:
///   1. Metni güncelleyin,
///   2. [version] değerini değiştirin (uygulama ebeveynden yeniden onay ister),
///   3. docs/ebeveyn-modulu/VERI_ENVANTERI.md dosyasını güncelleyin.
/// Metnin dayanak maddeleriyle birlikte açıklamalı hâli:
/// docs/ebeveyn-modulu/AYDINLATMA_VE_RIZA_METNI.md
class ConsentText {
  const ConsentText._();

  /// Metnin sürümü. İçerik değiştiğinde MUTLAKA değiştirin.
  static const String version = 'taslak-2026-11-v1';

  static const bool isDraft = true;

  static const String title = 'Aydınlatma Metni ve Açık Rıza';

  /// Doldurulacak alanlar (danışman hocaya sorulacak).
  static const String dataController = '[VERİ SORUMLUSU: AD SOYAD / KURUM]';
  static const String dataControllerContact = '[İLETİŞİM: E-POSTA / ADRES]';

  static const String draftNotice =
      'Bu metin taslaktır ve hukuki incelemeden geçmemiştir. Uygulama bir '
      'öğrenci bitirme projesinin prototipidir.';

  /// Rıza ekranında gösterilen kısa özet. Tam metnin yerine geçmez.
  static const List<String> summaryPoints = [
    'Yalnızca çocuğunuzun takma adını, yaşını ve oyundaki ilerlemesini '
        'kaydederiz.',
    'Veriler yalnızca bu cihazda durur; internete veya başka birine '
        'gönderilmez.',
    'Reklam, izleme veya analiz aracı yoktur. Mikrofon, kamera ve konum '
        'kullanılmaz.',
    'İstediğiniz zaman ebeveyn bölümünden verileri görebilir, düzeltebilir, '
        'silebilir ve rızanızı geri çekebilirsiniz.',
  ];

  static const String consentStatement =
      'Aydınlatma metnini okudum. Çocuğumun velisi (yasal temsilcisi) '
      'olarak, metinde belirtilen verilerin belirtilen amaçlarla bu cihazda '
      'işlenmesine açık rıza veriyorum.';

  static const List<ConsentSection> sections = [
    ConsentSection(
      '1. Veri sorumlusu',
      'Bu uygulamada kişisel verilerin işlenmesinden sorumlu olan taraf: '
          '$dataController. Sorularınız ve talepleriniz için: '
          '$dataControllerContact.',
    ),
    ConsentSection(
      '2. Hangi veriler işlenir?',
      '• Çocuğunuz için yazdığınız takma ad (gerçek ad yazmanız gerekmez).\n'
          '• Çocuğunuzun yaşı (${FamilyConfig.minChildAge}–'
          '${FamilyConfig.maxChildAge} arası bir sayı; doğum tarihi '
          'istenmez).\n'
          '• Oyun kayıtları: hangi sorunun sorulduğu, verilen cevaplar, '
          'cevabın doğru olup olmadığı, deneme sayısı, cevap süresi, ipucu '
          'kullanımı ve oturumun tarih ve saati.\n'
          '• Bu kayıtlardan hesaplanan öğrenme durumu: beceri bazında '
          'başarı, ustalık puanı ve önerilen zorluk düzeyi.\n'
          '• Ebeveyn PIN\'inizin geri döndürülemez özeti (PIN\'in kendisi '
          'saklanmaz).\n'
          '• Bu rızanın kaydı: onay tarihi ve onaylanan metnin sürümü.\n\n'
          'E-posta, telefon, adres, fotoğraf, ses, konum veya rehber '
          'bilgisi istenmez ve işlenmez.',
    ),
    ConsentSection(
      '3. Veriler hangi amaçla işlenir?',
      '• Soruların zorluğunu çocuğunuzun düzeyine göre ayarlamak.\n'
          '• Çocuğunuzun ilerlemesini size ebeveyn bölümünde göstermek.\n'
          '• Çocuğunuza oyunda takma adıyla hitap etmek.\n'
          '• Ebeveyn bölümünü PIN ile korumak.\n\n'
          'Veriler reklam, profilleme veya pazarlama amacıyla kullanılmaz.',
    ),
    ConsentSection(
      '4. Hukuki sebep',
      'Veriler, 6698 sayılı Kişisel Verilerin Korunması Kanunu\'nun '
          '5. maddesinin 1. fıkrası uyarınca açık rızanıza dayanılarak '
          'işlenir. Çocuğunuz reşit olmadığı için rızayı onun adına veli '
          '(yasal temsilci) olarak siz verirsiniz. Rıza vermezseniz '
          'uygulama kurulmaz ve hiçbir veri kaydedilmez.',
    ),
    ConsentSection(
      '5. Veriler nerede durur, kimlere aktarılır?',
      'Tüm veriler yalnızca bu cihazda, uygulamanın kendi depolama '
          'alanında saklanır. Uygulama bu verileri bir sunucuya, üçüncü '
          'kişilere veya yurt dışına aktarmaz. Uygulamada reklam veya '
          'kullanım analizi aracı bulunmaz.',
    ),
    ConsentSection(
      '6. Veriler ne kadar süre saklanır?',
      'Veriler siz silene kadar veya uygulama cihazdan kaldırılana kadar '
          'saklanır. Ebeveyn bölümünden sildiğiniz ilerleme verisi, '
          'yanlışlıkla silmeye karşı ${FamilyConfig.trashRetentionDays} gün '
          'boyunca "Silinenler" '
          'bölümünde tutulur ve bu sürede geri yüklenebilir. Süre dolunca '
          'uygulamanın bir sonraki açılışında kalıcı olarak silinir. '
          'Beklemek istemezseniz "Şimdi kalıcı olarak sil" seçeneğini '
          'kullanabilirsiniz.',
    ),
    ConsentSection(
      '7. Haklarınız',
      'Kanun\'un 11. maddesi uyarınca; verilerin işlenip işlenmediğini '
          'öğrenme, işlenen veriler hakkında bilgi isteme, yanlış verilerin '
          'düzeltilmesini ve verilerin silinmesini isteme haklarına '
          'sahipsiniz. Bu uygulamada:\n'
          '• Görme: kayıtlı tüm ilerleme ebeveyn bölümünde gösterilir.\n'
          '• Düzeltme: takma adı ve yaşı Ayarlar\'dan değiştirebilirsiniz.\n'
          '• Silme: "İlerlemeyi sıfırla" ve "Her şeyi sil" seçenekleri '
          'Ayarlar > Veri yönetimi altındadır.\n'
          'Diğer talepleriniz için veri sorumlusuna yukarıdaki iletişim '
          'bilgisinden ulaşabilirsiniz.',
    ),
    ConsentSection(
      '8. Rızayı geri çekme',
      'Rızanızı istediğiniz zaman Ayarlar > Rıza bölümünden geri '
          'çekebilirsiniz. Geri çektiğinizde bu cihazdaki tüm veriler '
          '("Silinenler" dahil) hemen ve kalıcı olarak silinir ve uygulama '
          'ilk kurulum ekranına döner.',
    ),
    ConsentSection(
      '9. Güvenlik',
      'Ebeveyn bölümü PIN ile korunur. PIN\'in kendisi saklanmaz; yalnızca '
          'geri döndürülemez özeti cihazın güvenli depolama alanında '
          'tutulur. Art arda yanlış PIN girilirse giriş kısa süre '
          'kilitlenir. Cihazınızı ekran kilidiyle korumanız verilerin '
          'güvenliğine katkı sağlar.',
    ),
    ConsentSection(
      '10. Metindeki değişiklikler',
      'İşlenen veriler veya işleme biçimi değişirse bu metin güncellenir '
          've uygulama devam etmeden önce sizden yeniden onay ister. '
          'Bu metnin sürümü: $version.',
    ),
  ];
}
