# SYSTEM.md — Cairo Heart Hotel Technical Architecture

> Phase 0 deliverable. Describes the **as-built + proposed** architecture.
> Aligns with PLAN.md §48 (Platform Architecture), §49-62 (Backend/Data), §63-69 (Flutter).
> Existing implementation was verified end-to-end in a prior session (see `worklog.md` Task 6).

---

## 1. High-Level Architecture (PLAN §48, §112)

```
                         HOTEL (Aden, Yemen)
                           │
          ┌────────────────┼────────────────┐
          │                │                │
        GUEST         COMMUNICATION       ADMIN
   (Flutter web)      WHATSAPP/CALL     (Flutter web)
          │                │                │
          └────────────────┼────────────────┘
                           │
                    Next.js API (port 3000)
                           │
                   BUSINESS LOGIC
   (Booking · Availability · Pricing · Payments ·
    Permissions · Content · Reporting · Audit)
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   Supabase Auth     Supabase Postgres    Local memory cache
   (RBAC + tokens)   (source of truth)    (permission/session cache)
                           │
                        AUDIT LOG
```

**Key invariants (PLAN §83):** Backend is the single source of truth. There are no independent copies of booking status in app / admin / WhatsApp — they all read the backend.

---

## 2. Technology Stack (as-built)

### Frontend — Flutter Web (mandatory per PLAN §63; installed this session)
- **Flutter 3.47.2 stable** + **Dart 3.13.2** — SDK at `/home/z/flutter-sdk/bin`.
- Deployment artifact: `flutter build web --release --base-href "/flutter-static/"` → `public/flutter-static/` (main.dart.js + canvaskit + assets).
- Served by Next.js `/` route as a full-screen iframe to `/flutter-static/index.html` with a branded loader.
- Architecture (PLAN §63): Clean + Feature-based + Repository-flavored + DI (Provider) + central error/log handling.
- State management: **Provider** (`ChangeNotifier` + `MultiProvider`). *PLAN §63.1 suggested Riverpod "or a clear alternative adopted once" — Provider is that single adopted alternative. Mixing is forbidden. **Decision: keep Provider** (see Blockers §B4).*
- Packages: `http`, `provider`, `google_fonts`, `intl`, `url_launcher`, `shared_preferences`, `flutter_svg`, `cached_network_image`, `table_calendar`, `fl_chart`.

### Backend — Next.js 16 App Router (TypeScript 5)
- API Routes (App Router `/api/.../route.ts`) — **25 routes** (see MAP.md §3).
- Auth: **Supabase Auth** (`signInWithPassword`) → bearer token in `Authorization` header or `sb-token` cookie. Session resolved in `src/lib/auth.ts` with a 60s in-memory permission cache.
- RBAC: `requireAuth()` / `requirePermission(perm)` / `hasPermission()`; `admin` role bypasses permission checks.
- DB: **Prisma 6** ORM → **Supabase Postgres**. Singleton PrismaClient with global cache (`src/lib/db.ts`).
- DB connection: **transaction pooler (port 6543, pgbouncer)** for `DATABASE_URL` (concurrency multiplexing) + **direct (port 5432)** for `DIRECT_URL` (migrations). *Supabase direct host is IPv6-only (unreachable in this sandbox); pooler hosts support IPv4 — region ap-south-1.*
- Response helpers (`src/lib/api.ts`): `ok/fail/unauthorized/forbidden/notFound/handleError` with Arabic user-facing message per PLAN §56; `dec()` Decimal→number; `genRef()` for reference numbers.

### Serving / Gateway
- Single external port via Caddy gateway (see `Caddyfile`). Cross-port requests use `?XTransformPort=` query (not used currently — all on port 3000).
- All API requests use **relative paths** (Flutter `apiBase = ''`).

### Infrastructure
- Linux x86_64 sandbox (Debian 13), 2 vCPU / 3.9 GB RAM / 8 GB free disk.
- Java 21 present. Android SDK / Chrome / Linux desktop toolchain NOT installed (non-blocking for web path — see Blockers §B2).

