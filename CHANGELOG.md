# Changelog

All notable changes to the **Lumière Grand Hotel Platform** are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] — 2026-08-30

### Added
- **Cross-platform Flutter app** (Web, Android, iOS, macOS, Windows, Linux) from one codebase.
- **Public website**: Home, Rooms, Room details, Gallery, Contact + 5-step booking flow + WhatsApp confirmation.
- **Guest app**: 6-digit activation, stay home with access code, service catalog, request tracking with chat, bill view, extension/room-change/checkout requests, reception chat, notifications.
- **Reception / PMS**: dashboard KPIs, arrivals/departures/in-house/reservations, rooms board with colored states, requests center (kanban), full check-in workflow (verify → assign room → create stay → generate access code), checkout with balance settlement.
- **Admin**: dashboard, room types, services catalog, users, audit log.
- **Single source of truth** in-memory store with full business rules: availability, price calculation, reservation lifecycle, request lifecycle, ledger billing, extensions, room transfers, audit trail.
- **i18n + RTL**: Arabic (default) and English, instant toggle, full RTL/LTR.
- **Theme**: warm-gold hospitality palette, light/dark modes.
- **Responsive**: mobile (drawer/bottom nav) vs desktop (navigation rail) layouts.
- **CI workflow**: flutter analyze + test on every push/PR.
- **Release workflow**: builds Web, Android APK, Android AAB, iOS IPA, with SHA-256 checksums + auto GitHub Release.
- **Deploy workflow**: publishes Web build to GitHub Pages on release.
- **Demo deep-links** (`/demo/reception`, `/demo/admin`, `/demo/guest`) for showcase.

### Security
- Reservation vs Stay separation enforced (no leakage of guest data across stays).
- Guest access codes are stay-scoped, time-limited, revocable.
- All sensitive operations create audit entries.

[Unreleased]: https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/releases/tag/v1.0.0
