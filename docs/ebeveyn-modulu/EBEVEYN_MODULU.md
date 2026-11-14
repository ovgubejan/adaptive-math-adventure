# Ebeveyn modülü — nasıl çalışır

Bu belge modülün sahipleri içindir: ilk açılış kurulumu, rıza, rol seçimi,
PIN, ebeveyn paneli ve veri silme. Kararların nedenleri için
[KARARLAR.md](KARARLAR.md), tutulan veriler için
[VERI_ENVANTERI.md](VERI_ENVANTERI.md).

## Çalıştırma

```powershell
flutter pub get

# Normal: ilk açılışta kurulum ekranı gelir
flutter run -d chrome

# Geliştirici modu: kurulumu atlar (takma ad "Test Çocuk", PIN 0000)
flutter run -d chrome --dart-define=FAMILY_DEV_MODE=true
```

Geliştirici modu yalnızca debug derlemede çalışır; `flutter build ... --release`
çıktısında tamamen kapalıdır. Açıkken ekranın üstünde turuncu "GELİŞTİRİCİ
MODU" şeridi görünür ve rıza kaydı "test kaydı" olarak işaretlenir. Gerçek bir
kurulum yapılmışsa ona dokunmaz.

Kurulumu baştan denemek için: Ebeveyn → Ayarlar → Veri yönetimi → Her şeyi
sil. (Chrome'da site verisini temizlemek de aynı işi görür.)

## Doğrulama

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze        # yalnızca "deprecated_member_use" bilgi notları beklenir
flutter test
flutter build web --release
```

`flutter analyze` çıktısındaki `package:flutter/material.dart is deprecated`
notları Flutter 3.47 sonrası sürümlerde her dosya için çıkar; hata değildir ve
tüm projeyi ilgilendirir (ekipçe karar verilecek bir geçiş).

## Akış

```
Uygulama açılır
   │
   ├─ kayıt okunuyor ............... /family/loading
   ├─ kurulum yapılmamış ........... /family/setup
   │      karşılama → aydınlatma + rıza → çocuk profili → PIN → PIN tekrar
   ├─ rıza metni sürümü değişmiş ... /family/consent-update  (PIN ile yeniden onay)
   └─ hazır ........................ /family/role
          ├─ "Ben Ali'yim"   → /            (oyun ekranları)
          └─ "Ben ebeveynim" → /family/pin → /parent
                                              ├─ /parent/settings
                                              └─ /parent/settings/data
```

Yönlendirme tek bir işlevde toplanmıştır: `resolveFamilyRedirect`
(`lib/family/navigation/family_navigation.dart`). Kural sırası: yüklenmedi →
kurulum yok → rıza eski → rotanın erişim sınıfı.

## Dosya haritası

```
lib/family/
  family_module.dart          Uygulamaya bağlanan TEK nokta; yerel depoları kurar
  family_config.dart          Sabitler: yaş aralığı, PIN kuralları, saklama süresi
  application/
    family_controller.dart    Tek durum sahibi: kurulum, rol, PIN, silme, Silinenler
    parent_progress.dart      Panel hesapları (yalnızca okur) ve beceri adları
  content/
    consent_text.dart         Aydınlatma ve rıza metni + sürümü
    parent_tips.dart          Ebeveyn ipuçları
  data/
    family_repositories.dart  Depo ARAYÜZLERİ (sunucu için sözleşme)
    local_family_repositories.dart  Yerel uygulamalar
    key_value_store.dart      shared_preferences / güvenli depo / bellek
    pin_hasher.dart           PBKDF2-HMAC-SHA256
    child_data_module.dart    Silme kaydı: ChildDataModule, ChildDataRegistry
  domain/                     ChildProfile, ConsentRecord, TrashEntry
  navigation/
    family_navigation.dart    Rotalar, erişim tablosu, yönlendirme kuralı
  screens/                    Kurulum, rol seçimi, PIN, panel, ayarlar, veri yönetimi
  widgets/                    PIN tuş takımı, onay penceresi, grafik, ortak parçalar

test/family/
  repository_contracts.dart   Depo sözleşme testleri (sunucu ekibi de kullanır)
  family_test_harness.dart    Uygulamayı modülle birlikte pompalayan yardımcı
  route_access_test.dart      Her rota sınıflandırılmış mı + yönlendirme kuralları
  family_controller_test.dart Kurulum, PIN kilidi, silme, Silinenler, geliştirici modu
  family_flow_test.dart       Uygulamayı baştan sona gezen arayüz testleri
  small_screen_test.dart      Küçük telefon ekranında (360x640) taşma olmadığı
  ...
```

Ekranların görüntüsünü almak için (yazılar gerçek yazı tipiyle, düğme
yazıları test ortamı yüzünden kutu olarak görünür):

```powershell
flutter test test/family/small_screen_test.dart --update-goldens `
  --dart-define=FAMILY_SCREENSHOT_DIR=C:/gecici/ekranlar
```

## Mevcut dosyalara dokunduğumuz yerler

| Dosya | Değişiklik |
|---|---|
| `lib/main.dart` | `FamilyModule.local()..start()` ve `...family.providers` |
| `lib/app.dart` | `createAppRouter(family: FamilyNavigation.maybeOf(context))` |
| `lib/navigation/app_router.dart` | `family` parametresi: yönlendirme koruması, ana menüyü saran `wrapChildHome`, `...?family?.routes` |
| `pubspec.yaml` | `flutter_secure_storage`, `crypto` |

Başka hiçbir mevcut dosyaya ve mevcut teste dokunulmadı. `createAppRouter()`
`family` verilmeden çağrıldığında eskisi gibi çalışır.

Oyun verisini **yalnızca okuyoruz** (`SessionHistoryController.results` ve
`learningStates`). Silme ve geri yükleme, oyun depolarının yerel anahtarlarını
olduğu gibi kopyalayıp silerek yapılır; verinin iç yapısını bilmeyiz. Bu
anahtarların adı `FamilyModule.defaultChildDataModules` içinde yazılıdır ve
adlar değişirse `child_data_and_progress_test.dart` başarısız olur.

## Güvenlik notları (dürüst sınırlar)

- 4 haneli PIN yalnızca 10.000 olasılıktır. Özetleme PIN'in düz metin olarak
  durmasını önler; asıl koruma özetin güvenli depoda durması ve deneme
  sınırıdır. Bu, çocuğu ebeveyn bölümünden uzak tutmak için yeterlidir; cihaza
  tam erişimi olan birine karşı güçlü bir koruma değildir.
- Güvenli depo yalnızca Android'de (Keystore) gerçekten güvenlidir. Chrome'da
  tarayıcı deposu kullanılır ve paket yalnızca güvenli bağlamda (`localhost`
  veya HTTPS) çalışır; `flutter run -d chrome` bunu sağlar.
- PIN kilidi cihazın saatine bakar; saat ileri alınırsa kilit erken açılır.
- PIN unutulursa kurtarma yoktur; uygulama verisini temizlemek gerekir.

## Android'e geçerken yapılacaklar

Depoda şu an yalnızca `web/` klasörü var; Android platform dosyaları henüz
oluşturulmamış. Oluşturulduğunda:

1. `flutter create --platforms=android .`
2. `android/app/src/main/AndroidManifest.xml` içinde `<application>` etiketine
   `android:allowBackup="false"` ekleyin. Eklenmezse Android uygulama verisini
   kullanıcının Google hesabına yedekleyebilir ve aydınlatma metnindeki "veri
   yalnızca bu cihazda durur" cümlesi yanlış olur.
3. `flutter_secure_storage` paketi (11.2.0) Android'de en az `minSdk 24`
   ister; `android/app/build.gradle` içindeki değer bundan düşükse yükseltin.
4. Gerçek bir cihazda veya emülatörde şu turu elle yapın: kurulum → çocuk
   olarak bir oturum oyna → ebeveyn paneli → ilerlemeyi sıfırla → geri yükle →
   her şeyi sil. Geri tuşunun her ekranda beklenen yere döndüğünü kontrol edin.
5. Manifest'e reklam kimliği, konum, kamera veya mikrofon izni eklenmediğini
   doğrulayın.

## Sunucu eklendiğinde bize düşebilecekler

Hangisinin gerçekleşeceği sunucu tasarımına bağlı; hepsi "olabilir" listesidir.

| Konu | Ne gerekebilir | Kimin işi |
|---|---|---|
| Hesap ve giriş | Ebeveyn için e-posta/şifre girişi; kurulum akışına bir adım; PIN'in hesapla ilişkisi (PIN cihaz kilidi olarak kalabilir) | Ortak |
| PIN kurtarma | Hesap doğrulamasıyla PIN sıfırlama ekranı | Biz |
| İlk eşitleme | Cihazdaki profil, rıza ve ilerlemenin sunucuya taşınması; çakışmada hangisinin geçerli olacağı | Ortak |
| Rıza kaydı | Rızanın sunucuya da yazılması; `ConsentRecord.withdrawnAt` alanının kullanılması | Biz + sunucu |
| Aydınlatma metni | Metne "veri sunucuda saklanır", sağlayıcı ve ülke bilgisinin eklenmesi; yurt dışındaysa aktarım hükümleri; `ConsentText.version` artışı (herkesten yeniden onay) | Biz (metin), uzman incelemesi |
| Veri envanteri | Sunucuda tutulan her veri için satır | Biz + sunucu |
| Silme | "Her şeyi sil" ve rıza geri çekmenin sunucudaki veriyi de silmesi; Silinenler'in 30 günlük süresinin sunucuda da uygulanması | Sunucu (uygulama), biz (ekran ve metin) |
| Çevrimdışı | Bağlantı yokken ekranların ne göstereceği; silme isteği çevrimdışı verilirse kuyruğa alınması | Ortak |
| E-posta | E-posta toplanırsa: envanter, metin, doğrulama ekranı | Biz |
| Çoklu cihaz | Aynı çocuğun iki cihazda oynaması; panelin iki cihazın verisini birlikte göstermesi | Ortak |
| Çoklu çocuk | İstenirse: profil seçimi, ilerlemenin çocuğa göre ayrılması (şu an tek çocuk varsayılıyor) | Ortak, büyük iş |
| Testler | Sunucu depoları için sözleşme testlerinin çalıştırılması | Sunucu |

## Bilinen eksikler

- Android'de ve gerçek bir tarayıcıda elle uçtan uca deneme yapılmadı;
  doğrulama otomatik testlerle ve web derlemesiyle yapıldı.
- Rıza metni taslaktır, veri sorumlusu alanı boştur.
- PIN kurtarma yoktur.
- Ebeveyn ekranları Türkçe, oyun ekranları İngilizcedir.
- Beceri adlarının Türkçesi `SkillLabels` içinde elle tutulur; yeni beceri
  eklenince oraya da eklenmelidir (eklenmezse etiket ham hâliyle görünür).