---

## 3. Data Model (PLAN §51 → implemented in `prisma/schema.prisma`, 581 lines, 22 models)

### Implemented models (mapped to PLAN §51 proposed tables)

| Domain | Models | Notes vs PLAN §51 literal list |
|---|---|---|
| **Auth/RBAC** | `User`, `Role`, `Permission`, `UserRole`, `RolePermission` | direct match |
| **Guests** | `Guest` (name/phone/whatsapp/email/notes/blacklisted) | direct match |
| **Rooms** | `RoomType`, `RoomTypeMedia`, `Room`, `RoomRate` | `amenities` consolidated into `RoomType.amenitiesJson` (JSON); `room_images` → `RoomTypeMedia`; `rate_plans`+`room_rates` → just `RoomRate` (date-scoped overrides) |
| **Bookings** | `BookingRequest` (guest intent), `Reservation` (confirmed, with **pricing snapshot** fields) | `reservation_guests`/`reservation_rooms` folded into Reservation (single guest + single room per reservation — simple hotel model); `reservation_services` not yet a separate table (services tracked via ServiceRequest) |
| **Services** | `Service`, `ServiceRequest`, `HousekeepingTask` | direct match |
| **Payments** | `Payment`, `Invoice` | `refunds`/`payment_proofs` consolidated into `Payment` fields (status `refunded`/`partially_refunded`, `proofUrl`, `reviewedById`) |
| **Offers** | `Offer`, `OfferRoom` (M:N offer↔room type) | direct match |
| **Content** | `ContentSection`, `Faq`, `Policy`, `Review`, `GalleryItem` | `content_pages` → `ContentSection` (keyed sections with `configJson`); `media_assets` → `GalleryItem` + `RoomTypeMedia` |
| **Communication** | `ContactRequest` (covers contact + WhatsApp threads) | `communication_threads`/`communication_events` simplified into `ContactRequest` + `BookingRequest` (both carry owner/status/priority/lastActivityAt) |
| **Settings** | `HotelSetting` (key-value), `FeatureFlag` | `booking_settings`/`contact_settings`/`currency_settings`/`cancellation_policies` consolidated into key-value HotelSetting + Policy table |
| **Audit** | `AuditLog`, `Notification` | direct match |

### Pricing snapshot on Reservation (PLAN §20.1, §105)
`roomPriceSnapshot`, `discountSnapshot`, `servicesSnapshot`, `feesSnapshot`, `totalSnapshot`, `currency`, `paidAmount`, `remainingAmount`, `paymentStatus` — captured at confirmation so historical bookings are immune to future price changes.

### Reservation/Booking states (PLAN §23, §27)
- `Reservation.bookingStatus`: `draft · pending · awaiting_confirmation · confirmed · checked_in · checked_out · completed · cancelled · no_show · rejected`
- `Reservation.paymentStatus`: `pending · submitted · under_review · paid · partially_paid · failed · cancelled · refunded · partially_refunded`
- `BookingRequest.status` / `ContactRequest.status`: `new · assigned · contacted · waiting_customer · waiting_hotel · confirmed · converted · closed · cancelled`
- `Room.status`: `available · reserved · occupied · cleaning · maintenance · blocked · out_of_service`
- `ServiceRequest.status`: `new · accepted · assigned · in_progress · waiting · completed · cancelled · rejected`

### State machine (PLAN §24) — enforced server-side
`/api/admin/reservations/[id]/action` implements allowed transitions only (e.g. `awaiting_confirmation → confirmed|cancelled|rejected`; `confirmed → checked_in|cancelled|no_show`; `checked_in → checked_out`; `checked_out → completed`). Terminal states expose no action buttons. Cancel/Reject/No-Show require a reason.

---

## 4. API Surface (PLAN §50 → 25 routes implemented, see MAP.md §3)

