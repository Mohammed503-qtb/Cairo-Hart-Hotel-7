# MAP.md — Cairo Heart Hotel Codebase Map

> Phase 0 deliverable. Inventory of every file/directory that exists **right now**.
> `✓` = present & healthy · `⚠` = present but needs attention · `✗` = missing/required.

---

## 1. Repository root — `/home/z/my-project/`

```
.env                       ⚠ RESET to SQLite default (Supabase creds GONE — BLOCKER, see STATE.md §B1)
Caddyfile                  ✓ gateway config (single external port)
bun.lock                   ✓
package.json               ✓ Next.js 16 + Prisma 6 + Supabase + shadcn deps
postcss.config.mjs         ✓
tailwind.config.ts         ✓
next.config.ts             ✓
tsconfig.json              ✓
eslint.config.mjs          ✓
components.json            ✓ shadcn/ui config
prisma/
  schema.prisma            ✓ 581 lines, 22 models (see SYSTEM.md §3)
  seed.ts                  ✓ 269 lines — seeds admin + 4 room types + 16 rooms +
                             6 services + 2 offers + gallery + FAQ + policies + settings + flags
db/
  custom.db                ⚠ leftover SQLite file from reset .env (will be unused once Supabase restored)
public/
  flutter-static/          ✓ complete Flutter web build (main.dart.js, canvaskit/, assets/,
                             index.html, manifest.json, flutter_bootstrap.js, service worker)
  logo.svg  robots.txt     ✓
src/                       ✓ Next.js app (see §2)
mobile/                    ✓ Flutter project (see §3)
examples/websocket/        ✓ reference (server.ts + frontend.tsx) — not currently used
tests/                     ⚠ shell scripts for runtime builds (python/database) — not Flutter tests
upload/PLAN.md             ✓ 3334 lines — authoritative source (read in full)
worklog.md                 ✓ prior session log (Tasks 0,1,5-guest,5-admin,6)
PROJECT.md SYSTEM.md MAP.md STATE.md   ✓ this Phase 0 deliverable set
tool-results/             (transient read cache)
download/                  (empty except README — prior Flutter download staging)
```

---

## 2. Next.js backend — `src/`

### Foundation
```
src/lib/
  db.ts                ✓ singleton PrismaClient + global cache
  supabase.ts         ✓ supabaseAdmin (service_role) + supabasePublic (anon)
  auth.ts             ✓ getSession/requireAuth/requirePermission/hasPermission + 60s cache
  api.ts              ✓ ok/fail/unauthorized/forbidden/notFound/handleError/dec/genRef
  utils.ts            ✓ (shadcn cn helper)
src/hooks/
  use-mobile.ts use-toast.ts   ✓ shadcn hooks (unused by Flutter; kept for Next.js/shadcn parity)
src/app/
  layout.tsx          ✓ minimal RTL Arabic (`lang="ar" dir="rtl"`) — Flutter handles its own chrome
  page.tsx            ✓ full-screen iframe → /flutter-static/index.html + branded loader (hides on load)
  globals.css         ✓
```

### API routes — `src/app/api/` (25 routes)
```
route.ts                         ✓ root (health/404)
public/
  home/route.ts                  ✓ GET — hero + sections + hotel info + contact + flags
  room-types/route.ts            ✓ GET — published room types (gallery + amenities)
availability/
  search/route.ts                ✓ POST — availability + pricing engine (overlap+offers)
booking-requests/route.ts        ✓ POST (create) + GET (lookup by phone)
service-requests/route.ts       ✓ POST (guest create) + GET (lookup by phone)
contact/route.ts                 ✓ POST — contact request (returns ref + WhatsApp URL)
whatsapp/link/route.ts           ✓ GET — normalized wa.me link with prefilled Arabic message
auth/
  login/route.ts                 ✓ POST — Supabase signInWithPassword → returns token
  session/route.ts               ✓ GET — current session (roles+permissions)
admin/                           (permission-guarded)
  dashboard/route.ts             ✓ stats + attention list + recent activity
  reservations/
    route.ts                     ✓ GET (list/filter) + POST (create from booking request)
    [id]/action/route.ts        ✓ PATCH — state machine (confirm/cancel/reject/checkin/...)
  rooms/route.ts                 ✓ GET + PATCH (status change)
  room-types/route.ts            ✓ GET + POST/PATCH (CRUD)
  services/route.ts              ✓ GET + POST/PATCH (CRUD)
  offers/route.ts                ✓ GET + POST/PATCH (CRUD)
  content/route.ts               ✓ GET + PATCH (sections visible/sort + titles)
  service-requests/route.ts      ✓ GET + PATCH (assign/start/complete/cancel)
  payments/route.ts              ✓ GET + POST (record payment)
  settings/route.ts              ✓ GET + PATCH (hotel info + flags + roles/perms read)
  audit/route.ts                 ✓ GET (filter by entity, pagination)
  guests/route.ts                ✓ GET (search + stats)
  users/route.ts                 ✓ GET (admin users read)
  communication/route.ts         ✓ GET + PATCH (contact + booking request threads)
```

