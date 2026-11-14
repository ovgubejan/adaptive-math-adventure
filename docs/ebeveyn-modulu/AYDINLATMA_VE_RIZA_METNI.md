# Aydınlatma ve açık rıza metni — çalışma belgesi

> **Durum: TASLAK.** Bu metin bir hukukçu tarafından incelenmedi. Aşağıdaki
> madde açıklamaları yön göstermek içindir, hukuki görüş değildir. Uygulama
> gerçek ailelerle kullanılmadan önce bir uzmana (üniversitenin KVKK birimi,
> hukuk müşavirliği veya bir avukat) gösterilmelidir.
>
> Projeyi anlatırken "KVKK'ya uygundur" demeyin. Doğru ifade:
> **"KVKK ilkeleri gözetilerek tasarlanmıştır; metin hukuki inceleme bekliyor."**

Uygulamada gösterilen metnin **tek kaynağı** koddur:
`lib/family/content/consent_text.dart`. Bu belge o metnin neden öyle yazıldığını
ve hangi soruların açık olduğunu anlatır. Metni değiştirirken önce kodu
değiştirin, sonra bu belgeyi.

## Metin nasıl değiştirilir?

1. `consent_text.dart` içindeki ilgili bölümü düzenleyin.
2. `ConsentText.version` değerini değiştirin (ör. `taslak-2026-11-v1` →
   `taslak-2026-12-v2`). **Bunu atlamayın:** sürüm değişmezse mevcut
   kullanıcılar yeni metni görmez ve eski rızayla devam eder.
3. [VERI_ENVANTERI.md](VERI_ENVANTERI.md) ile tutarlı olduğunu kontrol edin.
4. Metin hukuki incelemeden geçtiğinde `ConsentText.isDraft` değerini `false`
   yapın; "taslaktır" notu ekranlardan kalkar.

Yalnızca yazım düzeltmesi yapıyorsanız (anlam değişmiyorsa) sürümü
değiştirmeniz gerekmez.

## Doldurulacak alanlar

| Alan | Kodda | Kim dolduracak |
|---|---|---|
| Veri sorumlusunun adı / kurumu | `ConsentText.dataController` | Danışman hocaya sorulacak |
| İletişim (e-posta / adres) | `ConsentText.dataControllerContact` | Danışman hocaya sorulacak |

**Veri sorumlusu nedir?** Verinin neden ve nasıl işleneceğine karar veren ve
bundan hukuken sorumlu olan kişi ya da kurum (KVKK m. 3). Ebeveynin "bu
veriyle ilgili kime başvuracağım?" sorusunun muhatabıdır. Öğrencilerin kişisel
adı yerine üniversite veya danışman üzerinden bir çözüm mümkün olabilir; bu
yüzden hocaya sorulmalı.

## Bölüm bölüm: ne yazdık, neye dayanıyor

| Bölüm | Ne söylüyor | Dayandığı düşünülen madde | Uygulamada karşılığı |
|---|---|---|---|
| 1. Veri sorumlusu | Kim sorumlu, nasıl ulaşılır | m. 10/1-a (kimlik bildirme) | Boş alan; doldurulacak |
| 2. Hangi veriler | Takma ad, yaş, oyun kayıtları, öğrenme durumu, PIN özeti, rıza kaydı | m. 4 (ölçülülük, amaçla sınırlılık) | [VERI_ENVANTERI.md](VERI_ENVANTERI.md) |
| 3. Amaç | Zorluk uyarlama, ebeveyne gösterme, adıyla hitap, PIN koruması | m. 10/1-b (işleme amacı) | Uyarlama motoru, ebeveyn paneli, "Merhaba, …!", PIN kapısı |
| 4. Hukuki sebep | Velinin açık rızası | m. 5/1 (açık rıza), m. 10/1-ç (hukuki sebep) | Kurulumda onay kutusu; onaysız kurulum ilerlemez |
| 5. Aktarım | Hiçbir yere aktarılmaz | m. 8, m. 9, m. 10/1-c | Sunucu, reklam, analiz yok |
| 6. Saklama süresi | Silinene kadar; Silinenler 30 gün | m. 4/2-d (gerekli süre kadar), m. 7 (silme) | Silinenler ve süre dolunca kalıcı silme |
| 7. Haklar | Öğrenme, bilgi isteme, düzeltme, silme | m. 11, m. 10/1-d | Panel (görme), Ayarlar (düzeltme), Veri yönetimi (silme) |
| 8. Rızayı geri çekme | İstenildiği an; her şey hemen silinir | m. 5/1, m. 7 | Ayarlar → Rıza → "Rızayı geri çek" |
| 9. Güvenlik | PIN, özet, güvenli depo, deneme sınırı | m. 12 (veri güvenliği) | PBKDF2 özeti, güvenli depo, 5 denemede kilit |
| 10. Değişiklikler | Metin değişirse yeniden onay | m. 10 (güncel aydınlatma) | `ConsentText.version` ve yeniden onay ekranı |

