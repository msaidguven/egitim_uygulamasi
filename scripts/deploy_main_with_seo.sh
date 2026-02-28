#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/web"
SEO_DIR="$ROOT_DIR/seo_output"

cd "$ROOT_DIR"

echo "[1/4] Flutter web build aliniyor..."
flutter build web

echo "[2/4] SEO icerikleri senkronlaniyor..."
"$ROOT_DIR/scripts/sync_seo_output.sh"

echo "[3/4] SEO dosyalari build/web icine birlestiriliyor..."
# Root index/404 flutter app'e ait kalmali. SEO tarafindan ezilmez.
rsync -a \
  --exclude "index.html" \
  --exclude "404.html" \
  "$SEO_DIR"/ "$BUILD_DIR"/

echo "[4/4] Ana hosting'e deploy ediliyor..."
firebase deploy --only hosting:app

echo "Tamamlandi. Flutter app /'de, mevcut SEO HTML dosyalari kendi URL'lerinde servis edilir."
