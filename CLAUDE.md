# Adaptive Math Adventure — yapay zekâ asistanları için giriş

Bu dosyayı Claude Code otomatik okur. Başka bir yapay zekâ aracı
kullanıyorsanız içeriğini oturumun başında araca verin.

## Proje

4–8 yaş çocuklar için uyarlanabilir matematik oyunu. Flutter ile yazılıyor;
hedef **Android**, geliştirme ve hızlı deneme ortamı **Chrome**. Okul bitirme
projesi; dört kişilik ekip. Sunucu henüz yok, her şey cihazda saklanıyor.

- Oyun tarafı: `lib/content/`, `lib/domain/`, `lib/session/`, `lib/mechanics/`,
  `lib/presentation/`, `lib/screens/`, `lib/persistence/`, `lib/progress/`.
  Belgeler: `docs/architecture.md`, `docs/INTEGRATION_GUIDE.md`.
- Ebeveyn modülü (ilk açılış kurulumu, KVKK rızası, rol seçimi, PIN, ebeveyn
  paneli, veri silme): `lib/family/`. Belgeler: `docs/ebeveyn-modulu/`.

## Komutlar

```powershell
flutter pub get
flutter run -d chrome --dart-define=FAMILY_DEV_MODE=true   # kurulumu atlar, PIN 0000
flutter run -d chrome                                       # gerçek ilk açılış akışı

dart format --output=none --set-exit-if-changed lib test
flutter analyze     # "package:flutter/material.dart is deprecated" notları beklenir
flutter test
flutter build web --release
```

Bir işi bitmiş saymadan önce `flutter analyze` ve `flutter test` çalıştır ve
sonucu olduğu gibi bildir.

## Değiştirmeden önce bilmen gereken kurallar

Bu kurallar çocukların kişisel verisini korumak için var. Çoğu bir testle
zorunlu kılınmış durumda; test başarısız olursa **testi silme veya atlama**,
nedenini düzelt.

1. **Yeni rota = sınıflandırma.** `lib/navigation/app_router.dart` içine rota
   eklersen desenini `lib/family/navigation/family_navigation.dart` →
   `FamilyRoutes.access` tablosuna da ekle. Çocuğun oynadığı ekran
   `RouteAccess.child`; çocuğun ilerlemesini veya ebeveyne ait bilgiyi gösteren
   ekran `RouteAccess.parent` ve yolu `/parent/...`.
   (Test: `test/family/route_access_test.dart`)

2. **Çocuk hakkında yeni veri = üç adım.** (a) `FamilyModule.defaultChildDataModules`
   listesine silme kaydı, (b) `docs/ebeveyn-modulu/VERI_ENVANTERI.md` satırı,
   (c) `lib/family/content/consent_text.dart` metni + `ConsentText.version`
   değişikliği. Kullanıcıya bunu söyle; (c)'yi sormadan yapma.
   (Test: `test/family/child_data_and_progress_test.dart`)

3. **Dışarı veri gönderen paket ekleme.** Reklam, analiz, çökme raporlama,
   Firebase veya ağ isteği yapan bir paket eklemeden önce dur ve kullanıcıya
   sor. Mikrofon, kamera, konum izni için de aynısı. Aydınlatma metni "veri
   cihazdan çıkmaz" diyor.

4. **`family_` öneki ebeveyn modülünündür.** Başka modüllerde bu önekle
   depolama anahtarı kullanma. Oyun depolarının anahtar adını değiştirirsen
   `FamilyModule.defaultChildDataModules` içinde de güncelle.

5. **Yönlendirme korumasını gevşetme.** `resolveFamilyRedirect` içindeki sıra
   (yüklenmedi → kurulum yok → rıza eski → erişim sınıfı) ve "rıza onaylanmadan
   veri kaydedilmez" kuralı değişmez. Değişmesi gerekiyorsa önce kullanıcıya sor.

6. **Depo arayüzlerinin imzasını değiştirme.** `lib/persistence/*` ve
   `lib/family/data/family_repositories.dart` içindeki arayüzler sözleşmedir.
   Yeni davranış için aynı arayüzü uygulayan yeni sınıf yaz ve
   `test/family/repository_contracts.dart` testlerinden geçir.

7. **Geliştirici modu yalnızca debug'da çalışır.** `kDebugMode` koşulunu
   kaldırma; geliştirici modunun oluşturduğu rıza kaydı gerçek rıza değildir.

8. **Aydınlatma metni uygulamanın gerçekte yaptığını yazmalı.** Davranışı
   değiştirdiysen (ne saklanıyor, nerede, ne kadar süre) metnin hâlâ doğru olup
   olmadığını kontrol et ve kullanıcıya bildir. Metin taslaktır; "KVKK'ya
   uygundur" diye bir iddia yazma.

9. **Başkasının alanına sormadan girme.** Oyun tarafında çalışıyorsan
   `lib/family/` altını, ebeveyn modülünde çalışıyorsan oyun dosyalarını
   değiştirmen gerekiyorsa önce kullanıcıya söyle. İki tarafın buluştuğu
   dosyalar: `lib/main.dart`, `lib/app.dart`, `lib/navigation/app_router.dart`,
   `pubspec.yaml`; bunlarda yalnızca gerekli satırı değiştir, dosyayı baştan
   yazma.

## Test yazarken

- Uygulamanın tamamını pompalayan testlerde `test/family/family_test_harness.dart`
  içindeki `pumpFamilyApp` kullan (`startAs: FamilyTestStart.child` ana menüden
  başlatır).
- Maskotun bulunduğu ekranlarda `pumpAndSettle` bitmez; `pumpFrames(tester)`
  kullan.
- `createAppRouter()` ebeveyn modülü verilmeden çağrılırsa koruma olmadan
  çalışır; tek ekranı sınayan testler için bu yeterlidir.

## Git

- Her iş kendi dalında yapılır; ana dal `prototype-v1`.
- Kullanıcı açıkça istemedikçe `push` etme ve dalları birleştirme.
- `build/`, `.dart_tool/`, gizli anahtar ve kimlik dosyalarını commit etme.

## Hangi belge ne zaman

| Yapacağın iş | Önce oku |
|---|---|
| Seviye, soru, oyun, ekran eklemek | `docs/ebeveyn-modulu/OYUN_EKIBI_KILAVUZU.md`, `docs/INTEGRATION_GUIDE.md` |
| Sunucu, hesap, eşitleme eklemek | `docs/ebeveyn-modulu/SUNUCU_EKIBI_KILAVUZU.md` |
| Ebeveyn modülünde değişiklik | `docs/ebeveyn-modulu/EBEVEYN_MODULU.md`, `docs/ebeveyn-modulu/KARARLAR.md` |
| Saklanan veriyi değiştirmek | `docs/ebeveyn-modulu/VERI_ENVANTERI.md`, `docs/ebeveyn-modulu/AYDINLATMA_VE_RIZA_METNI.md` |