Madde numaraları 6698 sayılı Kanun'a göredir ve kontrol edilmelidir.

## Uzmana sorulacak açık sorular

1. **Aydınlatma ve rıza ayrımı.** Kişisel Verileri Koruma Kurulu'nun aydınlatma
   yükümlülüğüne ilişkin tebliği, aydınlatmanın ve açık rıza alınmasının ayrı
   ayrı yapılmasını ister. Ekranımızda aydınlatma (özet + tam metin) ve rıza
   (ayrı bir onay kutusu ve ayrı bir rıza cümlesi) aynı ekranda ama ayrı
   parçalar hâlinde duruyor. Bu yeterli mi, yoksa iki ayrı ekran mı olmalı?
2. **Çocuğun yaşı ve velinin rızası.** Kanun'da çocuklar için özel bir yaş
   sınırı yok; reşit olmayanlar için veli rızası alıyoruz. Velinin gerçekten
   veli olduğunu doğrulamıyoruz (yalnızca beyan). Bu proje için yeterli mi?
3. **Veri yalnızca cihazda duruyorken** veri sorumlusu olarak ekibin
   yükümlülükleri neler? VERBİS kaydı gibi bir yükümlülük doğar mı?
4. **Silinenler (30 gün).** Ebeveyn silme istedikten sonra verinin 30 gün
   geri alınabilir tutulması, metinde açıkça yazıldığı ve "şimdi kalıcı sil"
   seçeneği bulunduğu için kabul edilebilir mi?
5. **Oyun kayıtları** (cevap süresi, doğru/yanlış) bir çocuğun öğrenme
   güçlüğü gibi hassas bir duruma işaret edebilir mi; özel nitelikli veri
   (m. 6) sayılır mı? Uygulama tanı koymuyor ve böyle bir çıkarım yapmıyor.
6. **İlgili kişi başvurusu** (m. 13): ebeveyn veri sorumlusuna yazılı
   başvurursa süreç nasıl işleyecek, kim cevaplayacak?
7. Gerçek çocuklarla deneme yapılacaksa **etik kurul izni** ve ayrıca imzalı
   **veli onam formu** gerekir mi? (Uygulama içi onay bunun yerine geçmeyebilir.)
8. Sunucu eklendiğinde (özellikle yurt dışı sunucu) metinde nelerin değişmesi
   gerekir?

## Danışman hocaya sorulacaklar (kısa liste)

- Aydınlatma metnine veri sorumlusu olarak kimin adı ve hangi iletişim bilgisi
  yazılsın?
- Üniversitenin kişisel veri birimi veya hukuk müşavirliği metne bakabilir mi?
- Gerçek çocuklarla deneme için etik kurul başvurusu gerekiyor mu?
- Yaş aralığı 4–8 olarak kesin mi?
- Ebeveyn ipuçları ([EBEVEYN_IPUCLARI.md](EBEVEYN_IPUCLARI.md)) uygun mu?

## Kendi araştırmanız için başlıklar

- 6698 sayılı Kanun: m. 3 (tanımlar), m. 4 (genel ilkeler), m. 5 (işleme
  şartları), m. 7 (silme), m. 10 (aydınlatma), m. 11 (haklar), m. 12 (güvenlik).
- Aydınlatma Yükümlülüğünün Yerine Getirilmesinde Uyulacak Usul ve Esaslar
  Hakkında Tebliğ.
- Kurul'un açık rıza ve çocukların kişisel verileri hakkındaki rehberleri
  (kvkk.gov.tr).
- Google Play Aileler politikası (çocuklara yönelik uygulamalar için).

## Bu sürümde uygulamanın metne aykırı düşebileceği yerler

Dürüst olmak için: aşağıdaki durumlarda metin **yanlış** hâle gelir ve
düzeltilmelidir.

- Android yedeklemesi kapatılmadan Android sürümü çıkarılırsa ("yalnızca bu
  cihazda" cümlesi).
- Herhangi bir analiz, reklam, çökme raporlama veya sunucu paketi eklenirse.
- Envanterde olmayan yeni bir veri saklanırsa.
- Uygulama Chrome'da gerçek kullanıcıya sunulursa ("güvenli depolama alanı"
  cümlesi tarayıcı için tam doğru değildir).