### shadcn/ui components — `src/components/ui/` (52 files)
Full New York-style set (accordion, alert-dialog, avatar, badge, breadcrumb, button, calendar, card, carousel, chart, checkbox, collapsible, command, context-menu, dialog, drawer, dropdown-menu, form, hover-card, input, input-otp, label, menubar, navigation-menu, pagination, popover, progress, radio-group, resizable, scroll-area, select, separator, sheet, sidebar, skeleton, slider, sonner, switch, table, tabs, textarea, toast, toaster, toggle, toggle-group, tooltip).
> Note: shadcn/ui is the *Next.js* design system. The **Flutter** app has its own design system (`mobile/lib/app/theme.dart` + `core/widgets/common.dart`). The shadcn set is retained for parity/future React surfaces but the live UI is Flutter.

---

## 3. Flutter app — `mobile/`

### Project config
```
mobile/
  pubspec.yaml         ✓ deps: http, provider, google_fonts, intl, url_launcher,
                          shared_preferences, flutter_svg, cached_network_image,
                          table_calendar, fl_chart; SDK ^3.13.2
  pubspec.lock          ✓
  analysis_options.yaml ✓ flutter_lints
  README.md             ✓
  web/                  ✓ manifest.json, index.html, favicon, icons (192/512 + maskable)
  lib/                  (see below)
  (no android/ ios/ linux/ macos/ windows/ folders — web-only project)
```

### `mobile/lib/` structure
```
main.dart                          ✓ 37 lines — MultiProvider(AppStore + ApiClient),
                                     RTL MaterialApp, Cairo Google font, router,
                                     initialRoute = isAuthed ? /admin : /home
app/
  app_router.dart                  ✓ 86 lines — onGenerateRoute, 24 named routes
                                     (8 guest + /login + 15 admin incl. detail)
  theme.dart                       ✓ 7.3 KB — AppTheme.light/dark, palette, status colors
core/
  config.dart                      ✓ 16 lines — apiBase='' (relative), api(), currency, whatsapp default
  models.dart                      ✓ 356 lines — HomeData, RoomType, AvailabilityResult,
                                     BookingRequest, Reservation, AdminReservation,
                                     AdminRoom, AuditLog, DashboardData, etc.
  network/api_client.dart          ✓ singleton, SharedPreferences token, get/post/patch,
                                     ApiException(message,status,code)
  storage/app_store.dart           ✓ ChangeNotifier — surface(guest/admin) + isAuthed +
                                     navigatorKey + enterAdmin/exitToGuest/signOut/openAdmin
  widgets/common.dart              ✓ LoadingView, ErrorView, EmptyView, StatusBadge,
                                     HotelNetworkImage, SectionTitle, statCard
features/
  home/
    guest_shell.dart               ✓ bottom nav (5 tabs) + FAB → admin entry
    home_screen.dart               ✓ ~790 lines — hero, quick booking, featured rooms,
                                     why hotel, offers, services, gallery, location,
                                     reviews, contact; floating WhatsApp FAB
  rooms/
    rooms_screen.dart              ✓ ~510 lines — search bar + browse/search modes + cards
    room_detail_screen.dart        ✓ ~410 lines — hero + amenities + inline availability + CTA
  booking/
    booking_flow_screen.dart       ✓ ~515 lines — 3-step flow (review → guest info → success)
  bookings/
    my_bookings_screen.dart        ✓ ~400 lines — phone lookup, booking + service-request tabs
  services/
    services_screen.dart           ✓ ~470 lines — services grid + my-requests lookup
  contact/
    contact_screen.dart            ✓ ~360 lines — WhatsApp + call + form + policies accordion
  profile/
    profile_screen.dart            ✓ ~148 lines — brand header + contact + admin entry
  admin/
    admin_login_screen.dart        ✓ 170 lines — login form → /api/auth/login → enterAdmin
    admin_shell.dart               ✓ side nav (13 sections), responsive rail/drawer,
                                     IndexedStack body, navigateTo(idx) for dashboard deep-linking
    dashboard_screen.dart          ✓ 357 lines — greeting, "Needs Attention", 12 stat cards
                                     (SliverGrid), revenue card, recent activity timeline
    reservations_screen.dart       ✓ 523 lines — search + status FilterChips + cards +
                                     "new booking" bottom-sheet form
    reservation_detail_screen.dart ✓ 646 lines — guest + stay + price breakdown + payments +
                                     state-machine action buttons + reason dialogs + audit timeline
    rooms_screen.dart              ✓ 286 lines — search + status chips + SliverGrid + status dialog
    room_types_screen.dart         ✓ 397 lines — CRUD list + form (amenities multi-select)
    services_screen.dart           ✓ 360 lines — CRUD list + form
    offers_screen.dart             ✓ 459 lines — CRUD list + form (room type multi-select, dates)
    content_screen.dart            ✓ 241 lines — sections (edit/visible/sort) + FAQ/policies/gallery read
    service_requests_screen.dart   ✓ 294 lines — status chips + assign/start/complete/cancel/reject
    communication_screen.dart     ✓ 587 lines — Contact + Booking request tabs, status chips,
                                     actions (assign/contact/confirm/convert/close/cancel), WhatsApp
    settings_screen.dart           ✓ 372 lines — 4 tabs (hotel info, flags, roles/perms, localization)
    audit_screen.dart              ✓ 230 lines — entity FilterChips + timeline + load-more
    users_screen.dart              ✓ 125 lines — read-only admin users list
    guests_screen.dart             ✓ 327 lines — search + detail bottom-sheet + WhatsApp
```

