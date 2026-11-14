# Sunucu ekibi için kılavuz

Uygulama şu an tamamen cihazda çalışır. Bu belge, sunucu (hesap, eşitleme,
bulut depolama) eklerken uygulamanın geri kalanını bozmamak ve çocuk verisiyle
ilgili verdiğimiz sözleri tutmak için uymanız gerekenleri anlatır.

## Önce şunu bilin: sunucu, verdiğimiz sözü değiştirir

Ebeveyne gösterilen aydınlatma metni şu an "veriler yalnızca bu cihazda durur,
hiçbir yere aktarılmaz" diyor. Sunucuya **tek bir alan** bile göndermeye
başladığınız an bu cümle yanlış olur. Bu yüzden sıra şöyle olmalı:

1. Hangi verinin, hangi sağlayıcıda, hangi ülkede duracağına karar verin.
2. [VERI_ENVANTERI.md](VERI_ENVANTERI.md) tablosunu güncelleyin.
3. Aydınlatma metnini (`lib/family/content/consent_text.dart`) güncelleyin ve
   `ConsentText.version` değerini değiştirin. Uygulama her ebeveynden yeniden
   onay ister; onaylamayanın verisi sunucuya gitmemelidir.
4. Sunucu yurt dışındaysa bunun ayrı hukuki sonuçları vardır (yurt dışına
   aktarım). Metni bir uzmana gösterin.
5. Kodu ondan sonra birleştirin.

Firebase gibi hazır servisler çoğu zaman yurt dışı sunucu ve otomatik analiz
demektir; seçmeden önce ekipçe konuşun ve analiz/reklam bileşenlerini kapatın.

## Depo arayüzleri: sözleşme

Uygulama depolara doğrudan değil arayüzler üzerinden erişir.

| Arayüz | Dosya | Şu anki uygulama |
|---|---|---|
| `SessionResultPersistence` | `lib/persistence/session_result_persistence.dart` | `LocalSessionResultPersistence` |
| `AdaptiveProgressRepository` | `lib/persistence/adaptive_progress_repository.dart` | `LocalAdaptiveProgressRepository` |
| `ChildProfileRepository` | `lib/family/data/family_repositories.dart` | `LocalChildProfileRepository` |
| `ConsentRepository` | aynı dosya | `LocalConsentRepository` |
| `ParentPinRepository` | aynı dosya | `LocalParentPinRepository` |
| `TrashRepository` | aynı dosya | `LocalTrashRepository` |
| `ChildDataModule` | `lib/family/data/child_data_module.dart` | `StorageKeysDataModule` |

Kurallar:

- **Arayüz imzalarını değiştirmeyin.** Aynı arayüzü uygulayan yeni bir sınıf
  yazın (ör. `RemoteChildProfileRepository`). İmza değişmesi şartsa önce
  arayüzün sahibiyle konuşun.
- **Yerel uygulamaları silmeyin.** Çevrimdışı çalışma ve önbellek için kalırlar.
  Önerilen yapı: önce yerele yazan, sonra sunucuyla eşitleyen bir sarmalayıcı.
- **Bağlama noktası tektir:** ebeveyn modülü için `FamilyModule.local(...)`
  (`lib/family/family_module.dart`). Sunucu sürümü için yanına
  `FamilyModule.remote(...)` gibi ikinci bir kurucu ekleyin; ekranlara
  dokunmanız gerekmez.
- **Sözleşme testlerini çalıştırın.** `test/family/repository_contracts.dart`
  her arayüz için ortak testler içerir. Yeni sınıfınızı
  `test/family/repository_contract_test.dart` içine ekleyin:

  ```dart
  runChildProfileRepositoryContract(
    'sunucu',
    create: () => RemoteChildProfileRepository(sahteSunucu),
    reset: () async => sahteSunucu.temizle(),
  );
  ```

  Testler geçiyorsa uygulamanın geri kalanı deponuzla çalışır. Testlerde
  gerçek sunucuya bağlanmayın; sahte (bellek içi) bir sunucu kullanın.

## Davranış beklentileri

Arayüzlerin yorum satırlarında yazanlara ek olarak:

- `load()` kayıt yoksa `null` (veya boş liste) döner, hata fırlatmaz.
- Okunamayan veya bozuk kayıt çökmeye değil "kayıt yok" sonucuna yol açar.
- Kayıtlarda `schemaVersion` alanı vardır. Tanımadığınız alanları **silmeyin**;
  modeller (`ChildProfile.extra`, `ConsentRecord.extra`) bilinmeyen alanları
  okuyup geri yazar. Sunucuya özel alanlarınızı (ör. `serverId`, `syncedAt`)
  böyle ekleyebilirsiniz.
- Oturum sonuçlarında `sessionId` tekildir ve aynı oturumu iki kez kaydetmek
  tek kayıt bırakır. Değerlendirme motoru işlenmiş oturumu yeniden işlemez
  (`hasProcessed`). Eşitlemede bu özelliği koruyun.
