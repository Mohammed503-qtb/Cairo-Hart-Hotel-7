# STATE.md — Cairo Heart Hotel Progress Tracker

> Phase 0 deliverable. Snapshot of **what works now**, **what's broken**, and the **recommended path forward**.
> This file is the live progress ledger and must be updated after every completed task (per the working principle).

---

## 0. Executive Summary

A prior session (see `worklog.md` Tasks 0–6) **built the entire platform and verified it end-to-end** (PLAN §93 acceptance journey passed via Agent Browser + VLM): Flutter 3.47.2 web app (23 screens, ~9,000 lines) + Next.js 16 backend (25 API routes) + Supabase Postgres (22 models + seeded data) + WhatsApp linking + reservation state machine + pricing/availability engines + audit + admin dashboard.

Then the **sandbox environment was reset**: the Flutter SDK at `/home/z/flutter-sdk` was deleted, and `.env` was reset to a default SQLite path (`DATABASE_URL=file:/home/z/my-project/db/custom.db`) — the Supabase credentials were wiped. The **source code, the Prisma schema, the seed script, the Next.js API routes, the Flutter app source, and the `public/flutter-static/` build artifact all persisted**.

This Phase 0 session:
1. Re-read PLAN.md completely (3334 lines) — understanding confirmed.
2. **Reinstalled Flutter 3.47.2 + Dart 3.13.2** at `/home/z/flutter-sdk` (same versions as prior session).
3. Verified the existing project: Prisma schema (581 lines, 22 models), 25 API routes, Flutter foundation + 8 guest + 15 admin screens, `flutter-static` build present.
4. Ran `flutter analyze` → **0 errors, 0 blocking warnings** (clean).
5. Produced PROJECT.md, SYSTEM.md, MAP.md, this STATE.md.

**Current runtime state: NOT running.** Dev server is down; `.env` is broken (SQLite fallback) so the backend cannot reach Supabase even if started. The Flutter web build artifact is intact but its API calls would fail until the backend is restored.

---

## 1. What WORKS right now (verified this session)

| Capability | Status | Evidence |
|---|---|---|
| Flutter SDK 3.47.2 + Dart 3.13.2 | ✓ installed | `flutter --version`, `flutter doctor` |
| Flutter source compiles cleanly | ✓ | `flutter analyze` → 0 errors, 0 blocking warnings |
| Flutter web build artifact exists | ✓ | `public/flutter-static/` (41 MB: main.dart.js, canvaskit, assets, index.html) |
| Prisma schema (22 models, PLAN §51) | ✓ | `prisma/schema.prisma` 581 lines |
| Seed script (admin + rooms + services + offers + ...) | ✓ | `prisma/seed.ts` 269 lines |
| Next.js API routes (25, PLAN §50) | ✓ | `src/app/api/**` (all route.ts present) |
| Auth + RBAC (`src/lib/auth.ts`) | ✓ | getSession/requireAuth/requirePermission + 60s cache |
| Supabase client (`src/lib/supabase.ts`) | ✓ code present | runtime depends on `.env` (see §B1) |
| Availability + pricing engine (PLAN §19-20) | ✓ code present | `/api/availability/search` route — server-side overlap + offers |
| Reservation state machine (PLAN §24) | ✓ code present | `/api/admin/reservations/[id]/action` |
| WhatsApp linking (PLAN §8) | ✓ code present | `/api/whatsapp/link` + Flutter url_launcher |
| Audit logging (PLAN §38) | ✓ code present | `AuditLog` model + admin mutations log |
| Flutter iframe integration | ✓ code present | `src/app/page.tsx` + `layout.tsx` |
| Prior end-to-end verification | ✓ (prior session) | worklog Task 6: full §93 journey passed via Agent Browser + VLM |

## 2. What is BROKEN / NOT working

