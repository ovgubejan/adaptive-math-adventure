# Veri envanteri

Uygulamanın sakladığı her kişisel verinin listesi. **Bu belge, koddaki
aydınlatma metni (`lib/family/content/consent_text.dart`) ve gerçek davranış
her zaman aynı şeyi söylemelidir.**

> **Kural:** Çocuk veya ebeveyn hakkında yeni bir veri saklamaya
> başlıyorsanız, kodu birleştirmeden önce:
> 1. Bu tabloya satır ekleyin.
> 2. Aydınlatma metnini güncelleyin ve `ConsentText.version` değerini
>    değiştirin (uygulama ebeveynden yeniden onay ister).
> 3. Veriyi silme kaydına ekleyin
>    ([OYUN_EKIBI_KILAVUZU.md](OYUN_EKIBI_KILAVUZU.md) → "Yeni veri saklamak").

## Saklanan veriler

| Veri | İçerik | Kimin | Nerede | Anahtar | Ne zaman silinir |
|---|---|---|---|---|---|
| Çocuk profili | Takma ad, yaş (4–8), oluşturma/güncelleme zamanı | Ebeveyn modülü | Yerel depo (`shared_preferences`) | `family_child_profile_v1` | "Her şeyi sil" veya rıza geri çekilince hemen |
| Rıza kaydı | Onaylanan metnin sürümü, onay zamanı, test kaydı mı | Ebeveyn modülü | Yerel depo | `family_consent_v1` | "Her şeyi sil" veya rıza geri çekilince hemen |
| Ebeveyn PIN'i | PIN'in tuzlu özeti (PBKDF2-HMAC-SHA256), tuz, tur sayısı. **PIN'in kendisi saklanmaz.** | Ebeveyn modülü | Güvenli depo (`flutter_secure_storage`) | `family_parent_pin_v1` | "Her şeyi sil" veya rıza geri çekilince hemen |
| PIN deneme durumu | Yanlış deneme sayısı, kilit bitiş zamanı | Ebeveyn modülü | Güvenli depo | `family_pin_attempts_v1` | Doğru PIN girilince; ayrıca "Her şeyi sil" |
| Oturum geçmişi | Her oturum için: seviye, başlangıç/bitiş zamanı, soru kimliği, beceri etiketi, zorluk, verilen cevaplar, doğru/yanlış, cevap süresi, ipucu kullanımı | Oyun ekibi | Yerel depo | `adaptiveMathAdventure.sessionResults.v1` | "İlerlemeyi sıfırla" / "Her şeyi sil" → Silinenler'e; rıza geri çekilince hemen |
| Öğrenme ilerlemesi | Seviye bazında ustalık puanı, önerilen zorluk, beceri istatistikleri, eğilim, son sorulan sorular | Oyun ekibi | Yerel depo | `adaptiveMathAdventure.learningProgress.v1` | Oturum geçmişiyle aynı |
| Silinenler | Silinen oturum geçmişi ve öğrenme ilerlemesinin kopyası, silinme zamanı, sebep, o andaki takma ad | Ebeveyn modülü | Yerel depo | `family_trash_v1` | Silinmeden 30 gün sonra (uygulama açılırken); "Şimdi kalıcı sil"; rıza geri çekilince hemen |

## Saklanmayan veriler

Gerçek ad, soyad, doğum tarihi, e-posta, telefon, adres, fotoğraf, ses,
konum, cihaz kimliği, reklam kimliği, rehber. Uygulama mikrofon, kamera ve
konum izni istemez.

## Verinin gittiği yerler

**Hiçbir yere.** Uygulamada sunucu, reklam, analiz veya çökme raporlama
paketi yoktur; veri cihazdan çıkmaz.

Dikkat edilmesi gereken iki durum:

- **Android yedeklemesi:** Android varsayılan olarak uygulama verisini
  kullanıcının Google hesabına yedekleyebilir. Bu kapatılmazsa "veri yalnızca
  cihazda durur" cümlesi yanlış olur. Android platformu eklenirken
  kapatılmalıdır (bkz. [EBEVEYN_MODULU.md](EBEVEYN_MODULU.md) → "Android'e
  geçerken").
- **Chrome'da deneme:** Veriler tarayıcının kendi deposunda durur. Güvenli
  depo tarayıcıda Android'deki kadar güvenli değildir. Web yalnızca geliştirme
  ortamıdır.

## Saklama süresi

- Veriler ebeveyn silene veya uygulama kaldırılana kadar saklanır.
- Silinen ilerleme 30 gün Silinenler'de kalır. Süre kontrolü yalnızca
  uygulama açılırken ve Silinenler ekranı açılırken yapılır; uygulama hiç
  açılmazsa kayıt, açılana kadar cihazda durur.

## Bu envanter nasıl korunuyor?

- `test/family/child_data_and_progress_test.dart` → "oyunun yazdığı her yerel
  anahtar bir veri modülüne kayıtlıdır": oyun depolarının yazdığı anahtarlar
  silme kaydında değilse başarısız olur.
- Debug derlemede uygulama açılırken, kayıtlı olmayan depolama anahtarı varsa
  konsola `[family] UYARI: Kayıtlı olmayan yerel depolama anahtarları ...`
  yazılır.
- "Her şeyi sil" kayıtsız anahtarları da siler.

Bu korumalar yalnızca **yerel depoya yazılan** veriyi görür. Dosyaya,
veritabanına veya ağa yazılan veriyi göremezler; onlar için bu tabloyu elle
güncellemek gerekir.
