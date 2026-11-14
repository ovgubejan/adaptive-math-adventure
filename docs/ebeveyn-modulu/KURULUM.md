# Kurulum — Flutter'ı hiç indirmemiş ekip arkadaşları için

Bu belge Windows içindir. Uygulamayı şimdilik **Chrome'da** çalıştırıyoruz;
Android tarafı (Android Studio, emülatör) şimdilik gerekmez.

## 1. Gerekli programlar

- **Git** ve **GitHub Desktop** (projeyi ve dalı indirmek için).
- **Google Chrome**.
- **VS Code** ve içine **Flutter** eklentisi (Dart eklentisini kendisi kurar).

## 2. Flutter SDK'yı kurmak

Resmi kurulum sayfası: <https://docs.flutter.dev/get-started/install>

- **Kolay yol:** VS Code'da `Ctrl+Shift+P` → "Flutter: New Project". Eklenti
  Flutter'ı indirmeyi teklif eder.
- **Elle kurulum:** SDK'yı zip olarak indirip `C:\src\flutter` gibi bir
  klasöre çıkarın (`Program Files` altına **değil**, izin sorunu çıkar). Sonra
  `C:\src\flutter\bin` klasörünü Windows `Path` ortam değişkenine ekleyin.
- **Sürüm:** Güncel kararlı (stable) sürümü kurun. Proje en az Dart 3.12
  ister (`pubspec.yaml`). Ekipte Flutter 3.50 (Dart 3.14) ile çalışıldı.

## 3. Kurulumu kontrol etmek

Yeni bir terminal açıp:

```powershell
flutter doctor
```

Flutter ve Chrome satırlarında yeşil tik yeterlidir. **Android toolchain**,
**Android Studio** ve **Visual Studio** satırlarındaki kırmızı çarpılar şimdilik
önemli değil.

## 4. Projeyi indirmek ve çalıştırmak

1. GitHub Desktop'ta depoyu klonlayın (`ovgubejan/adaptive-math-adventure`).
2. "Current Branch" kutusundan çalışacağınız dala geçin (ebeveyn modülü için
   `feature/ebeveyn-kvkk`).
3. Proje klasörünü VS Code'da açın, terminalde:

   ```powershell
   flutter pub get
   flutter run -d chrome --dart-define=FAMILY_DEV_MODE=true
   ```

   İlk çalıştırma birkaç dakika sürebilir. Geliştirici modu ebeveyn kurulumunu
   test verisiyle atlar (ebeveyn PIN'i `0000`). İlk açılış kurulumunu görmek
   için `--dart-define=...` kısmını çıkarın.
4. Testler: `flutter test`

Bundan sonrası için: [EBEVEYN_MODULU.md](EBEVEYN_MODULU.md),
[OYUN_EKIBI_KILAVUZU.md](OYUN_EKIBI_KILAVUZU.md),
[SUNUCU_EKIBI_KILAVUZU.md](SUNUCU_EKIBI_KILAVUZU.md).

## Takıldığınızda

| Belirti | Çözüm |
|---|---|
| `flutter` komutu bulunamıyor | `Path`'e ekledikten sonra terminali (gerekirse VS Code'u) kapatıp açın. |
| `flutter pub get` sürüm uyuşmazlığı hatası veriyor | Flutter eski; `flutter upgrade` çalıştırın. |
| `flutter doctor` Chrome'u bulamıyor | Chrome'u kurun; kuruluysa `CHROME_EXECUTABLE` ortam değişkenine `chrome.exe` yolunu verin. |
| Analiz çıktısında "package:flutter/material.dart is deprecated" | Hata değil, bilgi notu; tüm projede çıkar. |
| Kurulum ekranını tekrar görmek istiyorum | Geliştirici modu olmadan çalıştırın; ardından Ebeveyn → Ayarlar → Veri yönetimi → Her şeyi sil. |
| Çalışmayan bir test | `git status` ile dalınızı kontrol edin; kendi değişikliğiniz yoksa ekibe haber verin. |

## Android'de denemek (ileride)

Android Studio, Android SDK ve bir emülatör ya da USB ile bağlı telefon
gerekir. Depoda şu an `android/` klasörü yok; oluşturma ve yedekleme ayarı için
[EBEVEYN_MODULU.md](EBEVEYN_MODULU.md) → "Android'e geçerken yapılacaklar".