| Item | Severity | Detail |
|---|---|---|
| `.env` reset to SQLite | 🔴 BLOCKER (B1) | Supabase creds gone; backend cannot reach the hotel's seeded Postgres data. |
| Dev server not running | 🔴 BLOCKER (B3) | Must start after `.env` fix. |
| `assets/` dir missing | 🟡 trivial | pubspec references `assets/` but dir absent → 1 analyzer warning. |

---

## 3. Blockers & Ambiguities

### B1 — `.env` reset (BLOCKER, must fix before any runtime work)
The current `.env` contains only:
```
DATABASE_URL=file:/home/z/my-project/db/custom.db
```
The Supabase Postgres credentials are gone. **Fix:** restore the full `.env` with the Supabase **transaction pooler** (port 6543, pgbouncer) for `DATABASE_URL` and the **direct** (port 5432) for `DIRECT_URL`, plus `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`. The credentials are known (provided in the original request + recovered from prior worklog). After restoring: `bun run db:push` (idempotent) + `bun run db:seed` (idempotent for fresh data).

> ⚠ Note: `bun run dev` already prefixes `unset DATABASE_URL; unset DIRECT_URL;` so the `.env` value wins over any shell env override (prior-session fix).

### B2 — Flutter doctor: Android SDK / Chrome / Linux desktop missing (NOT a blocker)
- **Android SDK** absent → cannot build native Android APK. The user's original request mentioned "all Android and iPhone devices". The **Flutter web build is responsive/adaptive** and runs in mobile browsers on Android & iOS, satisfying cross-device access. Producing a native APK would require ~3 GB Android SDK download + `flutter config --android-sdk`; an iOS IPA requires Xcode (macOS-only, unavailable in this Linux sandbox).
- **Chrome** absent → `flutter run -d chrome` (hot-reload) won't work, but `flutter build web --release` (the deploy path) does not need Chrome.
- **Linux desktop toolchain** absent → irrelevant (web-only target).
- **Recommendation:** treat the web build as the deployable artifact. Native packaging is out of sandbox scope; flag to user if native apps are truly required (would need a different environment).

### B3 — Dev server down (BLOCKER for runtime verification)
No `dev.log`, no `next-server` process, port 3000 returns nothing. Must start `bun run dev` (background) after `.env` fix and confirm `dev.log` shows "Ready" with no compile errors.

### B4 — State management: Provider vs Riverpod (ambiguity, recommendation: KEEP Provider)
PLAN §63.1 says "Riverpod … or a clear alternative adopted once". The existing 23-screen app uses **Provider** consistently (no mixing — satisfies the rule). Migrating ~9,000 lines to Riverpod is high-risk for zero product benefit. **Recommendation: keep Provider; document as AD3 (SYSTEM.md §10).** Flagging for your decision since it's an architecture-adjacent choice.

### B5 — Some PLAN §51 tables consolidated (ambiguity, recommendation: ACCEPT)
Deviations from the literal §51 table list (documented in SYSTEM.md §3): amenities → JSON field; rate_plans → just RoomRate; reservation_guests/rooms → folded into Reservation; refunds/payment_proofs → Payment fields; communication_threads/events → ContactRequest + BookingRequest; booking_settings/contact_settings/currency_settings/cancellation_policies → HotelSetting key-value + Policy. These are reasonable simplifications for a single-hotel, single-room-per-reservation model. **Recommendation: accept** unless you want the full normalized set.

### B6 — `reservation_services` snapshot not a separate relation
`Reservation.servicesSnapshot` is a single Decimal total (no line-item breakdown). If itemized service charges on invoices are required (PLAN §76 invoicing), a `ReservationService` join table may be needed. Current state: services are tracked via `ServiceRequest` (operational), not as billable line items on the reservation. **Flagging** — acceptable for MVP per PLAN §111 ("minimum complete system").

---

## 4. Gap analysis vs PLAN.md (functional coverage)

