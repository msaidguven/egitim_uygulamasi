#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT_DIR"

echo "[1/2] Flutter web build aliniyor..."
flutter build web

echo "[2/2] Ana hosting'e deploy ediliyor (SEO olmadan)..."
firebase deploy --only hosting:app

echo "Tamamlandi. Flutter app sadece derstakipnet1'e deploy edildi."