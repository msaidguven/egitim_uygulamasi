"""
main.py
───────
Ana çalıştırıcı. lesson_grades tablosunu merkeze alarak her
(grade, lesson) çifti için HTML sayfaları üretir.

Kullanım:
    python3 main.py
"""
from pathlib import Path
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

from config import get_supabase, SITE_NAME, SITE_URL, ADSENSE_CLIENT
from generate import (
    generate_topic_page,
    generate_questions_page,
    ensure_dir,
)

OUTPUT_DIR    = Path("output")
TEMPLATES_DIR = "templates"


def make_env() -> Environment:
    env = Environment(loader=FileSystemLoader(TEMPLATES_DIR))
    env.filters["choice_letter"] = lambda i: chr(65 + i)
    return env


def write_sitemap(sitemap_urls: list, output_dir: Path):
    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for url, lastmod in sitemap_urls:
        lines.append(f"""  <url>
    <loc>{SITE_URL}{url}</loc>
    <lastmod>{lastmod[:10]}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.7</priority>
  </url>""")
    lines.append("</urlset>")
    sitemap_file = output_dir / "sitemap.xml"
    sitemap_file.write_text("\n".join(lines), encoding="utf-8")
    print(f"\n🗺️  Sitemap: {sitemap_file} ({len(sitemap_urls)} URL)")


def main():
    print("🚀 SEO Generator başlatılıyor...\n")

    sb  = get_supabase()
    env = make_env()
    ensure_dir(OUTPUT_DIR)

    sitemap_urls = []
    stats = {
        "toplam_topic":   0,
        "icerikli_topic": 0,
        "sorulu_topic":   0,
        "konu_sayfasi":   0,
        "soru_sayfasi":   0,
    }

    # ── 1) Tüm aktif grade'leri çek (order_no sırasıyla) ─────────────────────
    grades = (sb.table("grades")
                .select("*")
                .eq("is_active", True)
                .order("order_no")
                .execute().data)

    grades_by_id = {g["id"]: g for g in grades}
    print(f"📚 {len(grades)} aktif sınıf bulundu.\n")

    # ── 2) Tüm aktif lesson_grades kayıtlarını çek ────────────────────────────
    # Her satır: hangi lesson hangi grade'e ait
    lg_rows = (sb.table("lesson_grades")
                 .select("lesson_id, grade_id")
                 .eq("is_active", True)
                 .execute().data)

    # ── 3) Tüm aktif lesson'ları çek ─────────────────────────────────────────
    lessons_raw = (sb.table("lessons")
                     .select("*")
                     .eq("is_active", True)
                     .order("order_no")
                     .execute().data)

    lessons_by_id = {l["id"]: l for l in lessons_raw}

    # ── 4) lesson_grades üzerinden (grade, lesson) çiftlerini işle ───────────
    # grade order_no sırasını korumak için grades listesi üzerinden dön
    for grade in grades:
        print(f"▶ {grade['name']} (id={grade['id']})")

        # Bu grade'e ait aktif lesson_id'leri bul
        lesson_ids = [
            row["lesson_id"] for row in lg_rows
            if row["grade_id"] == grade["id"]
        ]

        if not lesson_ids:
            print("  ⊘ Aktif ders yok")
            continue

        # Lesson'ları order_no sırasına göre al
        lessons = [
            lessons_by_id[lid] for lid in lesson_ids
            if lid in lessons_by_id
        ]
        lessons.sort(key=lambda l: l.get("order_no") or 0)

        for lesson in lessons:
            print(f"  📖 {lesson['name']} (id={lesson['id']})")

            # ── 5) Bu grade+lesson kombinasyonuna ait unit'leri çek ──────────
            # Artık units tablosunda doğrudan grade_id var
            units = (sb.table("units")
                       .select("*")
                       .eq("lesson_id", lesson["id"])
                       .eq("grade_id", grade["id"])
                       .eq("is_active", True)
                       .order("order_no")
                       .execute().data)

            if not units:
                print("    ⊘ Bu sınıfa ait aktif ünite yok")
                continue

            for unit in units:
                print(f"    📂 {unit['title']} (id={unit['id']})")

                # ── 6) Bu unit'e ait aktif topic'leri çek ────────────────────
                topics = (sb.table("topics")
                            .select("*")
                            .eq("unit_id", unit["id"])
                            .eq("is_active", True)
                            .order("order_no")
                            .execute().data)

                for topic in topics:
                    stats["toplam_topic"] += 1

                    generate_topic_page(
                        sb, env, OUTPUT_DIR,
                        grade, lesson, unit, topic,
                        sitemap_urls, stats
                    )

                    generate_questions_page(
                        sb, env, OUTPUT_DIR,
                        grade, lesson, unit, topic,
                        sitemap_urls, stats
                    )

    # ── 7) Sitemap yaz ───────────────────────────────────────────────────────
    write_sitemap(sitemap_urls, OUTPUT_DIR)

    # ── 8) Özet rapor ────────────────────────────────────────────────────────
    print("\n" + "─" * 40)
    print("✅ Tamamlandı!\n")
    print(f"Toplam konu:      {stats['toplam_topic']}")
    print(f"İçerikli konu:    {stats['icerikli_topic']} ✅")
    print(f"Sorulu konu:      {stats['sorulu_topic']} 🎯")
    print(f"Soru sayfası:     {stats['soru_sayfasi']} 📝")


if __name__ == "__main__":
    main()