### ✓ Fully implemented (per worklog Task 6 verification + code inspection)
- §6 Fast Booking (3-step flow)
- §7 Booking modes (Direct + WhatsApp-assisted + Admin-created)
- §8-9 WhatsApp + Communication Center (link generator + communication screen)
- §10 Hotel Home (all 10 sections, reorderable via ContentSection)
- §11-13 Content control (CRUD for sections/room-types/services/offers/policies/FAQ; draft/published/hidden/archived statuses)
- §17-20 Rooms + Room states + Availability + Pricing engines (server-side)
- §21 Offers (data object, discount types, room scoping, date validity)
- §22-25 Reservation domain + states + state machine + BookingRequest↔Reservation separation
- §26-27 Payments (multi-method, manual proof, review states)
- §29-32 Guest profile + Service requests + states
- §38 Audit log (every sensitive admin mutation)
- §39-40 RBAC (roles + fine-grained permissions + admin bypass)
- §42-43 Settings + Feature flags
- §60-62 RTL/Arabic/Currency/Date
- §63-69 Flutter architecture + design system + adaptive/responsive
- §81 Admin workflows (new request → confirm/convert; payment review; service request lifecycle)
- §82 User↔Admin synchronization (single source of truth = backend)
- §93 Acceptance journey (verified end-to-end in prior session)

### ⚠ Partially / to verify after restore
- §13 Media management (upload/delete/reorder/main-image): `RoomTypeMedia` + `GalleryItem` models exist; admin **upload UI** for new media not confirmed (images currently seeded by URL). Verify after restore.
- §36-37 Reporting + clickable dashboard metrics: dashboard has 12 stat cards (some navigate); full reports screen (PLAN §36) — verify if a dedicated `/admin/reports` exists (not in router). May be a gap.
- §75 Housekeeping: `HousekeepingTask` model exists; no dedicated housekeeping screen in router (folded into Rooms screen status + ServiceRequest). Acceptable per PLAN §75 ("no need for a huge system").
- §76-77 Invoicing + PDF: `Invoice` model exists; **PDF generation** not implemented (PLAN §77 says "per platform & need"). Gap if printable invoices are required.
- §33-34 Notifications: `Notification` model exists; admin notification center screen not in router. May be a gap.

### ✗ Known gaps (to address if required by PLAN scope)
- **§34 Admin Notification Center** — no dedicated screen (notifications table exists but no UI).
- **§36 Reports screen** — analytics/reports not in router.
- **§77 PDF/printing** — no invoice/booking-confirmation PDF generation.
- **§92 Testing** — no unit/widget/integration tests written (PLAN §92 strategy not yet executed). `tests/` dir has unrelated shell scripts.
- **Rate limiting** (PLAN §58) — not implemented.
- **Stricter zod input validation** — current routes do manual checks; zod is a dependency, could be adopted.
- **DB-level concurrency guard** for double-booking (PLAN §54) — currently app-level overlap query; could add a unique constraint or `SELECT ... FOR UPDATE` in a transaction.

> These gaps do not block the core acceptance journey (§93) which already passed. They are hardening/completeness items.

---

## 5. Recommended Execution Order (post-approval)

> Per your rule: "Execute PLAN.md sequentially and incrementally. Do not build the entire project at once."
> Since the platform is already built and verified, the path is **restore → re-verify → fill gaps → harden**, not build-from-scratch.

### Step 1 — Restore runtime (unblock, ~5 min)
1. Write `.env` with Supabase transaction pooler (6543) + direct (5432) + URL + anon + service_role.
2. `bun run db:push` (idempotent — ensures schema present).
3. `bun run db:seed` (idempotent-ish — re-seeds if tables empty; verify admin user exists).
4. Start `bun run dev` in background; tail `dev.log` until "Ready".
5. Smoke-test: `curl /api/public/home` returns hotel data; `curl /api/availability/search` returns priced room types.
- **Verification gate:** backend reachable + seeded.

