"""
generate.py
───────────
Supabase'den veri çekip HTML sayfaları üretir.
Klasör ve URL yapısı için DB'deki slug alanları kullanılır.
"""
import re
import time
from pathlib import Path
from datetime import datetime
from jinja2 import Environment, FileSystemLoader
from config import get_supabase, SITE_NAME, SITE_URL, ADSENSE_CLIENT


# ── Yardımcı Fonksiyonlar ─────────────────────────────────────────────────────

def slugify_tr(text: str) -> str:
    """Yedek slug üretici — DB'de slug yoksa kullanılır."""
    tr_map = str.maketrans("çğıöşüÇĞİÖŞÜ", "cgiosucgiosu")
    text = text.translate(tr_map).lower()
    text = re.sub(r"[.\s]+", "-", text)
    text = re.sub(r"[^a-z0-9-]", "", text)
    text = re.sub(r"-+", "-", text).strip("-")
    return text


def get_slug(obj: dict, title_key: str = "title") -> str:
    """
    DB'deki slug alanını döndürür.
    Yoksa veya boşsa title_key üzerinden slugify_tr ile üretir.
    """
    slug = obj.get("slug", "")
    if slug and slug.strip():
        return slug.strip()
    return slugify_tr(obj.get(title_key, ""))


def ensure_dir(path: Path):
    """Klasör yoksa oluştur."""
    path.mkdir(parents=True, exist_ok=True)


def choice_letter(index: int) -> str:
    """0 → A, 1 → B, 2 → C ... döndürür."""
    return chr(65 + index)


def make_env(templates_dir: str = "templates") -> Environment:
    """Jinja2 Environment'ı oluşturur ve custom filter'ları render'dan önce ekler."""
    env = Environment(loader=FileSystemLoader(templates_dir))
    env.filters["choice_letter"] = choice_letter
    return env


def make_seo(topic, unit, grade, lesson, contents=None, questions=None):
    """SEO title ve description üretir."""
    if questions is not None:
        n = len(questions)
        seo_title = (
            f"{topic['title']} Test Soruları - {unit['title']} | "
            f"{grade['name']} {lesson['name']}"
        )
        seo_description = (
            f"{n} soru ile {topic['title']} konusunu pekiştir ve başarını ölç. "
            f"{grade['name']} {lesson['name']} dersi {unit['title']} ünitesi online alıştırma."
        )
    else:
        seo_title = (
            f"{topic['title']} - {unit['title']} | "
            f"{grade['name']} {lesson['name']}"
        )
        plain = ""
        if contents:
            raw = contents[0].get("content", "")
            plain = re.sub(r"<[^>]+>", " ", raw)
            plain = re.sub(r"\s+", " ", plain).strip()
            plain = plain[:155].rsplit(" ", 1)[0]

        if plain:
            seo_description = (
                f"{topic['title']} konusu: {plain}. "
                f"{grade['name']} {lesson['name']} dersi ders notları ve kazanımlar."
            )
        else:
            seo_description = (
                f"{topic['title']} konusu hakkında detaylı bilgi, kazanımlar ve içerik. "
                f"{grade['name']} {lesson['name']} dersi {unit['title']} ünitesi."
            )

    if len(seo_title) > 60:
        seo_title = seo_title[:57].rsplit(" ", 1)[0] + "..."
    if len(seo_description) > 155:
        seo_description = seo_description[:152].rsplit(" ", 1)[0] + "..."

    return seo_title, seo_description


def execute_with_retry(query_builder, retries=3, base_delay=0.6):
    """Geçici 5xx hatalarda sorguyu tekrar dener."""
    for attempt in range(retries):
        try:
            return query_builder.execute().data
        except Exception as exc:
            text = str(exc).lower()
            is_transient = ("502" in text or "bad gateway" in text or "json could not be generated" in text)
            if not is_transient or attempt == retries - 1:
                raise
            time.sleep(base_delay * (attempt + 1))


