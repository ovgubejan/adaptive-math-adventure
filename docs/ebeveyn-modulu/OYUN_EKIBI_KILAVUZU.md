# Oyun ve seviye ekibi için kılavuz

Yeni seviye, oyun, ekran veya veri eklerken ebeveyn modülünü (kurulum, rıza,
PIN, ebeveyn paneli, veri silme) bozmamak için bilmeniz gerekenler. Çoğu iş
için **hiçbir şey yapmanız gerekmez**; aşağıdaki dört durumda birer küçük adım
var.

## Uygulamayı çalıştırmak

Uygulama artık ilk açılışta ebeveyn kurulumu ister. Her seferinde kurulum
yapmamak için geliştirici modunu kullanın:

```powershell
flutter run -d chrome --dart-define=FAMILY_DEV_MODE=true
```

Kurulum atlanır, rol seçimi ekranı açılır. "Ben Test Çocuk'um" düğmesi sizi
eskisi gibi ana menüye götürür. Ebeveyn bölümünün PIN'i `0000`.

## Hiçbir şey yapmanız gerekmeyen işler

- Mevcut bir seviyeye soru eklemek, soruları değiştirmek.
- Mevcut ekranların görünümünü, maskotu, temaları değiştirmek.
- Değerlendirme ve oturum planlama kurallarını değiştirmek.
- Tek bir ekranı veya `createAppRouter()`'ı test eden mevcut testler.

## 1. Yeni bir ekran (rota) ekliyorsanız

`lib/navigation/app_router.dart` içine yeni bir `GoRoute` eklediğinizde,
rotanın desenini `lib/family/navigation/family_navigation.dart` içindeki
`FamilyRoutes.access` tablosuna da ekleyin:

```dart
'/yeni-oyun/:id': RouteAccess.child,
```

- Çocuğun oynadığı ekran → `RouteAccess.child`
- Çocuğun ilerlemesini, ayarları veya ebeveyne ait herhangi bir bilgiyi
  gösteren ekran → `RouteAccess.parent` **ve** yolu `/parent/...` ile başlamalı
  (bunu ebeveyn modülü sahipleriyle konuşun).

Eklemezseniz `test/family/route_access_test.dart` başarısız olur ve rota
çalışırken açılmaz (rol seçimine atar). Bu bilinçli bir güvenlik: unutulan bir
ekran ebeveyn kapısını atlayamasın.

## 2. Çocuk hakkında yeni bir veri saklıyorsanız

Örnek: yeni oyunun yüksek skoru, rozetler, çocuğun seçtiği tema.

1. **Silme kaydına ekleyin.** `lib/family/family_module.dart` →
   `defaultChildDataModules` listesine bir satır:

   ```dart
   StorageKeysDataModule(
     id: 'yeniOyunSkorlari',            // kalıcı kimlik, sonradan değiştirmeyin
     displayName: 'Yeni oyun skorları',
     keys: {'adaptiveMathAdventure.yeniOyun.v1'},
     store: store,
   ),
   ```

   Böylece ebeveyn "ilerlemeyi sıfırla" dediğinde veriniz silinir, 30 gün
   Silinenler'de durur ve geri yüklenebilir. Veriniz `shared_preferences`
   dışında bir yerdeyse (dosya, veritabanı, sunucu) `ChildDataModule`
   arayüzünü kendiniz uygulayın: `exportSnapshot`, `clear`, `restoreSnapshot`.

2. **Envantere ekleyin.** [VERI_ENVANTERI.md](VERI_ENVANTERI.md) tablosuna
   satır.

3. **Aydınlatma metnini güncelleyin.** `lib/family/content/consent_text.dart`
   içinde "Hangi veriler işlenir?" bölümüne ekleyin ve `ConsentText.version`
   değerini değiştirin. Uygulama ebeveynden yeniden onay ister. Bunu ebeveyn
   modülü sahipleriyle birlikte yapın.

Eklemezseniz ne olur: debug derlemede uygulama açılırken konsolda
`[family] UYARI: Kayıtlı olmayan yerel depolama anahtarları` görürsünüz.
"Her şeyi sil" verinizi yine de siler, ama "ilerlemeyi sıfırla" silmez ve
geri yükleme çalışmaz.