```
Public:      /api/public/home · /api/public/room-types
Booking:     /api/availability/search (availability+pricing engine) · /api/booking-requests (create+lookup)
             /api/service-requests · /api/contact · /api/whatsapp/link
Auth:        /api/auth/login · /api/auth/session
Admin*:      /api/admin/dashboard · /api/admin/reservations (+[id]/action) · /api/admin/rooms
             /api/admin/room-types · /api/admin/services · /api/admin/offers · /api/admin/content
             /api/admin/service-requests · /api/admin/payments · /api/admin/settings
             /api/admin/audit · /api/admin/guests · /api/admin/users · /api/admin/communication
             /api/admin/room-types · (* = permission-guarded)
```

### Cross-cutting patterns
- **Server-side authority** (PLAN §28): price, availability, payment status, refunds, permissions are decided only by backend. Flutter sends Intent; backend decides.
- **Booking transaction** (PLAN §53): validate → check availability → calculate price → create reservation → create payment record → commit → emit notification. No half-written data on failure.
- **Concurrency / double-booking** (PLAN §54): availability search excludes rooms with overlapping confirmed-status reservations + blocked room statuses. (Hardening opportunity: DB-level unique constraint or SELECT FOR UPDATE — see STATE.md gaps.)
- **Audit**: sensitive admin mutations write `AuditLog` (actor/action/entity/entityId/old→new/reason).
- **Error model** (PLAN §55-56): user-facing Arabic message ("حدث خطأ أثناء تنفيذ العملية. حاول مرة أخرى.") + internal log/code; no token/password leakage.

---

## 5. Flutter Architecture (PLAN §63-69)

### Structure (PLAN §64 — feature-based)
```
mobile/lib/
├── app/        (router, theme, [localization], [config])  ← partially flat; see MAP §2
├── core/      (network/api_client, storage/app_store, widgets/common, models, config)
├── features/
│   ├── home/       (guest_shell + home_screen)
│   ├── rooms/      (rooms_screen + room_detail_screen)
│   ├── booking/    (booking_flow_screen — 3-step)
│   ├── bookings/   (my_bookings_screen — track by phone)
│   ├── services/   (services_screen — request + lookup)
│   ├── contact/    (contact_screen — WhatsApp + form + policies)
│   ├── profile/    (profile_screen — brand + admin entry)
│   └── admin/      (admin_shell + 15 screens: dashboard, reservations, reservation_detail,
│                    rooms, room_types, services, offers, content, service_requests,
│                    communication, settings, audit, users, guests, admin_login)
└── main.dart
```

### Separation (PLAN §65)
`UI → Controller/Notifier (ChangeNotifier via Provider) → ApiClient (http) → Next.js API → Prisma → Postgres`.
(Repository/Use-Case layers are lightly flattened into `ApiClient` + screen `StatefulWidget`s; the rule "no complex booking calc inside a Widget" is honored — all pricing/availability is server-side.)

### State management
- `AppStore` (ChangeNotifier) — surface (guest/admin) + auth state + navigator key.
- `ApiClient` (singleton) — bearer token + SharedPreferences persistence + get/post/patch + `ApiException(message,status,code)`.
- Screen-level state via `StatefulWidget` + `FutureBuilder`/`setState` (no separate Riverpod/Controller class — pragmatic for this scope).

### Design system (PLAN §66-68)
- `app/theme.dart` — `AppTheme.light/dark`, Cairo Google Font, palette (gold `#B8975A` + charcoal + cream), status colors/labels.
- `core/widgets/common.dart` — `LoadingView`, `ErrorView`, `EmptyView`, `StatusBadge`, `HotelNetworkImage`, `SectionTitle`, `statCard`.
- RTL: `MaterialApp.builder` wraps in `Directionality(TextDirection.rtl)`, `locale: Locale('ar')`.

### Adaptive vs Responsive (PLAN §69)
- Responsive: `LayoutBuilder` + `MediaQuery` + `SliverGrid` with min/max cross-axis extent — 1/2/3/4 columns by width.
- Adaptive: Guest = bottom nav (5 tabs) + short flows; Admin = side nav (rail on wide, drawer on narrow) + tables/filters/charts.

