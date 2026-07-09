# Ship Retrofit Factory 3D as an Android app (TWA)

The game is now an installable **PWA** — a web-app manifest, a service worker that
caches the whole self-contained HTML for **offline play**, and app icons. An Android
app is then just a thin **TWA** (Trusted Web Activity) shell that renders this PWA
full-screen in Chrome — no game code is rewritten, and every update you push to the
web build reaches the app automatically.

This repo ships the whole web layer. The steps below (Bubblewrap → APK/AAB →
Play Store) need an **Android SDK + JDK**, so run them on your own machine — they
can't be done inside this repo's CI container.

## What's already done (in this repo)

- `retrofit3d/manifest.webmanifest` — name, icons, `display: standalone`, colors, scope.
- `retrofit3d/sw.js` — service worker (network-first, offline fallback). Registered from the game's `<head>`.
- `retrofit3d/icons/` — `icon-192.png`, `icon-512.png`, `icon-512-maskable.png`.
- `retrofit3d/twa/twa-manifest.json` — a ready Bubblewrap config.
- `retrofit3d/twa/assetlinks.template.json` — the Digital Asset Links file to host.

Deployed PWA URL (auto-published from `main` via GitHub Pages):
`https://tlaba.github.io/workbench/retrofit3d/retrofit-factory-3d.html`

## 1 · Confirm the PWA is live

Open the URL above on Android Chrome → you should get an **"Install app"** / "Add to
Home screen" prompt. (Verified here: manifest valid, service worker active, offline
reload works.) If the install prompt doesn't show, run Lighthouse → PWA in Chrome DevTools.

## 2 · Generate the Android project with Bubblewrap

```bash
npm install -g @bubblewrap/cli
bubblewrap doctor            # installs/points at JDK 17 + Android SDK if needed
```

Then either use the config in this repo, or let Bubblewrap generate one:

```bash
# option A — from the deployed web manifest (interactive; simplest)
bubblewrap init --manifest https://tlaba.github.io/workbench/retrofit3d/manifest.webmanifest

# option B — start from the reference config in this repo
cp retrofit3d/twa/twa-manifest.json ./twa-manifest.json
bubblewrap init --manifest ./twa-manifest.json
```

Answer the prompts. **Set a permanent `packageId`** (e.g. `io.github.tlaba.retrofit`)
— it can't change after your first Play Store upload. Bubblewrap creates an
Android signing keystore; **back it up and remember the passwords** (losing it means
you can never update the app).

## 3 · Build

```bash
bubblewrap build
```

Produces:
- `app-release-signed.apk` — sideload to test (`adb install -r app-release-signed.apk`)
- `app-release-bundle.aab` — upload this to the Play Store

## 4 · Wire up Digital Asset Links (removes the URL bar)

This is the step that makes it feel native instead of a browser tab. The app and the
site must vouch for each other.

1. After `bubblewrap build`, Bubblewrap prints (and writes) an `assetlinks.json` with
   your app's SHA-256 signing fingerprint. (You can also get it with
   `keytool -list -v -keystore android.keystore -alias android`.)
2. Host it at the **origin root** — `https://tlaba.github.io/.well-known/assetlinks.json`.
   ⚠️ NOT under `/workbench/`. Chrome only checks the origin root, so this file must go
   in your **user-site repo `tlaba.github.io`** at `.well-known/assetlinks.json`
   (create that repo if you don't have one — it's what serves `tlaba.github.io/`).
   Use `retrofit3d/twa/assetlinks.template.json` as the starting point.
3. If you use **Play App Signing** (recommended), Google re-signs your app, so add the
   **Play-provided app-signing SHA-256** (Play Console → Setup → App integrity) to the
   `sha256_cert_fingerprints` array **as well as** your upload-key fingerprint.
4. Verify: `https://tlaba.github.io/.well-known/assetlinks.json` returns the JSON, then
   reinstall the APK — the URL bar should be gone. (Google's statement-list tester:
   https://developers.google.com/digital-asset-links/tools/generator)

## 5 · Publish to Google Play

1. Create the app in the [Play Console](https://play.google.com/console), upload the
   `.aab`, keep **Play App Signing** on (then complete step 4.3).
2. Fill store listing (icon = `icon-512.png`), content rating, data-safety form,
   screenshots (grab from the running game), and roll out to internal testing first.

## Updating the app later

Push web changes to `main` as usual — they reach installed apps immediately (no
resubmission needed) because the TWA loads the live URL. You only rebuild/resubmit the
Android package when you change the **shell** (icon, name, target SDK, versionCode):

```bash
bubblewrap update      # picks up manifest changes
bubblewrap build       # bump appVersionCode in twa-manifest.json first
```

## Notes for this game specifically

- **Auth:** in a TWA the web Google-OAuth redirect flow works normally (it opens in the
  same Chrome), so the Supabase Google sign-in we discussed is the right fit — no native
  Google SDK needed.
- **Performance:** the tier-2 post-processing (SSAO + bloom) is GPU-heavy. Consider
  defaulting **Reduced Effects** on lower-end devices — it already bypasses the composer.
- **Orientation** is unlocked (`"any"`); the HUD adapts to portrait and landscape.