def get_lesson_topics(sb, grade, lesson, current_topic_id, only_unit_id=None, include_current=False):
    """Aynı sınıf + ders için konu linklerini döndürür."""
    units = execute_with_retry(
        sb.table("units")
          .select("*")
          .eq("lesson_id", lesson["id"])
          .eq("grade_id", grade["id"])
          .eq("is_active", True)
          .order("order_no")
    )

    if not units:
        return []

    grade_slug = get_slug(grade, "name")
    lesson_slug = get_slug(lesson, "name")
    related = []

    for unit in units:
        if only_unit_id is not None and unit["id"] != only_unit_id:
            continue

        topics = execute_with_retry(
            sb.table("topics")
              .select("*")
              .eq("unit_id", unit["id"])
              .eq("is_active", True)
              .order("order_no")
        )
        if not topics:
            continue

        topic_ids = [t["id"] for t in topics]
        published_rows = execute_with_retry(
            sb.table("topic_contents")
              .select("topic_id")
              .eq("is_published", True)
              .in_("topic_id", topic_ids)
        )
        published_topic_ids = {row["topic_id"] for row in published_rows}
        if not published_topic_ids:
            continue

        for t in topics:
            is_current = t["id"] == current_topic_id
            if is_current and not include_current:
                continue
            if t["id"] not in published_topic_ids:
                continue

            unit_slug = get_slug(unit, "title")
            topic_slug = get_slug(t, "title")
            url = f"/{grade_slug}/{lesson_slug}/{unit_slug}/{topic_slug}/"

            related.append({
                "title": t["title"],
                "unit_title": unit["title"],
                "url": url,
                "is_current": is_current,
            })

    return related


# ── Sorular Sayfası Üretici ───────────────────────────────────────────────────

def generate_questions_page(sb, env, output_dir, grade, lesson, unit, topic, sitemap_urls, stats):
    """Bir topic için sorular sayfası oluşturur. SADECE soru varsa HTML üretir."""

    # ── 1) Soruları çek ──────────────────────────────────────────────────────
    question_ids = (sb.table("question_usages")
                      .select("question_id")
                      .eq("topic_id", topic["id"])
                      .execute().data)

    if not question_ids:
        print(f"   ⊘ Soru yok: {topic['title']}")
        return

    q_ids = [q["question_id"] for q in question_ids]

    questions = (sb.table("questions")
                   .select("*, question_choices(*)")
                   .in_("id", q_ids)
                   .order("difficulty", desc=False)
                   .execute().data)

    if not questions:
        return

    for q in questions:
        if q.get("question_choices"):
            q["choices"] = sorted(q["question_choices"], key=lambda x: x["id"])
        else:
            q["choices"] = []

    questions = [q for q in questions if q["choices"]]

    if not questions:
        return

    stats["sorulu_topic"] += 1

    # ── 2) Slug'ları DB'den al ────────────────────────────────────────────────
    grade_slug  = get_slug(grade,  "name")
    lesson_slug = get_slug(lesson, "name")
    unit_slug   = get_slug(unit,   "title")
    topic_slug  = get_slug(topic,  "title")

    questions_url = f"/{grade_slug}/{lesson_slug}/{unit_slug}/{topic_slug}-sorular/"
    content_url   = f"/{grade_slug}/{lesson_slug}/{unit_slug}/{topic_slug}/"

    # ── 3) SEO üret ──────────────────────────────────────────────────────────
    seo_title, seo_description = make_seo(topic, unit, grade, lesson, questions=questions)

    # ── 4) HTML üret ─────────────────────────────────────────────────────────
    template = env.get_template("questions.html")

    html = template.render(
        site_name=SITE_NAME,
        site_url=SITE_URL,
        adsense_client=ADSENSE_CLIENT,
        grade=grade,
        lesson=lesson,
        unit=unit,
        topic=topic,
        questions=questions,
        content_page_url=content_url,
        seo_title=seo_title,
        seo_description=seo_description,
        breadcrumb=[
            (grade["name"],                f"/{grade_slug}/"),
            (lesson["name"],               f"/{grade_slug}/{lesson_slug}/"),
            (unit["title"],                f"/{grade_slug}/{lesson_slug}/{unit_slug}/"),
            (f"{topic['title']} Soruları", None),
        ],
    )

    unit_path = output_dir / grade_slug / lesson_slug / unit_slug
    ensure_dir(unit_path)

    questions_file = unit_path / f"{topic_slug}-sorular.html"
    questions_file.write_text(html, encoding="utf-8")

    sitemap_urls.append((questions_url, datetime.now().isoformat()))
    stats["soru_sayfasi"] += 1

    print(f"   ✅ {questions_url} ({len(questions)} soru)")