### Static analysis state
`flutter analyze`: **0 errors, 0 blocking warnings**. 1 trivial warning (`assets/` dir referenced in pubspec but not created) + 26 info lints (deprecation `DropdownButtonFormField value:`→`initialValue:`; `use_build_context_synchronously` pedantry — all have `mounted` guards; `unnecessary_underscores`). None block the build.

---

## 4. Build artifacts & runtime

```
public/flutter-static/             ✓ complete web build (41 MB)
  index.html, main.dart.js, flutter.js, flutter_bootstrap.js,
  flutter_service_worker.js, manifest.json, version.json, favicon.png
  canvaskit/ (canvaskit.wasm/js, skwasm, wimp — incl. chromium + webparagraph variants)
  assets/ (FontManifest, MaterialIcons, shaders, CupertinoIcons, NOTICES)
  icons/ (192, 512, maskable-192, maskable-512)
```

`mobile/build/web/` — not present (build output was copied to `public/flutter-static/` in the prior session; a fresh `flutter build web` would regenerate it).

---

## 5. Environment & tooling inventory

| Tool | Status | Path / Version |
|---|---|---|
| Flutter SDK | ✓ installed this session | `/home/z/flutter-sdk/bin` · 3.47.2 stable |
| Dart SDK | ✓ (bundled with Flutter) | 3.13.2 |
| Java (JDK) | ✓ | OpenJDK 21.0.12.1 (Debian 13) |
| Node.js | ✓ | v24.19.0 |
| Bun | ✓ | 1.3.14 |
| Prisma CLI | ✓ | via `bun run db:*` scripts |
| Android SDK | ✗ NOT installed | non-blocking for web build (see STATE.md §B2) |
| Chrome | ✗ NOT installed | non-blocking for `flutter build web --release` (only needed for `flutter run -d chrome` hot-reload) |
| Linux desktop toolchain (clang/cmake/ninja/gtk) | ✗ | not needed (web-only target) |
| Git | ✓ | 2.47.3 |
| curl/wget/unzip/tar | ✓ | present |

### Flutter doctor summary
`✓ Connected device · ✓ Network resources · ✗ Android toolchain · ✗ Chrome · ✗ Linux desktop`
Only the web path is required for this project; the ✗ items are not blockers.

---

## 6. Mini-services & examples

```
mini-services/        (no active mini-service — directory not present or empty)
examples/websocket/  ✓ reference demo (server.ts port 3003 + frontend.tsx) — NOT wired into the app
skills/              (Skills toolkit dir — for z-ai-web-dev-sdk capabilities, not part of runtime)
```
> Real-time features (if ever needed per PLAN §33) would use a socket.io mini-service on a separate port with `?XTransformPort=` gateway forwarding. Not currently required.

---

## 7. Documentation set

```
upload/PLAN.md     ✓ authoritative product spec (3334 lines)
PROJECT.md         ✓ this Phase 0 — project understanding
SYSTEM.md          ✓ this Phase 0 — architecture
MAP.md             ✓ this Phase 0 — codebase inventory (this file)
STATE.md           ✓ this Phase 0 — current state + gaps + execution plan
worklog.md         ✓ prior session log (Tasks 0–6)
mobile/README.md   ✓ Flutter project readme
```

---

*Next: read `STATE.md` for the current status, blockers, and recommended execution order.*