### Step 2 — Re-verify the live app (Agent Browser, PLAN §93)
1. Open `/` → Flutter iframe loads, hero + sections render.
2. Walk the golden journey: pick dates → see rooms → select room → enter name+phone → submit → get booking request reference.
3. Admin login (`admin@cairoheart.ye` / `Admin@12345`) → dashboard shows the new request → confirm → reservation created → room reserved → audit log written.
4. Verify RTL, responsive (mobile + desktop widths), loading/empty/error states, WhatsApp deep link.
- **Verification gate:** §93 + §94 + §95 acceptance passes in-browser.

### Step 3 — Trivial cleanup (~10 min)
1. Create empty `mobile/assets/` dir (or remove the assets line from pubspec) → clears the 1 analyzer warning.
2. Optionally fix the 6 `DropdownButtonFormField value:` → `initialValue:` deprecations.
- **Verification gate:** `flutter analyze` → 0 warnings.

### Step 4 — Fill PLAN gaps (incrementally, one feature per step, each: implement → run → test → inspect → fix → verify → commit)
In PLAN priority order (§101-102):
- 4a. Admin Notification Center (§34) — list + read/unread + link-to-entity.
- 4b. Reports screen (§36) — bookings/occupancy/revenue/payments by period.
- 4c. PDF invoice + booking confirmation (§77) — server-side render, download.
- 4d. Media upload UI (§13) — admin image upload (Supabase Storage or base64 to HotelSetting — decide).
- *(Each as a separate approved step.)*

### Step 5 — Hardening (PLAN §58, §109)
- 5a. zod input validation on all routes.
- 5b. Rate limiting on `/api/booking-requests`, `/api/contact`, `/api/auth/login`.
- 5c. DB-level double-booking guard (transaction + unique constraint or row lock).
- 5d. Permission audit — verify every admin route calls `requirePermission(...)`.

### Step 6 — Testing (PLAN §92)
- 6a. Unit: availability engine, pricing+discounts, state transitions, cancellation.
- 6b. Widget: room card, booking flow, login.
- 6c. Integration: search→select→request→confirmation→payment recording→admin visibility.

### Step 7 — Production readiness review (PLAN §109 checklist)
Build succeeds · no critical crashes · migrations verified · API security reviewed · permissions verified · booking concurrency tested · payment paths tested · WhatsApp flows tested · admin actions audited · privacy reviewed.

> After each step: update this STATE.md, append a `worklog.md` entry, run `flutter analyze` + relevant tests, and only then commit.

---

## 6. Open Questions for You (decisions that materially affect the project)

1. **State management (B4):** Keep **Provider** (recommended) or migrate to **Riverpod**?
2. **Native mobile (B2):** Is the responsive **Flutter web** build acceptable as the cross-device deliverable (runs in mobile browsers on Android & iOS), or do you require native **APK/IPA** artifacts (which need Android SDK / Xcode not available in this Linux sandbox)?
3. **Schema consolidation (B5):** Accept the simplified model, or require the full normalized PLAN §51 table set?
4. **Gap priority (Step 4):** Which of Notification Center / Reports / PDF / Media Upload should I do first, or all in the listed order?
5. **Testing scope (Step 6):** Full PLAN §92 suite (unit+widget+integration+e2e), or a pragmatic subset (unit for engines + e2e for the golden journey)?

---

## 7. Current Todo (Phase 0)

| ID | Task | Status |
|---|---|---|
| p0-1 | Read PLAN.md completely | ✓ done |
| p0-2 | Inspect environment + toolchain | ✓ done |
| p0-3 | Install missing tooling (Flutter SDK) | ✓ done (3.47.2) |
| p0-4 | Verify technical choices vs docs | ✓ done |
| p0-5 | Create PROJECT.md | ✓ done |
| p0-6 | Create SYSTEM.md | ✓ done |
| p0-7 | Create MAP.md | ✓ done |
| p0-8 | Create STATE.md | ✓ done |
| p0-9 | Phase 0 report + STOP for approval | ⏳ this message |

**Phase 0 complete. Awaiting your approval to begin Step 1 (runtime restore).**
