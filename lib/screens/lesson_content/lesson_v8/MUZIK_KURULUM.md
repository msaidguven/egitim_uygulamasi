# lesson_v6 — Müzik Kurulum Rehberi

## 1. Paket ekle — pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  audioplayers: ^6.1.0   # ← bunu ekle
```

Terminalde çalıştır:
```
flutter pub get
```

---

## 2. MP3 dosyasını yerleştir

Proje kök klasöründe `assets/audio/` klasörü oluştur:

```
proje_adi/
├── assets/
│   └── audio/
│       └── bg_music.mp3   ← müziğini buraya koy
├── lib/
│   ├── main.dart
│   └── ...
```

---

## 3. pubspec.yaml'a assets ekle

```yaml
flutter:
  assets:
    - assets/audio/bg_music.mp3
```

Birden fazla müzik dosyan varsa:
```yaml
flutter:
  assets:
    - assets/audio/   # tüm klasörü ekler
```

---

## 4. Farklı müzik dosyası kullanmak istersen

`main.dart` içinde sadece şu satırı değiştir:

```dart
static const String _musicAsset = 'audio/bg_music.mp3';
//                                        ↑
//                          assets/ sonrasını yaz
```

---

## 5. Ses seviyesini ayarla

`main.dart` içinde `_startMusic()` metodunda:

```dart
await _audioPlayer.setVolume(0.35); // 0.0 = sessiz, 1.0 = tam ses
```

---

## Ücretsiz oyun müziği kaynakları

- https://opengameart.org  (lisanssız)
- https://freemusicarchive.org
- https://pixabay.com/music  (arama: "game background")
- https://incompetech.com  (Kevin MacLeod — CC lisansı)

---

## Nasıl çalışır?

| Durum | Davranış |
|---|---|
| Uygulama açılır | Müzik otomatik başlar |
| Header'daki 🔊 | Müziği kapatır (pause) |
| Header'daki 🔇 | Müziği açar (resume) |
| Ders biter | Müzik çalmaya devam eder |
| Sayfa kapanır | `dispose()` ile player temizlenir |

Müzik loop modunda çalışır — dosya bitince başa döner.
