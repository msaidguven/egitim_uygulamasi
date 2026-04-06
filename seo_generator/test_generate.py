"""
test_generate.py
────────────────
Mock data ile HTML üretimini test eder (Supabase bağlantısı gerektirmez).
"""
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

# Mock data
mock_data = {
    'grade':  {'id': 1, 'name': '5. Sınıf'},
    'lesson': {'id': 1, 'name': 'Fen Bilimleri'},
    'unit':   {'id': 1, 'title': 'Güneş Sistemi ve Tutulma', 'slug': 'gunes-sistemi'},
    'topic':  {'id': 1, 'title': 'Güneş Tutulması', 'slug': 'gunes-tutulmasi'},
    'contents': [
        {
            'id': 1,
            'title': 'Güneş Tutulması Nedir?',
            'content': '<p>Güneş tutulması, Ay\'ın Dünya ile Güneş arasına girmesiyle oluşan doğa olayıdır.</p>'
        },
        {
            'id': 2,
            'title': 'Güneş Tutulması Türleri',
            'content': '<p>Tam tutulma, kısmi tutulma ve halka tutulma olmak üzere üç çeşit güneş tutulması vardır.</p>'
        }
    ],
    'outcomes': [
        {
            'id': 1,
            'description': 'a) Güneş tutulmasının niteliklerini tanımlar.',
            'outcome_weeks': [{'start_week': 3, 'end_week': 3}]
        },
        {
            'id': 2,
            'description': 'b) Güneş tutulması ile ilgili topladığı verileri kaydeder.',
            'outcome_weeks': [{'start_week': 3, 'end_week': 4}]
        }
    ],
    # ✅ Düzeltme 3: has_questions, questions_count, questions_page_url eklendi
    'has_questions': True,
    'questions_count': 5,
    'questions_page_url': '/5-sinif/fen-bilimleri/gunes-sistemi/gunes-tutulmasi-sorular/',
    'breadcrumb': [
        ('5. Sınıf',                    '/5-sinif/'),
        ('Fen Bilimleri',               '/5-sinif/fen-bilimleri/'),
        ('Güneş Sistemi ve Tutulma',    '/5-sinif/fen-bilimleri/gunes-sistemi/'),
        ('Güneş Tutulması',             None),
    ]
}

# Mock data - sorular sayfası için
mock_questions_data = {
    'grade':  {'id': 1, 'name': '5. Sınıf'},
    'lesson': {'id': 1, 'name': 'Fen Bilimleri'},
    'unit':   {'id': 1, 'title': 'Güneş Sistemi ve Tutulma', 'slug': 'gunes-sistemi'},
    'topic':  {'id': 1, 'title': 'Güneş Tutulması', 'slug': 'gunes-tutulmasi'},
    'content_page_url': '/5-sinif/fen-bilimleri/gunes-sistemi/gunes-tutulmasi/',
    'questions': [
        {
            'id': 1,
            'question_text': 'Güneş tutulması hangi durumda gerçekleşir?',
            'difficulty': 1,
            'solution_text': 'Ay, Dünya ile Güneş arasına girdiğinde Güneş tutulması oluşur.',
            'choices': [
                {'id': 1, 'choice_text': 'Dünya, Ay ile Güneş arasına girince',  'is_correct': False},
                {'id': 2, 'choice_text': 'Ay, Dünya ile Güneş arasına girince',  'is_correct': True},
                {'id': 3, 'choice_text': 'Güneş, Ay ile Dünya arasına girince',  'is_correct': False},
                {'id': 4, 'choice_text': 'Dünya kendi çevresinde döndüğünde',    'is_correct': False},
            ]
        },
        {
            'id': 2,
            'question_text': 'Aşağıdakilerden hangisi güneş tutulması çeşitlerinden biri değildir?',
            'difficulty': 2,
            'solution_text': 'Güneş tutulması tam, kısmi ve halka olmak üzere üç türdür. Yarım tutulma yoktur.',
            'choices': [
                {'id': 5, 'choice_text': 'Tam tutulma',    'is_correct': False},
                {'id': 6, 'choice_text': 'Kısmi tutulma',  'is_correct': False},
                {'id': 7, 'choice_text': 'Halka tutulma',  'is_correct': False},
                {'id': 8, 'choice_text': 'Yarım tutulma',  'is_correct': True},
            ]
        },
    ],
    'breadcrumb': [
        ('5. Sınıf',                        '/5-sinif/'),
        ('Fen Bilimleri',                   '/5-sinif/fen-bilimleri/'),
        ('Güneş Sistemi ve Tutulma',        '/5-sinif/fen-bilimleri/gunes-sistemi/'),
        ('Güneş Tutulması Soruları',        None),
    ]
}


def make_env(templates_dir: str = "templates") -> Environment:
    """
    Jinja2 Environment'ı oluşturur ve custom filter'ları render'dan ÖNCE ekler.
    """
    env = Environment(loader=FileSystemLoader(templates_dir))
    # ✅ Düzeltme 1 & 2: choice_letter filter render öncesinde eklendi
    env.filters['choice_letter'] = lambda i: chr(65 + i)
    return env


def test_topic():
    print("🧪 topic.html testi başlatılıyor...")

    env = make_env()
    template = env.get_template('topic.html')

    html = template.render(
        site_name="Eğitim Portalı",
        site_url="https://example.com",
        adsense_client="ca-pub-XXXXXXXXXXXXXXXX",
        **mock_data
    )

    output_dir = Path("output/test")
    output_dir.mkdir(parents=True, exist_ok=True)

    output_file = output_dir / "gunes-tutulmasi.html"
    output_file.write_text(html, encoding='utf-8')

    print(f"✅ topic.html oluşturuldu: {output_file}")
    print(f"   Dosya boyutu: {len(html)} bytes")


def test_questions():
    print("🧪 questions.html testi başlatılıyor...")

    env = make_env()
    template = env.get_template('questions.html')

    html = template.render(
        site_name="Eğitim Portalı",
        site_url="https://example.com",
        adsense_client="ca-pub-XXXXXXXXXXXXXXXX",
        **mock_questions_data
    )

    output_dir = Path("output/test")
    output_dir.mkdir(parents=True, exist_ok=True)

    output_file = output_dir / "gunes-tutulmasi-sorular.html"
    output_file.write_text(html, encoding='utf-8')

    print(f"✅ questions.html oluşturuldu: {output_file}")
    print(f"   Dosya boyutu: {len(html)} bytes")
    print(f"\nTarayıcıda aç:")
    print(f"  file://{(output_dir / 'gunes-tutulmasi.html').absolute()}")
    print(f"  file://{output_file.absolute()}")


if __name__ == "__main__":
    test_topic()
    print()
    test_questions()