# ── Konu İçerik Sayfası Üretici ──────────────────────────────────────────────

def generate_topic_page(sb, env, output_dir, grade, lesson, unit, topic, sitemap_urls, stats):
    """Bir topic için içerik sayfası oluşturur."""

    # ── 1) İçerikler — sadece yayınlanmış olanlar ────────────────────────────
    contents = (sb.table("topic_contents")
                  .select("*")
                  .eq("topic_id", topic["id"])
                  .eq("is_published", True)
                  .order("order_no")
                  .execute().data)

    if not contents:
        print(f"   ⊘ Yayınlanmış içerik yok: {topic['title']}")
        return

    stats["icerikli_topic"] = stats.get("icerikli_topic", 0) + 1

    # ── 2) Kazanımlar ────────────────────────────────────────────────────────
    outcomes = (sb.table("outcomes")
                  .select("*, outcome_weeks(*)")
                  .eq("topic_id", topic["id"])
                  .execute().data)

    # ── 3) Soru sayısı ───────────────────────────────────────────────────────
    q_usages = (sb.table("question_usages")
                  .select("question_id")
                  .eq("topic_id", topic["id"])
                  .execute().data)

    has_questions   = len(q_usages) > 0
    questions_count = len(q_usages)

    # ── 4) Slug'ları DB'den al ────────────────────────────────────────────────
    grade_slug  = get_slug(grade,  "name")
    lesson_slug = get_slug(lesson, "name")
    unit_slug   = get_slug(unit,   "title")
    topic_slug  = get_slug(topic,  "title")

    content_url   = f"/{grade_slug}/{lesson_slug}/{unit_slug}/{topic_slug}/"
    questions_url = f"/{grade_slug}/{lesson_slug}/{unit_slug}/{topic_slug}-sorular/"

    # ── 5) SEO üret ──────────────────────────────────────────────────────────
    seo_title, seo_description = make_seo(topic, unit, grade, lesson, contents=contents)
    lesson_topics = get_lesson_topics(
        sb, grade, lesson, topic["id"],
        only_unit_id=None,
        include_current=True
    )
    unit_related_topics = [
        t for t in lesson_topics
        if t["unit_title"] == unit["title"] and not t["is_current"]
    ]

    # ── 6) HTML üret ─────────────────────────────────────────────────────────
    template = env.get_template("topic.html")

    html = template.render(
        site_name=SITE_NAME,
        site_url=SITE_URL,
        adsense_client=ADSENSE_CLIENT,
        grade=grade,
        lesson=lesson,
        unit=unit,
        topic=topic,
        contents=contents,
        outcomes=outcomes,
        unit_related_topics=unit_related_topics,
        lesson_topics=lesson_topics,
        has_questions=has_questions,
        questions_count=questions_count,
        questions_page_url=questions_url,
        seo_title=seo_title,
        seo_description=seo_description,
        breadcrumb=[
            (grade["name"],  f"/{grade_slug}/"),
            (lesson["name"], f"/{grade_slug}/{lesson_slug}/"),
            (unit["title"],  f"/{grade_slug}/{lesson_slug}/{unit_slug}/"),
            (topic["title"], None),
        ],
    )

    unit_path = output_dir / grade_slug / lesson_slug / unit_slug
    ensure_dir(unit_path)

    topic_file = unit_path / f"{topic_slug}.html"
    topic_file.write_text(html, encoding="utf-8")

    sitemap_urls.append((content_url, datetime.now().isoformat()))
    stats["konu_sayfasi"] = stats.get("konu_sayfasi", 0) + 1

    print(f"   ✅ {content_url}")
