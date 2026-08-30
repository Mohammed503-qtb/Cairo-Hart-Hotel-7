# Changelog

All notable changes to the **Lumière Grand Hotel Platform** are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] — 2026-08-30

### Changed — Architecture (per PLAN §57, §58)
- **Removed the 4-card role-selection screen.** There are no longer buttons to
  enter the Admin or Reception panels. Access is determined by the code
  entered at the unified login screen.
- **Unified login screen** (`/login`): a single access code input. The system
  detects the code type and routes automatically:
  - Guest access code (stay-tied 6-digit) → Guest App (mobile-first)
  - Staff access code (admin-generated, role-embedded) → Reception or Admin
    dashboard, depending on the code's role.
- **Platform-aware entry**: on Web the public website is the home; on native
  (phone/desktop app) the app opens directly to the login screen — giving two
  distinct experiences from one codebase, exactly as PLAN §57 specifies ("the
  web and mobile experiences may have different layouts while sharing the same
  product rules and backend contracts").
- The **website** is now a proper public booking site (desktop-optimized hero,
  room browsing, 5-step booking) with a "Portal Login" button in the header.
- The **guest app** remains mobile-first (bottom navigation, FAB, large touch
  targets) — distinct from the desktop website.

### Added — Staff Access Codes (PLAN §4.1, §37)
- New `StaffAccess` domain model: code, staff name, role, createdAt, expiresAt,
  lastUsedAt, active.
- Admin panel → **Staff Access Codes** management screen: create new codes
  (with role + validity), regenerate, revoke. Codes are revocable and
  time-limited per the security model.
- Seeded bootstrap codes for demonstration: `ADM-100` (admin), `REC-200`
  (reception), `204204` (guest).
- `AppState.loginWithCode()` unified entry point that validates guest codes
  first, then staff codes, and activates the correct session.
- Live code-type detection badge on the login screen ("Will sign in to: …").
- Demo code chips on the login screen for quick testing.

### Security
- Staff codes are generated only from the admin control panel (no self-service
  role selection). Each code carries its role, so the system — not the user —
  decides which dashboard to show.
- Codes are revocable and time-limited; expired/revoked codes are rejected.

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
