# Ebeveyn modülü — kararlar

Bu belge ebeveyn bölümü, KVKK/rıza ve ilk açılış girişi için alınan kararları
ve nedenlerini toplar. Yeni bir karar alındığında buraya eklenir.

İlgili belgeler: [EBEVEYN_MODULU.md](EBEVEYN_MODULU.md) (nasıl çalışır),
[VERI_ENVANTERI.md](VERI_ENVANTERI.md) (hangi veri tutulur),
[OYUN_EKIBI_KILAVUZU.md](OYUN_EKIBI_KILAVUZU.md),
[SUNUCU_EKIBI_KILAVUZU.md](SUNUCU_EKIBI_KILAVUZU.md),
[AYDINLATMA_VE_RIZA_METNI.md](AYDINLATMA_VE_RIZA_METNI.md).

## Kapsam

| Konu | Karar | Neden |
|---|---|---|
| Hedef platform | Android. Chrome (web) yalnızca geliştirme ve hızlı deneme ortamı. | Proje bir mobil uygulama; Chrome'da denemek hızlı. |
| Kullanıcı | Tek ebeveyn, tek çocuk. Çoklu profil yok. | Danışman hocanın isteği. |
| Yaş aralığı | 4–8. Kodda tek sabit: `FamilyConfig.minChildAge` / `maxChildAge`. | Aralık değişirse tek yerden değişsin. |
| Sunucu | Şimdi yok. Yapı yerel çalışır ama sunucuya hazırdır. | Sunucuyu sonra başka ekip üyeleri ekleyecek. |
| Yayın | Okul bitirme projesi (TÜBİTAK 2209-A başvurusu). Satış yok. Şimdilik yalnızca Türkiye. | — |

## Toplanan veri

| Karar | Neden |
|---|---|
| Çocuk için yalnızca **takma ad** ve **yaş** alınır. Doğum tarihi, gerçek ad, e-posta, fotoğraf, ses, konum alınmaz. | Veri en aza indirilir; uygulamanın bunlara ihtiyacı yok. |
| Ebeveynden e-posta alınmaz. | Rapor uygulama içinde gösteriliyor; e-posta göndermek sunucu ister. |
| Mikrofon, kamera, konum izni yok. Reklam ve analiz (analytics) paketi yok. | Çocuk verisi habersizce üçüncü tarafa gitmesin. |

## Giriş ve roller

| Karar | Neden |
|---|---|
| İlk açılışta kurulum: karşılama → aydınlatma ve rıza → çocuk profili → PIN. | Rıza alınmadan çocuk verisi alınmaz. |
| Kurulumda hiçbir şey son adım bitene kadar kaydedilmez. | Yarım kurulumda rızasız veri kalmasın. |
| Uygulama **her açılışta** rol sorar: "Ben Ali'yim" / "Ben ebeveynim". | Hem çocuk hem ebeveyn kolay girsin. |
| Çocuk düğmesi büyük ve renkli, ebeveyn düğmesi küçük ve sade. | 4 yaşındaki çocuk okumadan kendi düğmesini bulsun. |
| Ebeveyn bölümü 4 haneli PIN ile korunur. 5 yanlış denemede 30 saniye kilit. | Çocuk ebeveyn bölümüne giremesin (mağazaların "ebeveyn kapısı" şartı). |
| PIN'in kendisi saklanmaz; tuzlu özeti (PBKDF2-HMAC-SHA256) güvenli depoda durur. | PIN düz metin olarak hiçbir yerde durmasın. |
| PIN unutulursa kurtarma **yok** (bilinçli olarak ertelendi). | Yerel yapıda güvenli bir kurtarma yolu yok; sunucu/hesap gelince çözülecek. |
| Ebeveyn bölümünden çıkınca ve uygulama yeniden açılınca bölüm yeniden kilitlenir. | Açık unutulmasın. |

## Ebeveyn bölümü

| Karar | Neden |
|---|---|
| Sekmeler: Özet, Seviyeler (seviye ve beceri bazında doğru/yanlış), Geçmiş, Gelişim (grafik), İpuçları. | Ebeveyn çocuğun gidişatını uygulama içinden görsün. |
| Grafik ek paket olmadan çizilir. | Yeni bağımlılık eklememek. |
| "Öneri" ve "İpuçları" yalnızca öneridir; uygulamanın hiçbir davranışı bunlara bağlı değildir. | Ebeveyni yönlendirmek değil, bilgilendirmek. |
| Günlük oyun süresi sınırı **yok**. | Danışman hoca çocuğun uygulamada vakit geçirmesini istiyor. |
| Veriyi dışa aktarma **yok**. | Veri zaten uygulama içinde gösteriliyor. |
| Ebeveyn panele yalnızca **bakar**; oyunun verisini değiştirmez (silme hariç). | Oyun mantığı oyun ekibinin sorumluluğunda. |

## Silme

