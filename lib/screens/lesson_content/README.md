# Lesson Content Sistemi

Bu modül, `assets/lessons/*.json` dosyalarından veri okuyup dersi adım adım işler.

## Tum Derslere Uygulanabilir Step Tipleri

- `hotspot_image`
  - Amaç: Görsel üzerinde doğru bölgeyi buldurma.
  - Alanlar: `title`, `instruction`, `imageAsset?`, `placeholderLabel?`, `hints[]`, `hotspots[]`, `concepts[]`
  - `hotspots` formatı: `{ "x": 0.25, "y": 0.40, "radius": 18, "correct": true }`

- `timeline_builder`
  - Amaç: Zaman/olay akışı sıralatma.
  - Alanlar: `title`, `instruction`, `items[]`, `correctOrder[]`, `hints[]`, `buttonText`, `concepts[]`
  - `items`: `{ "id": "sabah", "label": "Sabah gölgesi uzundur" }`

- `cause_effect_match`
  - Amaç: Neden-sonuç eşleştirme.
  - Alanlar: `title`, `instruction`, `pairs[]`, `hints[]`, `buttonText`, `concepts[]`
  - `pairs`: `{ "cause": "Işık kaynağı yaklaşır", "effect": "Gölge büyür" }`

- `variable_simulator`
  - Amaç: Değişken oynatıp sonucu görerek öğrenme.
  - Alanlar: `title`, `instruction`, `targetRange[]`, `hints[]`, `buttonText`, `concepts[]`

- `error_hunt`
  - Amaç: Bilinçli yanlışları buldurma.
  - Alanlar: `title`, `instruction`, `items[]`, `hints[]`, `buttonText`, `concepts[]`
  - `items`: `{ "id": "a1", "label": "Ekran ışık kaynağının önünde", "isError": true }`

- `memory_grid`
  - Amaç: Kavram-tekrar ve dikkat geliştirme.
  - Alanlar: `title`, `instruction`, `pairs[]`, `hints[]`, `concepts[]`
  - `pairs`: `{ "id": "p1", "left": "Opak", "right": "Işığı geçirmez" }`

- `micro_review`
  - Amaç: Ders sonunda en zayıf konulara 2-3 mini tekrar.
  - Alanlar: `title`, `count`, `questionBank[]`, `concepts[]`
  - `questionBank`: `{ "concept": "tam_golge", "question": "...", "options": ["..."], "correct": "...", "hints": ["..."] }`

- `branching_path`
  - Amaç: Performansa göre kolay/orta/zor yol seçimi.
  - Alanlar: `title`, `instruction`, `thresholds`, `targets`, `buttonText`
  - `thresholds`: `{ "medium": 60, "hard": 85 }`
  - `targets`: `{ "easy": "step_easy_1", "medium": "step_mid_1", "hard": "step_hard_1" }`

- `mastery_overview`
  - Amaç: Puan + ustalık yüzdesi + rozet gösterimi.
  - Alanlar: `title`, `buttonText`

## Adaptif Sistemler

- `adaptive_hint`: Tüm etkileşimli step'lerde yanlış deneme sayısına göre `hints[]` kademeli gösterilir.
- `mastery_score`: Etkileşimli step'lerde performansa göre puan hesaplanır.
- `badge`: `mastery_overview` adımında rozet seviyesi üretilir.

## Onerilen Genel Akış

1. `text` (kısa görev girişi)
2. 2-3 etkileşimli step (`hotspot_image`, `timeline_builder`, `cause_effect_match`)
3. `variable_simulator` veya `error_hunt`
4. `memory_grid`
5. `branching_path`
6. dal adımları
7. `micro_review`
8. `mastery_overview`
