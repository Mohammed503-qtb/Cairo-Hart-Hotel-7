# Build & Release Guide

This document explains exactly how to build, sign, and publish the Cairo Heart
Hotel app for **commercial production** use.

> The `release.yml` GitHub Actions workflow handles 95% of this automatically.
> This guide explains the manual prerequisites (signing keys, Supabase setup,
> store listings) that the workflow cannot do for you.

---

## Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [One-time setup: signing keys & secrets](#2-one-time-setup-signing-keys--secrets)
3. [Triggering a release](#3-triggering-a-release)
4. [What the workflow does](#4-what-the-workflow-does)
5. [Manual local build (no CI)](#5-manual-local-build-no-ci)
6. [Deploying the web bundle](#6-deploying-the-web-bundle)
7. [Deploying the backend](#7-deploying-the-backend)
8. [Publishing to Google Play](#8-publishing-to-google-play)
9. [Publishing to App Store](#9-publishing-to-app-store)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites

| Tool | Version | Why |
|---|---|---|
| Flutter SDK | `3.27.4` (stable) | Build all platforms |
| Dart SDK | bundled with Flutter | — |
| Bun | latest | Build Next.js backend |
| Java | 17 (Temurin) | Android build |
| Xcode | latest stable | iOS build (macOS only) |
| Supabase CLI | latest | Push schema & migrations |

> The CI/Release workflows install Flutter, Java, Xcode, and Bun for you.

---

## 2. One-time setup: signing keys & secrets

### 2a. Create an Android release keystore

On your local machine (this stays private — never commit it):

```bash
keytool -genkey -v \
  -keystore cairo-heart-hotel.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cairo-heart-hotel
```

You'll be prompted for:
- Keystore password
- Key password
- Your name, organization, city, country

Encode it as base64 for storage as a GitHub Secret:

```bash
base64 -i cairo-heart-hotel.jks | tr -d '\n'
```

### 2b. Add GitHub Secrets

In your repository → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret name | Value |
|---|---|
| `PRODUCTION_API_BASE` | e.g. `https://api.cairoheart.ye` (the URL your Flutter app calls) |
| `ANDROID_KEYSTORE_BASE64` | The base64 string from §2a |
| `ANDROID_STORE_PASSWORD` | Your keystore password |
| `ANDROID_KEY_PASSWORD` | Your key password |
| `ANDROID_KEY_ALIAS` | `cairo-heart-hotel` (or whatever you chose) |

> **If you skip the Android signing secrets**, the workflow still builds an
> APK, but it will be debug-signed. Real devices will install it (after enabling
> "Install unknown apps"), but Google Play will reject it.

### 2c. Provision an iOS developer profile (for App Store)

This is **outside** what GitHub Actions can do for you:

1. Enroll in the Apple Developer Program ($99/year) — <https://developer.apple.com>
2. In Xcode → Settings → Accounts → Add your Apple ID
3. In Apple Developer Portal → Certificates, Identifiers & Profiles:
   - Create an App ID for `ye.cairoheart.hotel`
   - Create an iOS Distribution certificate
   - Create a provisioning profile linked to that cert and App ID
4. Download the `.cer` file and the provisioning profile, import both into Xcode
5. Open `mobile/ios/Runner.xcworkspace` and select the Runner target → Signing & Capabilities → select your team

After this, build with `flutter build ipa --release` locally — the workflow's
`--no-codesign` builds are **unsigned** and require you to re-sign with
`xcrun altool` or upload to TestFlight via Transporter.

---

## 3. Triggering a release

```bash
# Tag a version (semver: vMAJOR.MINOR.PATCH, optionally with -rc.N suffix)
git tag v1.0.0
git push origin v1.0.0
```

That's it. Pushing the tag triggers the **Release** workflow, which:

1. Builds Flutter Web (production bundle)
2. Builds Android APKs (split-per-ABI + universal fat APK, optionally signed)
3. Builds iOS IPA (unsigned, requires re-signing before distribution)
4. Builds Next.js standalone backend
5. Creates a GitHub Release with all artifacts attached

Pre-release tags like `v1.0.0-rc.1` are automatically marked as **pre-release**.

### Manual dispatch

You can also trigger a release from the **Actions** tab → "Release" workflow →
"Run workflow" → enter a version tag → "Run workflow".

---

## 4. What the workflow does

### `release.yml` pipeline

```
prepare
   │
   ├── build-web        (Ubuntu) → Flutter Web bundle (.zip)
   ├── build-android    (Ubuntu) → Android APKs (arm64, armv7, x86_64, universal)
   ├── build-ios        (macOS)  → iOS IPA (unsigned, packaged as .ipa)
   └── build-backend    (Ubuntu) → Next.js standalone bundle (.tar.gz)
        │
        └── release (Ubuntu) → GitHub Release with all artifacts
```

The pipeline:
- Runs in **parallel** where possible
- Has **30–60 min** timeouts per job
- Uses the GitHub-provided `GITHUB_TOKEN` to create the release (no extra secret needed)
- Generates build provenance attestations (SLSA-style) for the Web bundle

### `ci.yml` pipeline (runs on every push)

```
flutter-ci   → flutter pub get → flutter analyze → flutter build web (smoke)
backend-ci   → bun install → prisma generate → next build (standalone)
```

Both jobs must pass before merging to `main`.

---

## 5. Manual local build (no CI)

If you need to build locally (e.g. to debug a signing issue):

### 5a. Flutter Web

```bash
cd mobile
flutter build web --release --base-href "/flutter-static/"
# Output: mobile/build/web/
```

### 5b. Android APK

```bash
cd mobile

# Scaffold the android/ folder if missing
flutter create --platforms=android --project-name cairo_heart_hotel .

# Create android/key.properties (NEVER commit)
cat > android/key.properties <<EOF
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=<your-alias>
storeFile=<path-to>/cairo-heart-hotel.jks
EOF

# Build per-ABI APKs
flutter build apk --release --split-per-abi

# Or universal fat APK
flutter build apk --release
```

Output: `mobile/build/app/outputs/flutter-apk/*.apk`

### 5c. iOS (macOS only)

```bash
cd mobile
flutter create --platforms=ios --project-name cairo_heart_hotel .
open ios/Runner.xcworkspace   # configure signing in Xcode first
flutter build ipa --release
# Output: mobile/build/ios/ipa/Runner.ipa
```

---

## 6. Deploying the web bundle

The Flutter web build is a static bundle — deploy it to any static host:

### Option A: Vercel / Netlify / Cloudflare Pages

1. Unzip `cairo-heart-hotel-web-v{VERSION}.zip`
2. Upload the `web/` folder as the static root
3. Add a redirect rule: `/* /index.html 200` (for SPA routing)

### Option B: Bundle with the Next.js backend

```bash
# The backend already serves /flutter-static/ — drop the unzipped web/ folder
# at <backend-root>/public/flutter-static/
bun run build    # builds both Flutter web (→ public/flutter-static/) and Next.js
```

### Option C: Nginx / Caddy

```nginx
server {
  listen 80;
  root /var/www/cairo-heart-hotel/web;
  location / { try_files $uri /index.html; }
}
```

---

## 7. Deploying the backend

The Next.js standalone build produces a self-contained server bundle:

```bash
# Extract
tar -xzf cairo-heart-hotel-backend-v{VERSION}.tar.gz

# Configure
cp .env.example .env
#   → fill in real Supabase keys, DATABASE_URL, etc.

# Run
bun server/server.js
# Listens on $PORT (default 3000)
```

For production, run behind a reverse proxy (Caddy / Nginx) with TLS:

```caddyfile
api.cairoheart.ye {
  reverse_proxy localhost:3000
}
```

Set `PRODUCTION_API_BASE=https://api.cairoheart.ye` as a GitHub Secret before
triggering the release — the Flutter app will then call this URL.

---

## 8. Publishing to Google Play

1. **Sign the APK** (skip if you set the ANDROID_KEYSTORE_* secrets — the
   workflow already produces a signed APK).
2. Create a Google Play Console developer account ($25 one-time).
3. In Play Console → Create app → fill in app details.
4. Go to **Production → Create release**.
5. Upload the universal APK (or the per-ABI APKs for smaller download size).
6. Complete the Store Listing:
   - App name: **فندق قلب القاهرة**
   - Short description (Arabic, ≤80 chars): منصة عمليات فندقية متكاملة — حجوزات، خدمات، إدارة.
   - Full description (Arabic, ≤4000 chars): Describe features in Arabic.
   - App icon: 512×512 PNG.
   - Feature graphic: 1024×500 PNG.
   - Phone screenshots: at least 2 (min 320px wide).
   - Categorization: Travel & Local / Business.
   - Privacy policy URL: required.
7. Submit for review (usually 1–3 days for first-time submissions).

### Internal testing (instant)

For instant testing before going public:

1. Play Console → **Testing → Internal testing → Create release**
2. Upload APK → add release notes → Save → Review release → Start rollout
3. Copy the opt-in URL → share with testers
4. Testers install from the Play Store using that link

---

## 9. Publishing to App Store

1. Re-sign the unsigned IPA produced by the workflow:

   ```bash
   # On a Mac with your developer cert + provisioning profile installed
   xcrun altool --upload-app \
     -f cairo-heart-hotel-ios-v{VERSION}.ipa \
     -t ios \
     -u <your-apple-id> \
     -p <app-specific-password>
   ```

   Or, easier: open Xcode → Window → Organizer → drag the IPA in.

2. **App Store Connect → My Apps → + → New App**:
   - Platforms: iOS
   - Name: **فندق قلب القاهرة**
   - Primary language: Arabic
   - Bundle ID: `ye.cairoheart.hotel` (matches what the workflow sets)
   - SKU: `cairo-heart-hotel-ios`

3. Complete App Information, Pricing (free), Availability (Yemen + target countries).

4. Under the iOS App Info tab → Build → select the build you uploaded in §1.

5. Add:
   - Screenshots (6.7" iPhone required, 12.9" iPad optional)
   - App description (Arabic, ≤4000 chars)
   - Keywords (Arabic, ≤100 chars)
   - Support URL (Arabic page)
   - Privacy policy URL

6. Submit for review (usually 24–48 hours for first-time submissions).

---

## 10. Troubleshooting

### "flutter create" overwrites my files?

No — `flutter create --platforms=... .` only adds missing files and folders. It
will not touch existing `lib/`, `pubspec.yaml`, or `web/index.html`.

### iOS build fails with code-signing error

The workflow uses `--no-codesign`. The IPA it produces is **unsigned** and
cannot be installed directly on a device. Re-sign locally as described in §9.

If you want CI to produce a signed IPA, you need to set up fastlane match or
similar, which is beyond the scope of this guide.

### Android APK installs but the app crashes immediately

Check the API base URL. The workflow uses `--dart-define=API_BASE=...` from the
`PRODUCTION_API_BASE` secret. If it's empty, the app uses relative paths — which
only work when the app is served from the same origin as the backend. For a
native Android app, you MUST set `PRODUCTION_API_BASE` to an absolute URL.

### Release workflow never triggers on tag push

Verify the tag matches `v*` (e.g. `v1.0.0`, not `1.0.0`). Check the workflow's
`on.push.tags` filter in `.github/workflows/release.yml`.

### Build artifact is missing from the release

The `release` job's "Check upstream build status" step aborts the release if any
required job failed. iOS failures are non-fatal (the IPA is just omitted). Check
the workflow logs for the specific job that failed.

### Pruning old release artifacts

GitHub Release artifacts are kept indefinitely. To prune, use `gh release delete`
or the GitHub UI. The `actions/upload-artifact` artifacts (not attached to the
release) auto-expire after 14 days.
