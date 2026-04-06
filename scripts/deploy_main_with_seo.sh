#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/web"
SEO_DIR="$ROOT_DIR/seo_output"
SOURCE_DIR="/home/msaid/Masaüstü/app/mobil/egitim_uygulamasi/seo_generator/output"

slug_to_label() {
  local slug="$1"
  if [[ -z "$slug" ]]; then
    echo "Ana Sayfa"
    return
  fi
  echo "$slug" | tr '-' ' '
}

join_url() {
  local left="$1"
  local right="$2"
  if [[ "$left" == "/" ]]; then
    echo "/$right"
  else
    echo "$left/$right"
  fi
}

render_dir_index() {
  local dir="$1"
  local rel="${dir#"$SEO_DIR"}"
  rel="${rel#/}"

  local path="/"
  if [[ -n "$rel" ]]; then
    path="/$rel"
  fi

  local title
  title="$(slug_to_label "$(basename "$rel")")"

  local parent_path=""
  if [[ -n "$rel" ]]; then
    local parent_rel
    parent_rel="$(dirname "$rel")"
    if [[ "$parent_rel" == "." ]]; then
      parent_path="/"
    else
      parent_path="/$parent_rel"
    fi
  fi

  mapfile -t child_dirs < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  mapfile -t child_pages < <(
    find "$dir" -mindepth 1 -maxdepth 1 -type f -name '*.html' \
      ! -name 'index.html' ! -name '404.html' -printf '%f\n' | sort
  )

  {
    cat <<'HTML_HEAD'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Ders Icerikleri</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 860px; margin: 40px auto; padding: 0 16px; line-height: 1.5; }
    h1 { margin-bottom: 8px; text-transform: capitalize; }
    h2 { margin: 16px 0 8px; font-size: 18px; }
    ul { padding-left: 20px; }
    li { margin: 6px 0; }
    .muted { color: #555; font-size: 14px; }
    .legal-links { margin-top: 20px; padding-top: 12px; border-top: 1px solid #e5e7eb; display: flex; gap: 12px; flex-wrap: wrap; }
  </style>
</head>
<body>
HTML_HEAD

    printf '  <h1>%s</h1>\n' "$title"
    printf '  <p class="muted">Konum: <code>%s</code></p>\n' "$path"

    if [[ -n "$parent_path" ]]; then
      printf '  <p><a href="%s">← Ust klasor</a></p>\n' "$parent_path"
    fi

    if [[ ${#child_dirs[@]} -gt 0 ]]; then
      echo '  <h2>Klasorler</h2>'
      echo '  <ul>'
      for child in "${child_dirs[@]}"; do
        child_url="$(join_url "$path" "$child")"
        child_label="$(slug_to_label "$child")"
        printf '    <li><a href="%s">%s</a></li>\n' "$child_url" "$child_label"
      done
      echo '  </ul>'
    fi

    if [[ ${#child_pages[@]} -gt 0 ]]; then
      echo '  <h2>Icerikler</h2>'
      echo '  <ul>'
      for page in "${child_pages[@]}"; do
        page_slug="${page%.html}"
        page_url="$(join_url "$path" "$page_slug")"
        page_label="$(slug_to_label "$page_slug")"
        printf '    <li><a href="%s">%s</a></li>\n' "$page_url" "$page_label"
      done
      echo '  </ul>'
    fi

    if [[ ${#child_dirs[@]} -eq 0 && ${#child_pages[@]} -eq 0 ]]; then
      echo '  <p>Bu klasorde goruntulenecek icerik bulunamadi.</p>'
    fi

    echo '  <div class="legal-links">'
    echo '    <a href="/privacy-policy">Gizlilik Politikası</a>'
    echo '    <a href="/about">Hakkımızda</a>'
    echo '    <a href="/contact">İletişim</a>'
    echo '    <a href="/sitemap.xml">Site Haritası</a>'
    echo '  </div>'

    cat <<'HTML_FOOT'
</body>
</html>
HTML_FOOT
  } > "$dir/index.html"
}

sync_seo_output() {
  if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Source not found: $SOURCE_DIR" >&2
    exit 1
  fi

  mkdir -p "$SEO_DIR"
  rsync -a --delete "$SOURCE_DIR"/ "$SEO_DIR"/

  mapfile -t all_dirs < <(find "$SEO_DIR" -type d | sort)
  for dir in "${all_dirs[@]}"; do
    render_dir_index "$dir"
  done

  cat > "$SEO_DIR/404.html" <<'HTML_404'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Sayfa Bulunamadi</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 760px; margin: 40px auto; padding: 0 16px; line-height: 1.5; }
    .legal-links { margin-top: 20px; padding-top: 12px; border-top: 1px solid #e5e7eb; display: flex; gap: 12px; flex-wrap: wrap; }
  </style>
</head>
<body>
  <h1>Sayfa Bulunamadi</h1>
  <p>Aradiginiz sayfa mevcut degil veya tasinmis olabilir.</p>
  <p><a href="/">Ana sayfaya don</a></p>
  <div class="legal-links">
    <a href="/privacy-policy">Gizlilik Politikası</a>
    <a href="/about">Hakkımızda</a>
    <a href="/contact">İletişim</a>
    <a href="/sitemap.xml">Site Haritası</a>
  </div>
</body>
</html>
HTML_404
}

cd "$ROOT_DIR"

echo "[1/4] Flutter web build aliniyor..."
flutter build web

echo "[2/4] SEO icerikleri senkronlaniyor..."
sync_seo_output

echo "[3/4] SEO dosyalari build/web icine birlestiriliyor..."
# Root index/404 flutter app'e ait kalmali. SEO tarafindan ezilmez.
rsync -a \
  --exclude "/index.html" \
  --exclude "/404.html" \
  "$SEO_DIR"/ "$BUILD_DIR"/

echo "[4/4] Ana hosting'e deploy ediliyor..."
firebase deploy --only hosting:app

echo "Tamamlandi. Flutter app /'de, mevcut SEO HTML dosyalari kendi URL'lerinde servis edilir."