- Yazma başarısız olursa hata fırlatın; sessizce yutmayın. Ekranlar hatayı
  kullanıcıya gösterir.

## Silme ve rıza: sunucuda da geçerli olmalı

Ebeveynin uygulamadaki dört işlemi sunucuda da aynı sonucu vermelidir:

| Ebeveynin işlemi | Cihazda olan | Sunucuda olması gereken |
|---|---|---|
| İlerlemeyi sıfırla | Oyun verisi Silinenler'e taşınır (30 gün) | Sunucudaki oyun verisi de silinir veya aynı 30 günlük süreyle saklanır |
| Silinenlerden geri yükle | Veri geri gelir; o anki veri Silinenler'e geçer | Sunucu aynı duruma gelir |
| Şimdi kalıcı olarak sil | Kayıt hemen yok olur | Sunucudaki kopya da hemen yok olur |
| Her şeyi sil / Rızayı geri çek | Profil, PIN, rıza hemen silinir; rıza geri çekmede Silinenler de | Hesaba bağlı **tüm** çocuk verisi silinir; yedeklerdeki kopyalar için süre belirlenir ve metne yazılır |

Bunları sağlamanın yolu: sunucuda tuttuğunuz çocuk verisi için bir
`ChildDataModule` yazıp `FamilyModule` içindeki listeye eklemek. `clear()`
sunucudaki veriyi de silmelidir. Silme isteği çevrimdışıyken verilirse kuyruğa
alın ve bağlantı gelince **mutlaka** gönderin; ebeveyne "silindi" dedikten
sonra verinin sunucuda kalması kabul edilemez.

Rıza geri çekildiğinde `ConsentRecord.withdrawnAt` alanı bunun için modelde
hazır durur. Rıza kaydının kendisini (kim, ne zaman, hangi metne onay verdi)
ispat amacıyla sunucuda tutup tutmayacağınız hukuki bir sorudur; uzmana sorun.

## Güvenlik

- Sunucu adresi dışında hiçbir gizli bilgiyi (API anahtarı, şifre, servis
  hesabı dosyası) uygulamaya veya depoya koymayın. Uygulama paketi açılıp
  okunabilir. `.gitignore` içinde `.env`, `credentials.json`,
  `service-account*.json` zaten hariç tutuluyor; öyle kalsın.
- Yalnızca HTTPS kullanın.
- Oturum belirteçlerini (token) `shared_preferences` içinde değil güvenli
  depoda saklayın: `SecureKeyValueStore` (`lib/family/data/key_value_store.dart`).
  Anahtar adlarınız `family_` ile başlamasın; o önek ebeveyn modülüne aittir.
- Ebeveyn PIN'inin özetini sunucuya göndermeyin. PIN cihazdaki ebeveyn
  kapısıdır; hesap şifresi ayrı bir şeydir. 4 haneli bir PIN'in özeti sunucuda
  kolayca kırılır.
- Sunucu tarafında her istek, verinin o hesaba ait olduğunu doğrulamalıdır;
  bir ebeveyn başka bir çocuğun verisini kimlik değiştirerek okuyamamalıdır.
- Sunucu günlüklerine (log) çocuk verisi yazmayın.

## Çevrimdışı ve çakışma

- Uygulama internet olmadan oynanabilmelidir. Oturum bitince sonuç önce
  yerele yazılır; eşitleme sonradan yapılır.
- Aynı verinin cihazda ve sunucuda farklı olması durumunda hangisinin geçerli
  olacağına baştan karar verin ve belgeleyin. Oturum sonuçları yalnızca eklenen
  kayıtlardır (çakışmaz); öğrenme ilerlemesi seviye başına tek kayıttır
  (çakışabilir).
- İlk eşitlemede cihazdaki mevcut veriyi kaybetmeyin.

## Ekleme yaparken dokunmamanız gerekenler

- `resolveFamilyRedirect` ve `FamilyRoutes.access` (yönlendirme koruması).
  Giriş ekranı ekleyecekseniz yeni rotanızı tabloya ekleyin; kuralı ebeveyn
  modülü sahipleriyle birlikte değiştirin.
- Kurulumdaki sıra: rıza onaylanmadan hiçbir veri kaydedilmez ve hiçbir veri
  sunucuya gönderilmez.
- Geliştirici modunun yalnızca debug derlemede çalışması. Geliştirici modunda
  oluşan kayıt `isDevSeed: true` taşır; **gerçek rıza değildir** ve sunucuya
  gerçek rıza olarak gönderilmemelidir.

## Birleştirmeden önce

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Ek olarak elle: internet kapalıyken kurulum ve bir oturum; sonra internet
açılınca eşitleme; "her şeyi sil"den sonra sunucuda veri kalmadığının kontrolü.