**Çocuğa ait olmayan** veriler (ör. ses açık/kapalı ayarı) için silme kaydı
şart değildir; ama uyarıyı susturmak ve "her şeyi sil"de ne olduğunu belli
etmek için yine de kaydetmeniz iyi olur.

## 3. Depolama anahtarı veya kayıt biçimi değiştiriyorsanız

- `LocalSessionResultPersistence` veya `LocalAdaptiveProgressRepository`
  içindeki `_storageKey` değerini değiştirirseniz (ör. `.v2`), aynı anahtarı
  `FamilyModule.defaultChildDataModules` içinde de güncelleyin.
  `test/family/child_data_and_progress_test.dart` bunu unutursanız başarısız
  olur.
- `SessionResult` veya `AdaptiveProgressState` alanlarını değiştirirseniz
  ebeveyn paneli etkilenebilir; panel `results`, `learningStates`,
  `correctCount`, `totalQuestions`, `evidence[].skillTag`, `attempts[].hintUsed`,
  `mastery`, `currentDifficulty`, `latestTrend`, `latestFocusSkill` alanlarını
  okur. `flutter test` çalıştırın; derleme hatası çıkarsa
  `lib/family/application/parent_progress.dart` güncellenmelidir.
- Kayıt biçimini geriye uyumsuz değiştirirseniz, Silinenler'deki eski kayıtlar
  geri yüklendiğinde eski biçimde geri gelir. Eski biçimi okuyabilen bir geçiş
  yazın ya da değişiklikten önce bunu ekipçe konuşun.
- `family_` ile başlayan depolama anahtarı kullanmayın; o önek ebeveyn
  modülüne aittir.

## 4. Yeni bir paket ekliyorsanız

Reklam, analiz (analytics), çökme raporlama, Firebase veya kullanıcı verisini
dışarı gönderen herhangi bir paketi **eklemeden önce ekiple konuşun**.
Bu tür paketler çoğu zaman yalnızca eklenmekle veri göndermeye başlar;
aydınlatma metnindeki "veri cihazdan çıkmaz" cümlesi yanlış olur ve çocuk
uygulamaları için mağaza kuralları ihlal edilebilir. Aynı şey mikrofon, kamera
ve konum izinleri için de geçerli.

## Yeni beceri etiketi (skillTag) eklerken

Ebeveyn panelinde beceriler Türkçe adıyla gösterilir. Yeni bir `skillTag`
eklediğinizde `lib/family/application/parent_progress.dart` → `SkillLabels`
içine Türkçe adını (ve isterseniz evde yapılabilecek küçük bir etkinlik
önerisini) ekleyin. Eklemezseniz etiket olduğu gibi görünür; uygulama bozulmaz.

## Yaş aralığı

Hedef yaş 4–8'dir (`FamilyConfig`). 4 yaşındaki çocuk okuyamaz: oyun
ekranlarındaki yazılı yönergelerin görsel veya sesli bir karşılığı olması
gerekir. Rol seçimi ekranında çocuk düğmesi bu yüzden büyük ve simgelidir.

## Uygulamanın tamamını test etmek

Uygulamayı yönlendirici ve ebeveyn modülüyle birlikte pompalayan bir test
yazacaksanız hazır yardımcıyı kullanın:

```dart
import 'family/family_test_harness.dart';

testWidgets('yeni oyun ana menüden açılır', (tester) async {
  SharedPreferences.setMockInitialValues({});
  await pumpFamilyApp(tester, startAs: FamilyTestStart.child);
  // Buradan itibaren ana menüdesiniz.
});
```

Rol seçimi ekranında sürekli hareket eden maskot olduğu için bu testlerde
`pumpAndSettle` yerine `pumpFrames(tester)` kullanın.

## Birleştirmeden önce

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Üçü de temizse ebeveyn modülünü bozmadınız demektir. `test/family/` altında bir
test başarısız olursa hata mesajı ne yapmanız gerektiğini söyler; emin
değilseniz ebeveyn modülü sahiplerine sorun, testi silmeyin veya atlamayın.
