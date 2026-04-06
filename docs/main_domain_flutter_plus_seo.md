# Tek Domain: Flutter + SEO HTML

Hedef davranis:
- `/` -> Flutter app (build/web/index.html)
- Eger URL'ye karsilik gelen statik HTML dosyasi varsa -> o dosya servis edilir
- Dosya yoksa -> Flutter app fallback

## Tek komut deploy

```bash
./scripts/deploy_main_with_seo.sh
```

Bu script su adimlari yapar:
1. `flutter build web`
2. `seo_generator/output` icerigini `seo_output` klasorune senkronlar
   (klasor indexleri ve `404.html` dosyasini da uretir)
3. `seo_output` dosyalarini `build/web` icine kopyalar (root `index.html` ve `404.html` haric)
4. `firebase deploy --only hosting:app`

## Neden calisiyor?

Firebase Hosting once dosya var mi diye bakar.
- Varsa dosyayi verir (SEO HTML)
- Yoksa rewrite ile `/index.html` verir (Flutter SPA)

`firebase.json` icinde `cleanUrls: true` oldugu icin
`/a/b/c` istegi otomatik olarak `/a/b/c.html` dosyasini da bulabilir.
