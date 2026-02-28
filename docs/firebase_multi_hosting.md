# Firebase Multi Hosting (App + SEO)

This project now uses two Hosting targets:

- `app`: Flutter Web SPA (`build/web`)
- `seo`: Static SEO HTML pages (`seo_output`)

## 1) Create second hosting site (one-time)

If `derstakipnet1-seo` does not exist yet, create it:

```bash
firebase hosting:sites:create derstakipnet1-seo
```

If you prefer another site id, update `.firebaserc` target `seo` accordingly.

## 2) Sync generated SEO files into this repo

```bash
./scripts/sync_seo_output.sh
```

This copies from:

`/home/msaid/İndirilenler/seo_generator/output`

into:

`./seo_output`

## 3) Build and deploy

App only:

```bash
flutter build web
firebase deploy --only hosting:app
```

SEO only:

```bash
firebase deploy --only hosting:seo
```

Both:

```bash
flutter build web
firebase deploy --only hosting
```

## Notes

- `app` target keeps SPA rewrite to `/index.html`.
- `seo` target has no SPA rewrite, so static HTML is served directly.
- `seo` target enables `cleanUrls` and `trailingSlash: false`.
- If your SEO generator emits links with trailing slash (e.g. `/slug/`), verify they resolve correctly against your output naming (`slug.html`).
