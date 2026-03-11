# 🫁 Tiroid Rapor Uygulaması

Sesli komutla tiroid ultrason raporu oluşturan iOS uygulaması.

---

## 📋 Uygulamanın Yapısı

Uygulama şu bölümleri sesli olarak alır ve PDF formatında kaydeder:

| Bölüm | Nasıl Tanıyor |
|-------|---------------|
| Hasta adı | İlk söylenen cümle |
| Sağ/Sol lob ölçüleri | "sağ lob" + ölçüm (30x20x15 mm) |
| İstmus | "istmus" + kalınlık (mm) |
| Nodül | Lokasyon kelimesi + ölçüm (sağ lob anteriorda 9x8x12...) |
| TI-RADS | "ti-rads 4" veya "tirads 3" |
| Lenf nodu | "sağ seviye 3" veya "sol seviye 2" |
| Düzeltme | "Düzelt" veya "Geri al" |

---

## 🛠 Kurulum (Mac Gereklidir)

### Gereksinimler
- Mac (macOS 13+)
- Xcode 15+ ([App Store'dan ücretsiz indir](https://apps.apple.com/tr/app/xcode/id497799835))
- Apple Developer hesabı (ücretsiz, [appleid.apple.com](https://appleid.apple.com))

### Adım 1: Projeyi İndir

```bash
git clone https://github.com/KULLANICI_ADINIZ/ThyroidReport.git
cd ThyroidReport
```

### Adım 2: Xcode Projesini Oluştur

```bash
chmod +x setup.sh
./setup.sh
```

Bu komut otomatik olarak:
- Homebrew'u kontrol eder/yükler
- XcodeGen'i kontrol eder/yükler
- `ThyroidReport.xcodeproj` dosyasını oluşturur

### Adım 3: Xcode'da Aç ve İmzala

1. `ThyroidReport.xcodeproj` dosyasını çift tıklayarak Xcode'da açın
2. Sol üstten **ThyroidReport** projesine tıklayın
3. **Signing & Capabilities** sekmesine gidin
4. **Team** bölümünden Apple ID'nizi seçin
5. Bundle Identifier'ı benzersiz yapın: `com.ADINIZ.ThyroidReport`

### Adım 4: TestFlight'a Yükle

1. iPhone'unuzu Mac'e USB ile bağlayın
2. Xcode'da üstten hedef olarak iPhone'unuzu seçin
3. Menüden: **Product → Archive**
4. Archive tamamlandığında: **Distribute App → TestFlight**
5. [TestFlight](https://testflight.apple.com) uygulamasından yükleyin

---

## 📱 Kullanım Kılavuzu

### Kayıt Akışı

```
1. Uygulamayı açın → Kayda Başla'ya basın
2. Hasta adını söyleyin      → "Ahmet Yılmaz"
3. Sağ lobu söyleyin        → "Sağ lob 35x20x18 mm"
4. Sol lobu söyleyin        → "Sol lob 32x18x16 mm"
5. İstmusu söyleyin         → "İstmus 4 mm"
6. Nodülü söyleyin          → "Sağ lob anteriorda 9x8x12 mm 
                                sınırları düzenli hipoekoik nodül"
7. TI-RADS'ı söyleyin       → "Ti-rads 3"
8. Lenf nodunu söyleyin     → "Sağ seviye 3'te 12x8 mm
                                reaktif görünümlü lenf nodu"
9. Önizle butonuna basın
10. Gerekirse düzenleyin
11. PDF Oluştur ve Kaydet'e basın
```

### Komutlar

| Komut | Efek |
|-------|------|
| "Düzelt" | Son eklenen bilgiyi geri al |
| "Geri al" | Son eklenen bilgiyi geri al |
| "İptal" | Son eklenen bilgiyi geri al |

### Desteklenen Tıbbi Terimler

Türkçe ve İngilizce terminoloji desteklenir:
- hipoekoik / hypoechoic
- hiperekoik / hyperechoic
- izoekoik / isoechoic
- mikrokalsifikasyon
- vaskülarite
- heterojen / homojen
- anteriorda, posteriorda, lateralde, medialde

---

## 📄 Rapor Formatı

```
TİROİD ULTRASON RAPORU
─────────────────────────────
Hasta    : Ahmet Yılmaz
Tarih    : 11 Mart 2026 09:30
─────────────────────────────
TİROİD BEZİ ÖLÇÜLERİ
Sağ lob  : 35 x 20 x 18 mm (Volüm: 6.3 mL)
Sol lob  : 32 x 18 x 16 mm (Volüm: 4.4 mL)
İstmus   : 4 mm
─────────────────────────────
NODÜLLER
Nodül 1 - Sağ lob anteriorda:
  Sağ lob anteriorda 9x8x12 mm sınırları düzenli...
  TI-RADS: TR3
─────────────────────────────
SERVİKAL LENF NODLARI
Lenf Nodu 1 - Sağ seviye 3:
  Sağ seviye 3'te 12x8 mm reaktif görünümlü lenf nodu
```

**Dosya adlandırma:** `AhmetYilmaz_11032026.pdf`
**Kayıt yeri:** Dosyalar uygulaması → Tiroid Rapor (Paylaş menüsünden seçebilirsiniz)

---

## ❓ Sorun Giderme

**"Konuşma tanıma çalışmıyor"**
→ Ayarlar → Gizlilik → Konuşma Tanıma → Tiroid Rapor'a izin verin

**"Mikrofon çalışmıyor"**  
→ Ayarlar → Gizlilik → Mikrofon → Tiroid Rapor'a izin verin

**"İnternete ihtiyacı var mı?"**  
→ Evet, konuşma tanıma için Apple sunucularına bağlanır (veriler Apple'ın gizlilik politikasına göre korunur)

---

## ⚖️ Yasal Uyarı

Bu uygulama klinisyen tarafından kontrol altında kullanılmak üzere tasarlanmıştır. Otomatik tanı aracı değildir. Tüm raporlar oluşturulduktan sonra hekimin denetiminden geçmelidir.

---

*Tiroid Rapor v1.0 — SwiftUI + Apple Speech Framework*