| Karar | Neden |
|---|---|
| İki ayrı işlem: **İlerlemeyi sıfırla** (profil, PIN, rıza kalır) ve **Her şeyi sil** (uygulama ilk kuruluma döner). | Biri "baştan başlasın", diğeri KVKK'daki silme hakkı. |
| Her silmeden önce onay penceresi: ne olacağı, sonrasında ne yapmak gerekeceği yazılır ve **PIN yeniden istenir**. | Yanlışlıkla veya çocuk tarafından silinmesin. |
| Silinen ilerleme **30 gün** "Silinenler"de durur, geri yüklenebilir, sonra kalıcı silinir. | Yanlışlıkla silmeye karşı (Google Fotoğraflar'daki gibi). |
| Süre kontrolü uygulama açılırken ve Silinenler ekranı açılırken yapılır. | Sunucu yok; arka planda çalışan bir zamanlayıcı yok. |
| "Şimdi kalıcı olarak sil" her zaman vardır. | Ebeveyn 30 gün beklemek zorunda kalmasın. |
| Geri yüklerken o anki ilerleme kaybolmaz; Silinenler'e taşınır. | Geri yükleme de geri alınabilsin. |
| **Rızayı geri çekmek** Silinenler dahil her şeyi hemen ve kalıcı siler. | Rıza olmadan veri saklanmaz. |
| "Her şeyi sil", uygulamanın yerel deposundaki **tüm** anahtarları siler (kayıtsız modüllerinki dahil). | Bir modül silme kaydına eklenmeyi unutsa bile "her şey silindi" sözü doğru kalsın. |
| Yalnızca toplu silme; tek tek oturum silme yok. | Tek çocuk var; iş büyümesin. |

## Rıza metni

| Karar | Neden |
|---|---|
| Metin kodda tek dosyada durur (`lib/family/content/consent_text.dart`) ve bir **sürümü** vardır. | Hangi metne onay verildiği kayıtlı olsun. |
| Sürüm değişirse uygulama ebeveynden PIN ile **yeniden onay** ister; onaylanmadan hiçbir ekran açılmaz. | Yeni veri toplanmaya başlanırsa eski rıza yetmez. |
| Metin **taslaktır**; "KVKK'ya uygundur" iddiası yoktur. Doğru ifade: "KVKK ilkeleri gözetilerek tasarlanmıştır". | Hukuki uygunluğu bir uzman onaylar. |
| Veri sorumlusu alanı boş bırakıldı (`[VERİ SORUMLUSU ...]`). | Danışman hocaya sorulacak. |
| Metin yalnızca uygulamanın **gerçekten yaptığını** yazar. | Yapılmayan bir şeyi vaat etmek, hiç yazmamaktan kötüdür. |

## Kod düzeni

| Karar | Neden |
|---|---|
| Modülün tamamı `lib/family/` altındadır. | Dört kişi aynı dosyalarda çakışmasın. |
| Mevcut dosyalara dokunuş üç yerle sınırlıdır: `main.dart` (3 satır), `app.dart` (2 satır), `app_router.dart` (yönlendirme koruması ve rotalar). | Birleştirme (merge) çakışması en aza insin. |
| `createAppRouter()` ebeveyn modülü verilmeden çağrılırsa eskisi gibi çalışır. | Mevcut testler değişmeden geçsin. |
| Yerel depolama anahtarlarımız `family_` önekiyle başlar. | Başka bir modülle aynı anahtarı kullanıp birbirimizin verisini bozmayalım. |
| Kayıtlarda `schemaVersion` var; bilinmeyen alanlar okunup geri yazılır, bozuk kayıt çökme yerine "kayıt yok" sayılır. | Şema değişince uygulama çökmesin, yeni sürümün yazdığı veri kaybolmasın. |
| Her rota "çocuk" / "ebeveyn" / "geçiş" olarak sınıflandırılır; sınıflandırılmamış rota açılmaz ve test başarısız olur. | Yeni eklenen bir ekran ebeveyn kapısını atlayamasın. |
| Çocuğa ait veri tutan her modül silme kaydına (`ChildDataModule`) eklenir. | "Sil" denince hiçbir verisi geride kalmasın. |
| Depolar arayüz arkasındadır; ortak sözleşme testleri vardır. | Sunucu eklenirken uygulamanın geri kalanı değişmesin. |
| Geliştirici modu (`--dart-define=FAMILY_DEV_MODE=true`) kurulumu atlar; yalnızca debug derlemede çalışır. | Ekip her çalıştırmada kurulum yapmak zorunda kalmasın; yayın sürümünde sahte rıza oluşmasın. |
| Ebeveyn ve kurulum ekranları Türkçedir. | Rıza metni ve ebeveyn Türkçe; oyun ekranlarının dili oyun ekibinin kararı. |

## Açık konular

- **Veri sorumlusu** kimin adıyla yazılacak? (Hocaya sorulacak.)
- **Android klasörü yok.** Depoda yalnızca `web/` var. Android'de çalıştırmak
  için platform dosyalarının oluşturulması ve yedekleme ayarının kapatılması
  gerekir (bkz. [EBEVEYN_MODULU.md](EBEVEYN_MODULU.md) → "Android'e geçerken").
- **PIN kurtarma** yok.
- **Rıza metninin hukuki incelemesi** yapılmadı.
- Gerçek çocuklarla deneme yapılacaksa etik kurul izni ve veli onam formu
  gerekip gerekmediği hocaya sorulacak.
- Oyun ekranları İngilizce, ebeveyn ekranları Türkçe. Dil birliği ekipçe
  kararlaştırılmalı.
- 4 yaşındaki çocuk okuyamaz; oyun ekranlarındaki yazılı yönergeler için
  görsel/sesli karşılık oyun ekibinin konusudur.
