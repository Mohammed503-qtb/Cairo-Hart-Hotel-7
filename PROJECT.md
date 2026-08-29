# PROJECT.md — Cairo Heart Hotel (فندق قلب القاهرة)

> Phase 0 deliverable. Authoritative understanding of the project as **one system**.
> Source of truth: `upload/PLAN.md` (3334 lines, read in full).
> This document must not contradict PLAN.md. Where a deviation exists, it is explicitly flagged.

---

## 1. What this project IS

Cairo Heart Hotel — **Digital Operations Platform** (المنصة الرقمية التشغيلية المتكاملة) for a hotel in Aden, Yemen.

This is **not** a booking app. It is **not** a CMS. It is **not** a dashboard with pages.

It is a unified platform that closes the gap between the **customer journey** (discover → inquire → book → arrive → service → depart) and the **hotel operations** (reception → bookings → rooms → payments → services → content → reports → audit).

> "منصة تشغيل رقمية للفندق، تجعل تجربة العميل بسيطة وسريعة، وتجعل WhatsApp قناة عملية عند الحاجة، وتجعل الإدارة قادرة على رؤية وإدارة والتحكم في دورة العمل كاملة من مكان واحد." — PLAN §115

### Four usage layers (PLAN §3.1)
1. **Guest Experience** — simple, fast, mobile-first.
2. **Communication Layer** — WhatsApp + calls + notifications (a *workflow channel*, not a contact button — PLAN §8, Golden Rule 3).
3. **Hotel Operations** — reception, staff, management.
4. **Platform Core** — Backend + Database + Business Logic + Audit + Security.

---

## 2. Mission & Core Value (PLAN §0)

| Stakeholder | Value |
|---|---|
| Guest | Fewest possible steps to reach the right service. |
| Hotel | Maximum clarity & control over requests, bookings, operations — minimal chaos. |
| Staff | Know what to do now, who owns it, what its status is. |
| Management | See the full operational truth from one place. |

**Supreme rule (PLAN §0):** Understand the business, the service, the logic, and the flow *before* writing code. A screen is not success. Success is a system that behaves like a real hotel.

---

## 3. Actors & Roles (PLAN §4)

| Actor | Capabilities (summary) |
|---|---|
| **Guest** | Browse hotel/rooms, pick dates, see availability & price, request booking, open WhatsApp, track requests, request services, see request status, review stay. No forced account creation (PLAN §5.4). |
| **Receptionist** | View/create bookings on behalf of guest, check-in/out, record allowed payments, follow up service requests, contact guest. |
| **Booking Operator** | Receive requests, review availability, send offers/alternatives, confirm bookings, follow WhatsApp, edit request status, log communication. |
| **Housekeeping** | View assigned rooms, change cleaning status, complete tasks, report room issues. |
| **Manager** | View operations, manage bookings/prices (per permission)/offers/services, access reports, review staff performance. |
| **Administrator** | Full system control: users, roles, permissions, content, media, hotel settings, communications, all operational units, feature flags, audit. |

> RBAC with **fine-grained permissions** separate from role names (PLAN §39-40). The system checks the *permission*, not the role label, for sensitive decisions. `admin` role bypasses permission checks.

---

## 4. Non-Negotiable Principles (PLAN §1, §113)

### MUST (selected)
- Understand business model before implementing.
- Design user journey before screens.
- **WhatsApp is a workflow channel, not a contact button** (Rule 3).
- Admin Panel is the operational control center (Rule 4).
- Separate guest UI from business logic.
- **Backend is the source of truth** (Rule 5).
- Prevent booking conflicts.
- Record sensitive operations in audit.
- Never hard-delete business history (Rule 6: traceable).
- Content editable from admin without rebuilding (Rule 7).
- Build permissions on roles + fine-grained permissions.
- Arabic + RTL from day one.
- Test on **complete flows**, not screens (Rule 8).
- Every state transition has a reason and an owner (Rule 9).

### MUST NOT (selected)
- Build a formal app disconnected from real operations.
- Force the user through steps they don't need.
- Put sensitive booking/pricing rules inside Flutter only.
- Build a view-only dashboard with no control.
- Bury important settings in code.
- Mix staff permissions.
- Force one UI across all platforms (adaptive, not forced — PLAN §69).
- Treat "payment" as just a UI event (Rule: API success ≠ business success).
- Assume every customer wants an account before inquiring.

---

## 5. Domain Model at a Glance (PLAN §17-32)

### Booking modes (PLAN §7)
- **Direct Booking** — system can validate availability/price/rules → create request/reservation.
- **WhatsApp Assisted Booking** — needs human confirmation / negotiation / manual payment → route to WhatsApp *with a system record*.
- **Admin Created Booking** — staff creates on behalf of guest, tagged "Created by Staff" + actor + timestamp.
- **Walk-in Booking** — reception, treated as its own workflow, not an undocumented shortcut.

### Booking Request vs Reservation (PLAN §25) — critical separation
- **BookingRequest** = guest's *intent* to book (a lead, an inquiry).
- **Reservation** = a *confirmed* booking per hotel rules.

> A WhatsApp message is NOT a confirmed reservation. Flow: `Guest Request → Booking Request → Admin Review → Confirmed Reservation`.

### Reservation state machine (PLAN §23-24)
```
Draft → Pending → Awaiting Confirmation → Confirmed → Checked-In → Checked-Out → Completed
Side paths: Pending→Rejected, Pending→Cancelled, Confirmed→Cancelled, Confirmed→No-Show
```
Every sensitive transition carries: **Actor · Reason (when needed) · Timestamp · Audit**.

