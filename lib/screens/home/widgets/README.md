# Home Screen Refactoring - Minimal & Modern

## 📁 Dosya Yapısı

Bu refactoring ile anasayfa 8 ayrı dosyaya bölünmüştür:

```
lib/screens/home/
├── home_screen.dart                    # Ana home screen (refactored)
└── widgets/
    ├── common_widgets.dart             # Ortak kullanılan widget'lar
    ├── home_header.dart                # Header ve kullanıcı bilgileri
    ├── week_info_card.dart             # Haftalık bilgi kartı
    ├── unfinished_tests_section.dart   # Yarım kalan testler bölümü
    ├── student_content_view.dart       # Öğrenci içeriği
    ├── teacher_content_view.dart       # Öğretmen içeriği
    └── guest_content_view.dart         # Misafir kullanıcı içeriği
```

---

## 📦 Dosya Açıklamaları

### 1. **home_screen_refactored.dart**
Ana home screen dosyası. Tüm widget'ları import eder ve organize eder.
- SliverAppBar ile header
- WeekInfoCard ile hafta bilgisi
- Role göre content gösterimi

### 2. **common_widgets.dart**
Tüm sayfalarda kullanılan ortak widget'lar:
- `SectionHeader` - Bölüm başlıkları için
- `EmptyState` - Boş durum gösterimi için
- `MotivationCard` - Motivasyon kartı
- `LoadingShimmer` - Yükleme animasyonu

### 3. **home_header.dart**
Header bölümü:
- Kullanıcı karşılama mesajı
- Avatar gösterimi
- Admin menüsü (role değiştirme, oyunlar)
- Oyun seçim dialog'u

### 4. **week_info_card.dart**
Haftalık bilgi kartı:
- Giriş yapan kullanıcılar için hafta bilgisi
- Giriş yapmayan kullanıcılar için login prompt
- İstatistikler (ders sayısı, sınıf, tamamlanan)

### 5. **unfinished_tests_section.dart**
Yarım kalan testler bölümü:
- Horizontal scroll liste
- Loading state
- Test devam ettirme fonksiyonu

### 6. **student_content_view.dart**
Öğrenci içeriği:
- Bu haftanın dersleri
- Geçmiş haftalar (next steps)
- Ders kartları
- Motivasyon kartı

### 7. **teacher_content_view.dart**
Öğretmen içeriği:
- Sınıf kartları
- Öğrenci sayıları
- Ortalama başarı grafikleri

### 8. **guest_content_view.dart**
Misafir kullanıcı içeriği:
- Mevcut sınıflar grid view
- Sınıf kartları

---

## 🎨 Tasarım Özellikleri

### Renk Paleti
- **Ana Renk:** `Colors.grey.shade900` (Siyah/Gri)
- **Arka Plan:** `Colors.white`
- **Kartlar:** `Colors.grey.shade50`
- **Border:** `Colors.grey.shade200`
- **Text:** `Colors.grey.shade600` (secondary)

### Spacing (Boşluklar)
- Sayfa padding: `24px`
- Kart padding: `20-24px`
- Element arası: `12-16px`
- Section arası: `32-40px`

### Border Radius
- Kartlar: `16px`
- Butonlar: `12px`
- İkonlar: `10-12px`

### Typography
- Başlık: `18-20px`, `FontWeight.w600`
- Alt başlık: `13-14px`, `FontWeight.w400`
- İstatistik: `20px`, `FontWeight.w700`

---

## 🚀 Kullanım

### Projeye Ekleme

1. `lib/screens/home/` klasörünü oluşturun
2. Tüm widget dosyalarını `lib/screens/home/widgets/` içine kopyalayın
3. Ana `home_screen_refactored.dart` dosyasını `lib/screens/home_screen.dart` olarak kaydedin

### Import Yapısı

```dart
// Ana ekranda
import 'package:egitim_uygulamasi/screens/home/widgets/home_header.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/week_info_card.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/student_content_view.dart';
// ... diğer import'lar
```

### Widget Kullanımı

```dart
// Header kullanımı
HomeHeader(
  profile: widget.profile,
  isAdmin: isAdmin,
  onRoleChanged: widget.onRoleChanged,
  impersonatedRole: widget.impersonatedRole,
)

// Week Info Card kullanımı
WeekInfoCard(
  profile: widget.profile,
  agendaData: widget.agendaData,
  completedLessons: _calculateCompletedLessons(),
)

// Student Content kullanımı
StudentContentView(
  agendaData: widget.agendaData,
  nextStepsData: widget.nextStepsData,
  currentCurriculumWeek: widget.currentCurriculumWeek,
  nextStepsState: widget.nextStepsState,
  onToggleNextSteps: widget.onToggleNextSteps,
  onExpandNextSteps: widget.onExpandNextSteps,
  onRefresh: widget.onRefresh,
)
```

---

## ✅ Avantajlar

1. **Modülerlik** - Her widget kendi dosyasında
2. **Okunabilirlik** - Daha temiz ve anlaşılır kod
3. **Bakım Kolaylığı** - Tek bir widget'ı değiştirmek kolay
4. **Yeniden Kullanılabilirlik** - Widget'lar başka yerlerde de kullanılabilir
5. **Test Edilebilirlik** - Her widget ayrı ayrı test edilebilir
6. **Minimal Tasarım** - Modern ve sade görünüm

---

## 📝 Notlar

- Tüm widget'lar **StatelessWidget** olarak tasarlandı
- State management ana ekranda (HomeScreen) tutuldu
- Callback'ler parametre olarak geçildi
- Common widget'lar tüm içerik view'larında kullanılabilir

---

## 🔄 Eski Koddan Farklar

| Özellik | Eski Kod | Yeni Kod |
|---------|----------|----------|
| Dosya Sayısı | 1 dosya | 8 dosya |
| Satır Sayısı | ~1000+ | ~100-200/dosya |
| Widget Organizasyonu | Tek dosyada | Ayrı dosyalarda |
| Renk Paleti | Gradient'li, renkli | Minimal, gri tonları |
| Boşluklar | Orta | Fazla (havadar) |
| Gölgeler | Çokça | Minimal/Yok |

---

## 🎯 Sonuç

Bu refactoring ile:
- ✅ Kod daha organize
- ✅ Bakımı daha kolay
- ✅ Tasarım daha minimal ve modern
- ✅ Performance daha iyi (lazy loading)
- ✅ Test edilebilirlik arttı