### Error/Loading/Empty states (PLAN §55, §86-87)
All screens implement: `LoadingView` (skeleton/progress), `ErrorView` (retry CTA), `EmptyView` (with contextual CTA), inline loading on actions, SnackBar feedback.

---

## 6. Security & Privacy (PLAN §58-59, §96)

- **Authentication**: Supabase Auth (password) → JWT access token.
- **Authorization**: server-side `requirePermission(perm)`; `admin` bypass.
- **Transport**: HTTPS terminated at gateway; relative API paths (no CORS leaking).
- **Input validation**: per-route (zod-equivalent manual checks; dates parsed + validated, nights≥1, checkout>checkin, etc.).
- **Audit**: every sensitive mutation logged.
- **Privacy**: least-privilege — guest phone-lookup only returns the caller's own bookings/requests.
- **Secrets**: `.env` (NOT committed); Supabase service_role key used only server-side (`supabaseAdmin`); anon key for public client.
- **Hardening gaps** (to address): rate limiting, stricter zod schemas, DB-level concurrency guard — see STATE.md.

---

## 7. Localization, Currency, Date (PLAN §60-62)

- Arabic-first + RTL throughout. English fields exist in schema (`nameAr/nameEn`, `titleAr/titleEn`, `bodyAr/bodyEn`) — UI currently renders Arabic.
- Currency stored **with** every amount (`currency` column on RoomType, RoomRate, Reservation, Payment, Service, Offer). Default `YER`, symbol `ر.ي`.
- Dates stored as ISO/Date; rendered via Arabic month formatters in Flutter.
- No hard-coded manageable text — all variable content lives in DB (ContentSection/Faq/Policy/HotelSetting/FeatureFlag).

---

## 8. Observability (PLAN §57)

- API errors, booking failures, payment failures, auth failures, critical state transitions → logged to console (`console.error`) + AuditLog where business-relevant.
- Never logged: passwords, tokens, unnecessary PII.

---

## 9. Deployment / Run

| Command | Purpose |
|---|---|
| `bun run dev` | Next.js dev server on port 3000 (writes `dev.log`). Prefixes `unset DATABASE_URL; unset DIRECT_URL;` so `.env` values win over shell env. |
| `bun run db:push` | Push Prisma schema to Supabase (`--accept-data-loss`). |
| `bun run db:seed` | Seed admin user + room types + rooms + services + offers + gallery + FAQ + policies + settings + flags. |
| `flutter build web --release --base-href "/flutter-static/"` | Build Flutter web → `mobile/build/web/` → copy to `public/flutter-static/`. |
| `bun run lint` | ESLint. |

**Runtime**: user opens `/` → Next.js renders the iframe page → Flutter web boots from `/flutter-static/` → Flutter calls relative `/api/*` → Next.js API → Prisma → Supabase.

---

## 10. Architecture Decisions (to preserve)

| # | Decision | Rationale |
|---|---|---|
| AD1 | Flutter Web (not native APK/IPA) as the deployable | Single codebase for guest+admin; responsive/adaptive covers all device sizes via mobile browser; native toolchains (Android SDK, Xcode) unavailable in this Linux sandbox. |
| AD2 | Next.js serves Flutter via iframe + handles all `/api/*` | Single origin → relative API paths, no CORS, single external port. |
| AD3 | Provider (not Riverpod) | PLAN §63.1 allows "one clear alternative adopted once"; Provider is adopted; migration risk > benefit. |
| AD4 | Supabase transaction pooler (6543) for runtime + direct (5432) for migrations | Pooler multiplexes connections under concurrency (fixes session-limit exhaustion seen in prior session). |
| AD5 | Pricing snapshot on Reservation | PLAN §20.1/§105 — historical booking integrity. |
| AD6 | BookingRequest ≠ Reservation | PLAN §25 — a WhatsApp message is intent, not a confirmed booking. |
| AD7 | Server-side authority for price/availability/payment/permissions | PLAN §28. |
| AD8 | No hard delete for business history | PLAN §74 — cancel/archive/soft-delete. |

---

*For the file-by-file inventory see `MAP.md`. For current status + gaps see `STATE.md`.*