### Room states (PLAN §18)
`Available · Reserved · Occupied · Cleaning · Maintenance · Blocked · Out of Service`
> Staff UI may not change state without server-side operational rule verification (PLAN §18).

### Pricing (PLAN §20) + Availability (PLAN §19) engines
- Both are **server-side**. Flutter sends Intent/Request; Backend decides (PLAN §28).
- Availability ≠ `totalRooms − reservations`. It depends on room, date, reservations, room status, maintenance, blocks, occupancy rules.
- **Price snapshot** is stored on confirmation so historical bookings don't change when prices change later (PLAN §20.1, §105).
- **Double-booking prevention is server-side** (PLAN §19.1, §54).

### Payments (PLAN §26-27)
- Abstracted, multi-method (cash, bank transfer, local, online gateway when available, manual).
- Manual payment supports reference + proof file + review state + reviewer + notes.
- States: `Pending · Submitted · Under Review · Paid · Partially Paid · Failed · Cancelled · Refunded · Partially Refunded`.

### Communication Center (PLAN §9, §84)
Unified admin view of contact requests + booking requests with: Owner, Status, Priority, Last Activity, Next Action. Prevents guests from being lost between WhatsApp / Calls / App / Reception / Admin.

Contact/Booking request statuses (PLAN §8.4):
`New · Assigned · Contacted · Waiting Customer · Waiting Hotel · Confirmed · Converted · Closed · Cancelled`

### Audit (PLAN §38, §72-73, §74)
Every business-truth-changing action records: `Actor · Action · Entity · EntityID · OldValue → NewValue · Reason · Timestamp`.
**No hard delete** for bookings, payments, invoices, audit logs — use Cancel / Archive / Soft-delete (PLAN §74).

### Content control (PLAN §11-13, §100)
All variable content is editable from admin: home sections (hero/CTA/order/visibility), rooms, services, offers, hotel info, policies, FAQ. Workflow: `Draft · Published · Hidden · Archived`. Reordering + preview supported.

### Feature flags (PLAN §43)
Toggle features safely: `online_payment · reviews · offers · service_requests · guest_accounts · gallery`. Turning a feature off must not break the system.

---

## 6. Guest Journey — Fast Booking (PLAN §6, §93)

```
Home → Choose Dates → Available Rooms → Choose Room → Name + Phone → Confirm
       ↓
   Direct Confirmation  OR  WhatsApp Confirmation  OR  Admin Review
```

Ideal flow (PLAN §6.2): `Home → Dates → Rooms → Room → Name+Phone → Confirm → WhatsApp/Payment/Confirmation`.

**No steps "just to complete the system"** (PLAN §6.4). The backend may execute dozens of operations internally; the customer need not see them.

---

## 7. Acceptance Criteria (PLAN §93, §114)

### Golden journey must succeed end-to-end
Guest opens → sees hotel → selects dates → sees rooms → selects room → name+phone → submits → system creates booking request → admin sees → admin confirms/WhatsApp → guest gets confirmation → reservation visible → reception sees → check-in → service request → staff completes → check-out → invoice → review.

### WhatsApp acceptance (PLAN §94)
Guest requests booking → chooses WhatsApp → system prepares structured info → WhatsApp opens → staff receives → admin links request → admin confirms → reservation created/confirmed → guest receives confirmation.

### Admin master control (PLAN §95)
Administrator can (within permissions): content add/edit/hide/publish/reorder; rooms add/edit/disable/status/price; services add/edit/hide/price; offers create/start/stop/archive; reservations view/create/approve/edit/cancel/confirm-payment; users add/disable/assign-role/adjust-permissions; settings change contact/hotel-info/flags/policies — **all via UI, no code changes**.

### Definition of Done (PLAN §107)
`[ ] UI · [ ] Business logic · [ ] API integrated · [ ] Validation · [ ] Loading · [ ] Empty · [ ] Error · [ ] Permission check · [ ] Audit if applicable · [ ] Tests · [ ] Responsive/Adaptive · [ ] RTL`

---

## 8. Design Quality Bar (PLAN §66, §98-99)

The project must look: **hotel-grade, refined, calm, fast, trustworthy, clear**.
Must NOT look like: a store, an accounting panel in the guest UI, a template, a cluttered app.
Content copy: clear, short, natural, non-technical, on-brand.

### Color & typography (existing design system — preserved)
- Warm gold `#B8975A` (primary) + charcoal + cream `#FAF7F2` background.
- Arabic Google Font **Cairo**.
- Status colors + labels centralized.
- Mobile = bottom nav + cards + short flows. Web/Admin = sidebar + tables + filters + charts (adaptive, PLAN §69).

---

## 9. Future Expansion — explicitly OUT of scope (PLAN §110-111)

Loyalty, membership, transfers, restaurant, events, meeting rooms, advanced revenue management, multi-branch, corporate accounts, coupons, gift cards, OTA integrations, WhatsApp automation — **allowed by design but NOT built in this version** unless within real operational scope.

> "Build the minimum **complete** system, not the minimum number of screens." (PLAN §111)

---

## 10. Definition of Ready (PLAN §106)
Before implementing any feature:
`Purpose · Actor · Data · Rules · Permissions · API · Error states · Audit requirements · Dependencies known`

---

*This document is the human-facing summary of understanding. For technical architecture see `SYSTEM.md`; for the codebase map see `MAP.md`; for live progress see `STATE.md`.*
