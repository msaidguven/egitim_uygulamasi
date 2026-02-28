#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="/home/msaid/İndirilenler/seo_generator/output"
TARGET_DIR="$(cd "$(dirname "$0")/.." && pwd)/seo_output"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source not found: $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
rsync -a --delete "$SOURCE_DIR"/ "$TARGET_DIR"/

# Create a root index page so Firebase Hosting doesn't return default 404 at `/`.
mapfile -t TOP_LEVEL_DIRS < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
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
    h1 { margin-bottom: 8px; }
    ul { padding-left: 20px; }
    li { margin: 6px 0; }
  </style>
</head>
<body>
  <h1>Ders Icerikleri</h1>
  <p>Asagidaki sinif sayfalarindan birini secin:</p>
  <ul>
HTML_HEAD

  for dir in "${TOP_LEVEL_DIRS[@]}"; do
    first_html="$(find "$TARGET_DIR/$dir" -type f -name '*.html' | sort | head -n 1 || true)"
    if [[ -z "$first_html" ]]; then
      continue
    fi
    rel_path="${first_html#"$TARGET_DIR"/}"
    clean_path="${rel_path%.html}"
    printf '    <li><a href="/%s">%s</a></li>\n' "$clean_path" "$dir"
  done

  cat <<'HTML_FOOT'
  </ul>
  <p><a href="/sitemap.xml">Sitemap</a></p>
</body>
</html>
HTML_FOOT
} > "$TARGET_DIR/index.html"

# Add a custom 404 to avoid Firebase default "Page Not Found" screen.
cat > "$TARGET_DIR/404.html" <<'HTML_404'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Sayfa Bulunamadi</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 760px; margin: 40px auto; padding: 0 16px; line-height: 1.5; }
  </style>
</head>
<body>
  <h1>Sayfa Bulunamadi</h1>
  <p>Aradiginiz sayfa mevcut degil veya tasinmis olabilir.</p>
  <p><a href="/">Ana sayfaya don</a></p>
</body>
</html>
HTML_404

echo "SEO output synced to: $TARGET_DIR"
