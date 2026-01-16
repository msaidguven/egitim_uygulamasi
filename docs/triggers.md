# Veritabanı Tetikleyicileri (Triggers)

Bu doküman, projedeki önemli veritabanı tetikleyicilerinin (triggers) ne işe yaradığını açıklar.

---

## `on_new_answer_srs`

- **Tablo:** `public.test_session_answers`
- **Çalışma Zamanı:** `AFTER INSERT` (Her yeni cevap eklendiğinde)
- **Çalıştırdığı Fonksiyon:** `public.sync_user_question_stats()`

### Açıklama

Bu tetikleyici, uygulamanın **Aralıklı Tekrar Sistemi (Spaced Repetition System - SRS)**'nin kalbidir. Giriş yapmış bir kullanıcı bir soruya cevap verdiğinde, bu tetikleyici otomatik olarak devreye girer ve `user_question_stats` tablosundaki ilgili kaydı günceller.

### Temel İşlevleri

1.  **İstatistik Güncelleme:** Kullanıcının bir soruya verdiği her cevabı (doğru/yanlış, deneme sayısı vb.) kaydeder.
2.  **Akıllı Tekrar Zamanlaması:** Bir sorunun bir sonraki gösterileceği zamanı (`next_review_at`) kullanıcının performansına göre akıllıca ayarlar.

### Kullandığı Aralıklar

- **Yanlış Cevap:** Soru **10 dakika** sonra tekrar gösterilir.
- **Doğru Cevap (Performansa Göre):**
  - Yanlıştan sonraki 1. doğru: **8 saat** sonra
  - 2. ardışık doğru: **1 gün** sonra
  - 3. ardışık doğru: **3 gün** sonra
  - 4. ardışık doğru: **7 gün** sonra
  - 5. ve üzeri ardışık doğru: **15 gün** sonra

Bu sistem, öğrenilen bilginin unutulmaya yüz tuttuğu anda tekrar edilmesini sağlayarak, bilginin uzun süreli belleğe daha etkili bir şekilde yerleşmesine yardımcı olur.
