import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/seed_data.dart';

/// Single source of truth for the whole hotel platform (see PLAN §5, §10, §62).
/// In-memory store with repository semantics + ChangeNotifier for reactive UI.
/// All business rules live here; UI only renders and calls these methods.
class HotelStore extends ChangeNotifier {
  HotelStore() {
    _seed();
  }

  // -- collections --
  late final HotelInfo hotel;
  late final List<RoomType> roomTypes;
  late final List<Room> rooms;
  late final List<Service> services;
  late final List<AppUser> users;
  final List<Guest> guests = [];
  final List<Reservation> reservations = [];
  final List<Stay> stays = [];
  final List<GuestRequest> requests = [];
  final List<Charge> charges = [];
  final List<Payment> payments = [];
  final List<AppNotification> notifications = [];
  final List<Conversation> conversations = [];
  final List<AuditEntry> audit = [];
  final List<ExtensionRequest> extensionRequests = [];
  final List<GuestAccess> accesses = [];
  final List<StaffAccess> staffAccesses = [];

  // -- sequence counters --
  int _resSeq = 420;
  int _staySeq = 883;
  int _reqSeq = 1;
  int _chargeSeq = 1;
  int _paySeq = 1;
  int _auditSeq = 1;
  int _extSeq = 1;
  int _staffCodeSeq = 100;

  // -- seed --
  void _seed() {
    hotel = Seed.hotel;
    roomTypes = Seed.roomTypes;
    services = Seed.services;
    users = Seed.users;

    // Build rooms from room type inventory.
    rooms = Seed.buildRooms(roomTypes);

    // Add demo guests & reservations & an active stay so all roles have data.
    final mohamed = Guest(
      id: 'g1',
      name: 'Mohamed Ahmed',
      email: 'mohamed.ahmed@example.com',
      phone: '+971 50 123 4567',
      nationality: 'Egypt',
      idNumber: 'A12345678',
      createdAt: DateTime(2026, 8, 12),
    );
    final sara = Guest(
      id: 'g2',
      name: 'Sara Al-Mansouri',
      email: 'sara.m@example.com',
      phone: '+971 55 998 1200',
      nationality: 'UAE',
      idNumber: '7841990',
      createdAt: DateTime(2026, 8, 20),
    );
    final john = Guest(
      id: 'g3',
      name: 'John Carter',
      email: 'john.carter@example.com',
      phone: '+1 415 555 0188',
      nationality: 'USA',
      idNumber: 'P8841207',
      createdAt: DateTime(2026, 8, 25),
    );
    guests.addAll([mohamed, sara, john]);

    final today = _today();

    // Active stay: Mohamed, room 204, in-house
    final res1 = Reservation(
      id: Fmt.reservationId(421),
      guestId: mohamed.id,
      roomTypeId: 'deluxe',
      checkIn: today,
      checkOut: today.add(const Duration(days: 3)),
      adults: 2,
      children: 0,
      status: ReservationStatus.checkedIn,
      paymentMethod: PaymentMethod.creditCard,
      amountPaid: 0,
      createdAt: DateTime(2026, 8, 20),
      price: const PriceSnapshot(
        nightlyRate: 780,
        nights: 3,
        subtotal: 2340,
        taxRate: 0.05,
        tax: 117,
        total: 2457,
      ),
    );
    reservations.add(res1);
    final room204 = roomByNumber('204')!;
    final stay1 = Stay(
      id: Fmt.stayId(883),
      reservationId: res1.id,
      guestId: mohamed.id,
      roomId: room204.id,
      checkIn: today,
      checkOut: today.add(const Duration(days: 3)),
      status: StayStatus.inHouse,
      createdAt: DateTime.now(),
    );
    stays.add(stay1);
    res1.stayId = stay1.id;
    res1.assignedRoomId = room204.id;
    room204.status = RoomStatus.occupied;
    room204.currentStayId = stay1.id;

    // Guest access code per PLAN_MOBILE-APK §5: H{6digits}{2checksum}.
    // Seeded demo code H834729X7 for Mohamed's active stay.
    final access1 = GuestAccess(
      id: 'GA1',
      stayId: stay1.id,
      guestId: mohamed.id,
      code: 'H834729X7',
      issuedAt: DateTime.now(),
      expiresAt: stay1.checkOut.add(const Duration(hours: 12)),
    );
    accesses.add(access1);
    stay1.guestAccessId = access1.id;

    // Seed a couple of charges for Mohamed's stay
    charges.add(
      Charge(
        id: Fmt.chargeId(1),
        stayId: stay1.id,
        description: 'Room — 3 nights',
        category: 'Room',
        quantity: 3,
        unitPrice: 780,
        gross: 2340,
        discount: 0,
        net: 2340,
        tax: 117,
        at: DateTime.now(),
        source: 'room',
        createdBy: 'system',
      ),
    );
    charges.add(
      Charge(
        id: Fmt.chargeId(2),
        stayId: stay1.id,
        description: 'Minibar',
        category: 'F&B',
        quantity: 2,
        unitPrice: 35,
        gross: 70,
        discount: 0,
        net: 70,
        tax: 3.5,
        at: DateTime.now(),
        source: 'manual',
        createdBy: 'reception',
      ),
    );
    payments.add(
      Payment(
        id: Fmt.paymentId(1),
        stayId: stay1.id,
        method: PaymentMethod.creditCard,
        amount: 1000,
        at: DateTime.now(),
        reference: 'VISA-****1230',
        recordedBy: 'reception',
      ),
    );
    _chargeSeq = 3;
    _paySeq = 2;

    // One in-progress request for Mohamed
    requests.add(
      GuestRequest(
        id: Fmt.requestId(1),
        stayId: stay1.id,
        guestId: mohamed.id,
        roomId: room204.id,
        category: ServiceCategory.housekeeping,
        title: 'Extra towels',
        description: 'Please bring two extra bath towels to room 204.',
        status: RequestStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        assignedTo: 'Housekeeping — Layla',
        messages: [
          RequestMessage(
            id: 'm1',
            authorId: 'g1',
            fromStaff: false,
            text: 'Please bring two extra bath towels.',
            at: DateTime.now().subtract(const Duration(minutes: 25)),
          ),
          RequestMessage(
            id: 'm2',
            authorId: 'u2',
            fromStaff: true,
            text: 'On the way, 5 minutes.',
            at: DateTime.now().subtract(const Duration(minutes: 18)),
          ),
        ],
      ),
    );
    _reqSeq = 2;

    // Conversation for Mohamed
    conversations.add(
      Conversation(
        id: 'CV1',
        stayId: stay1.id,
        guestId: mohamed.id,
        messages: [
          RequestMessage(
            id: 'cm1',
            authorId: 'g1',
            fromStaff: false,
            text: 'Hello, is the gym open 24 hours?',
            at: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          RequestMessage(
            id: 'cm2',
            authorId: 'u2',
            fromStaff: true,
            text: 'Yes, the gym is open 24 hours on the 3rd floor.',
            at: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      ),
    );

    // Today's arrival: Sara (confirmed, not yet checked in)
    final res2 = Reservation(
      id: Fmt.reservationId(422),
      guestId: sara.id,
      roomTypeId: 'suite',
      checkIn: today,
      checkOut: today.add(const Duration(days: 2)),
      adults: 2,
      children: 1,
      status: ReservationStatus.confirmed,
      paymentMethod: PaymentMethod.payAtHotel,
      amountPaid: 0,
      createdAt: DateTime(2026, 8, 22),
      price: const PriceSnapshot(
        nightlyRate: 1450,
        nights: 2,
        subtotal: 2900,
        taxRate: 0.05,
        tax: 145,
        total: 3045,
      ),
    );
    reservations.add(res2);

    // Today's departure: John (in-house, checkout today)
    final res3 = Reservation(
      id: Fmt.reservationId(419),
      guestId: john.id,
      roomTypeId: 'standard',
      checkIn: today.subtract(const Duration(days: 2)),
      checkOut: today,
      adults: 1,
      children: 0,
      status: ReservationStatus.checkedIn,
      paymentMethod: PaymentMethod.cash,
      amountPaid: 0,
      createdAt: DateTime(2026, 8, 15),
      price: const PriceSnapshot(
        nightlyRate: 520,
        nights: 2,
        subtotal: 1040,
        taxRate: 0.05,
        tax: 52,
        total: 1092,
      ),
    );
    reservations.add(res3);
    final room301 = roomByNumber('301')!;
    final stay3 = Stay(
      id: Fmt.stayId(880),
      reservationId: res3.id,
      guestId: john.id,
      roomId: room301.id,
      checkIn: today.subtract(const Duration(days: 2)),
      checkOut: today,
      status: StayStatus.inHouse,
      createdAt: today
          .subtract(const Duration(days: 2))
          .add(const Duration(hours: 3)),
    );
    stays.add(stay3);
    res3.stayId = stay3.id;
    res3.assignedRoomId = room301.id;
    room301.status = RoomStatus.occupied;
    room301.currentStayId = stay3.id;
    charges.add(
      Charge(
        id: Fmt.chargeId(3),
        stayId: stay3.id,
        description: 'Room — 2 nights',
        category: 'Room',
        quantity: 2,
        unitPrice: 520,
        gross: 1040,
        discount: 0,
        net: 1040,
        tax: 52,
        at: stay3.createdAt,
        source: 'room',
        createdBy: 'system',
      ),
    );

    // A confirmed future reservation
    final res4 = Reservation(
      id: Fmt.reservationId(425),
      guestId: mohamed.id,
      roomTypeId: 'standard',
      checkIn: today.add(const Duration(days: 5)),
      checkOut: today.add(const Duration(days: 7)),
      adults: 1,
      children: 0,
      status: ReservationStatus.confirmed,
      paymentMethod: PaymentMethod.payAtHotel,
      amountPaid: 0,
      createdAt: DateTime(2026, 8, 28),
      price: const PriceSnapshot(
        nightlyRate: 520,
        nights: 2,
        subtotal: 1040,
        taxRate: 0.05,
        tax: 52,
        total: 1092,
      ),
    );
    reservations.add(res4);

    notifications.add(
      AppNotification(
        id: 'n1',
        title: 'Welcome to Lumière Grand',
        body:
            'Your stay in room 204 is active until ${Fmt.dateShort(stay1.checkOut)}.',
        at: DateTime.now().subtract(const Duration(hours: 5)),
        scope: 'guest',
        guestId: mohamed.id,
      ),
    );
    notifications.add(
      AppNotification(
        id: 'n2',
        title: 'New arrival: Sara Al-Mansouri',
        body: 'Reservation ${res2.id}, Suite, arriving today.',
        at: DateTime.now().subtract(const Duration(hours: 1)),
        scope: 'reception',
      ),
    );

    // Staff access codes per PLAN_MOBILE-APK §5 — generated by the admin from
    // the admin control panel. Format: R{6digits}{2checksum} for reception,
    // A{6digits}{2checksum} for admin. Seeded here so the unified login flow
    // is demonstrable. The admin code bootstraps the admin panel; the
    // reception code is one the admin "created" for the receptionist.
    staffAccesses.add(
      StaffAccess(
        id: 'sa-admin-1',
        code: 'A371849L9',
        staffName: 'Omar (Owner)',
        role: 'admin',
        createdAt: DateTime(2026, 8, 1),
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      ),
    );
    staffAccesses.add(
      StaffAccess(
        id: 'sa-rec-1',
        code: 'R492671M3',
        staffName: 'Layla (Front Desk)',
        role: 'reception',
        createdAt: DateTime(2026, 8, 10),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
        lastUsedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    );
    _staffCodeSeq = 3;
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ============================================================
  //  LOOKUPS
  // ============================================================
  Room? roomById(String id) => firstWhereOrNull(rooms, (r) => r.id == id);
  Room? roomByNumber(String n) => firstWhereOrNull(rooms, (r) => r.number == n);
  RoomType? roomTypeById(String id) =>
      firstWhereOrNull(roomTypes, (t) => t.id == id);
  Guest? guestById(String id) => firstWhereOrNull(guests, (g) => g.id == id);
  Stay? stayById(String id) => firstWhereOrNull(stays, (s) => s.id == id);
  Reservation? reservationById(String id) =>
      firstWhereOrNull(reservations, (r) => r.id == id);
  GuestRequest? requestById(String id) =>
      firstWhereOrNull(requests, (r) => r.id == id);
  Conversation? conversationForStay(String stayId) =>
      firstWhereOrNull(conversations, (c) => c.stayId == stayId);

  List<Stay> get activeStays => stays
      .where(
        (s) =>
            s.status == StayStatus.inHouse ||
            s.status == StayStatus.checkedIn ||
            s.status == StayStatus.extensionPending ||
            s.status == StayStatus.checkoutPending,
      )
      .toList();

  List<Stay> staysForGuest(String guestId) =>
      stays.where((s) => s.guestId == guestId).toList();

  Stay? currentStayForGuest(String guestId) {
    final list = staysForGuest(guestId);
    if (list.isEmpty) return null;
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final s = list.first;
    if (s.status == StayStatus.checkedOut || s.status == StayStatus.closed) {
      return null;
    }
    return s;
  }

  List<GuestRequest> requestsForStay(String stayId) =>
      requests.where((r) => r.stayId == stayId).toList();
  List<GuestRequest> requestsForGuest(String guestId) =>
      requests.where((r) => r.guestId == guestId).toList();
  List<Charge> chargesForStay(String stayId) =>
      charges.where((c) => c.stayId == stayId).toList();
  List<Payment> paymentsForStay(String stayId) =>
      payments.where((p) => p.stayId == stayId).toList();
  List<AppNotification> notificationsForGuest(String guestId) =>
      notifications.where((n) => n.guestId == guestId).toList();

  // ============================================================
  //  AVAILABILITY & BOOKING (PLAN §8)
  // ============================================================

  /// Returns the count of sellable rooms for a room type across a date range.
  int availableCountForType(String roomTypeId, DateTime ci, DateTime co) {
    if (!co.isAfter(ci)) return 0;
    final typeRooms = rooms.where((r) => r.roomTypeId == roomTypeId).toList();
    int available = 0;
    for (final room in typeRooms) {
      if (!room.active) continue;
      if (room.status == RoomStatus.outOfOrder ||
          room.status == RoomStatus.outOfService) {
        continue;
      }
      if (_roomOccupiedInRange(room, ci, co)) continue;
      available++;
    }
    return available;
  }

  bool _roomOccupiedInRange(Room room, DateTime ci, DateTime co) {
    for (final s in stays) {
      if (s.roomId != room.id) continue;
      if (s.status == StayStatus.checkedOut || s.status == StayStatus.closed) {
        continue;
      }
      if (_overlaps(ci, co, s.checkIn, s.checkOut)) return true;
    }
    for (final r in reservations) {
      if (r.assignedRoomId != room.id) continue;
      if (r.status == ReservationStatus.cancelled ||
          r.status == ReservationStatus.noShow)
        continue;
      if (_overlaps(ci, co, r.checkIn, r.checkOut)) return true;
    }
    return false;
  }

  bool _overlaps(DateTime a1, DateTime a2, DateTime b1, DateTime b2) {
    return a1.isBefore(b2) && b1.isBefore(a2);
  }

  PriceSnapshot calculatePrice(
    RoomType type,
    DateTime ci,
    DateTime co,
    int adults,
  ) {
    final nights = Fmt.nights(ci, co);
    final base = type.basePrice * nights;
    double extra = 0;
    if (adults > type.defaultAdults) {
      extra = (adults - type.defaultAdults) * 75.0 * nights;
    }
    final subtotal = base + extra;
    final tax = subtotal * Brand.defaultTaxRate;
    return PriceSnapshot(
      nightlyRate: type.basePrice,
      nights: nights,
      subtotal: subtotal,
      taxRate: Brand.defaultTaxRate,
      tax: tax,
      total: subtotal + tax,
    );
  }

  /// Create a reservation (PLAN §8, §9). Returns the new reservation.
  Reservation createReservation({
    required String guestId,
    required String roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    required PaymentMethod paymentMethod,
    double amountPaid = 0,
  }) {
    final type = roomTypeById(roomTypeId)!;
    final price = calculatePrice(type, checkIn, checkOut, adults);
    final res = Reservation(
      id: Fmt.reservationId(++_resSeq),
      guestId: guestId,
      roomTypeId: roomTypeId,
      checkIn: checkIn,
      checkOut: checkOut,
      adults: adults,
      children: children,
      status: ReservationStatus.confirmed,
      price: price,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      createdAt: DateTime.now(),
    );
    reservations.insert(0, res);
    _audit(
      'system',
      'create-reservation',
      res.id,
      'Guest $guestId, ${type.id}, ${Fmt.dateNum(checkIn)} → ${Fmt.dateNum(checkOut)}',
    );
    _notify(
      title: 'Reservation confirmed',
      body: '${res.id} • ${type.name} • ${Fmt.dateShort(checkIn)}',
      scope: 'reception',
    );
    notifyListeners();
    return res;
  }

  /// Find or create a guest by email.
  Guest upsertGuest({
    required String name,
    required String email,
    required String phone,
  }) {
    final existing = firstWhereOrNull(guests, (g) => g.email == email);
    if (existing != null) {
      existing.name = name;
      existing.phone = phone;
      notifyListeners();
      return existing;
    }
    final g = Guest(
      id: 'g${guests.length + 1}-${Random().nextInt(9999)}',
      name: name,
      email: email,
      phone: phone,
    );
    guests.insert(0, g);
    notifyListeners();
    return g;
  }

  void cancelReservation(String resId, String reason) {
    final r = reservationById(resId);
    if (r == null) return;
    r.status = ReservationStatus.cancelled;
    r.cancellationReason = reason;
    _audit('reception', 'cancel-reservation', resId, reason);
    notifyListeners();
  }

  /// Website Manage-Booking lookup (PLAN_WEBSITE §47).
  /// Validate booking reference + verification value (phone or email).
  /// Never allow lookup by reference alone.
  Reservation? lookupReservation(String ref, String verification) {
    final r = reservationById(ref.trim().toUpperCase());
    if (r == null) return null;
    final guest = guestById(r.guestId);
    if (guest == null) return null;
    final v = verification.trim().toLowerCase();
    if (v.isEmpty) return null;
    // Match phone or email (case-insensitive, trimmed).
    final phoneMatch =
        guest.phone.toLowerCase().replaceAll(' ', '') == v.replaceAll(' ', '');
    final emailMatch = guest.email.toLowerCase() == v;
    if (!phoneMatch && !emailMatch) return null;
    return r;
  }

  void markNoShow(String resId) {
    final r = reservationById(resId);
    if (r == null) return;
    r.status = ReservationStatus.noShow;
    _audit('reception', 'no-show', resId, null);
    notifyListeners();
  }

  // ============================================================
  //  CHECK-IN (PLAN §12)
  // ============================================================

  /// Assign a specific room to a reservation before/at check-in.
  void assignRoomToReservation(String resId, String roomId) {
    final r = reservationById(resId);
    final room = roomById(roomId);
    if (r == null || room == null) return;
    r.assignedRoomId = roomId;
    room.status = RoomStatus.reserved;
    _audit('reception', 'assign-room', resId, 'Room ${room.number}');
    notifyListeners();
  }

  /// Complete check-in: creates active Stay, sets room occupied, generates
  /// guest access code, links everything. (PLAN §12.2, §12.3)
  Stay checkIn({
    required String reservationId,
    required String actor,
    double? deposit,
    PaymentMethod? depositMethod,
  }) {
    final r = reservationById(reservationId)!;
    // Pick a room: prefer assigned, else first available of the type.
    Room room;
    if (r.assignedRoomId != null) {
      room = roomById(r.assignedRoomId!)!;
    } else {
      room = _pickAvailableRoomForType(r.roomTypeId, r.checkIn, r.checkOut)!;
      r.assignedRoomId = room.id;
    }

    final stay = Stay(
      id: Fmt.stayId(++_staySeq),
      reservationId: r.id,
      guestId: r.guestId,
      roomId: room.id,
      checkIn: r.checkIn,
      checkOut: r.checkOut,
      status: StayStatus.inHouse,
      createdAt: DateTime.now(),
    );
    stays.insert(0, stay);
    r.stayId = stay.id;
    r.status = ReservationStatus.checkedIn;
    room.status = RoomStatus.occupied;
    room.currentStayId = stay.id;

    // Generate access code (PLAN §13)
    final code = _generateAccessCode();
    final access = GuestAccess(
      id: 'GA${accesses.length + 1}',
      stayId: stay.id,
      guestId: r.guestId,
      code: code,
      issuedAt: DateTime.now(),
      expiresAt: stay.checkOut.add(const Duration(hours: 12)),
    );
    accesses.add(access);
    stay.guestAccessId = access.id;

    // Opening room charge
    charges.add(
      Charge(
        id: Fmt.chargeId(++_chargeSeq),
        stayId: stay.id,
        description:
            'Room ${room.number} — ${r.price.nights} ${r.price.nights == 1 ? 'night' : 'nights'}',
        category: 'Room',
        quantity: r.price.nights,
        unitPrice: r.price.nightlyRate,
        gross: r.price.subtotal,
        discount: 0,
        net: r.price.subtotal,
        tax: r.price.tax,
        at: DateTime.now(),
        source: 'room',
        createdBy: actor,
      ),
    );

    if (deposit != null && deposit > 0) {
      payments.add(
        Payment(
          id: Fmt.paymentId(++_paySeq),
          stayId: stay.id,
          method: depositMethod ?? PaymentMethod.creditCard,
          amount: deposit,
          at: DateTime.now(),
          reference: 'Deposit at check-in',
          recordedBy: actor,
        ),
      );
    }

    _audit(actor, 'check-in', stay.id, 'Room ${room.number}, code $code');
    _notify(
      title: 'Checked-in: ${guestById(r.guestId)?.name ?? ""}',
      body: 'Room ${room.number} • Access code $code',
      scope: 'reception',
    );
    _notify(
      title: 'Welcome to ${hotel.name}',
      body: 'You are checked in to room ${room.number}. Access code: $code',
      scope: 'guest',
      guestId: r.guestId,
    );
    notifyListeners();
    return stay;
  }

  Room? _pickAvailableRoomForType(String roomTypeId, DateTime ci, DateTime co) {
    for (final r in rooms) {
      if (r.roomTypeId != roomTypeId) continue;
      if (!r.active) continue;
      if (!r.status.isSellable) continue;
      if (_roomOccupiedInRange(r, ci, co)) continue;
      return r;
    }
    return null;
  }

  /// Generate a Guest access code per PLAN_MOBILE-APK §5:
  /// H + 6 digits + 2-char checksum (e.g. H834729X7).
  String _generateAccessCode() {
    return Fmt.guestCode();
  }

  /// Validate guest access code (PLAN §13.2). Returns matching stay if valid.
  Stay? validateAccessCode(String code) {
    final c = code.trim().toUpperCase();
    if (Fmt.codeType(c) != 'guest') return null;
    final access = firstWhereOrNull(accesses, (a) => a.code == c && a.active);
    if (access == null) return null;
    if (access.expiresAt != null && DateTime.now().isAfter(access.expiresAt!)) {
      return null;
    }
    return stayById(access.stayId);
  }

  // ============================================================
  //  GUEST REQUESTS (PLAN §15-18)
  // ============================================================
  GuestRequest createRequest({
    required String stayId,
    String? serviceId,
    required ServiceCategory category,
    required String title,
    required String description,
    RequestPriority priority = RequestPriority.normal,
  }) {
    final stay = stayById(stayId)!;
    final req = GuestRequest(
      id: Fmt.requestId(++_reqSeq),
      stayId: stayId,
      guestId: stay.guestId,
      roomId: stay.roomId,
      serviceId: serviceId,
      category: category,
      title: title,
      description: description,
      priority: priority,
      status: RequestStatus.newRequest,
      createdAt: DateTime.now(),
    );
    requests.insert(0, req);
    _audit(
      'guest',
      'create-request',
      req.id,
      '${category.label}: $title (room ${roomById(stay.roomId)?.number})',
    );
    _notify(
      title: 'New request • Room ${roomById(stay.roomId)?.number}',
      body: '${category.label}: $title',
      scope: 'reception',
    );
    notifyListeners();
    return req;
  }

  void updateRequestStatus(
    String reqId,
    RequestStatus status, {
    String? assignedTo,
  }) {
    final r = requestById(reqId);
    if (r == null) return;
    r.status = status;
    if (assignedTo != null) r.assignedTo = assignedTo;
    if (status == RequestStatus.completed) r.completedAt = DateTime.now();
    _audit('reception', 'request-status', reqId, status.label);
    _notify(
      title: 'Request ${r.title} • ${status.label}',
      body: 'Room ${roomById(r.roomId)?.number}',
      scope: 'guest',
      guestId: r.guestId,
    );
    notifyListeners();
  }

  void addRequestMessage(String reqId, RequestMessage msg) {
    final r = requestById(reqId);
    if (r == null) return;
    r.messages.add(msg);
    notifyListeners();
  }

  void addConversationMessage(String stayId, RequestMessage msg) {
    var conv = conversationForStay(stayId);
    if (conv == null) {
      conv = Conversation(
        id: 'CV${conversations.length + 1}',
        stayId: stayId,
        guestId: stayById(stayId)!.guestId,
      );
      conversations.add(conv);
    }
    conv.messages.add(msg);
    notifyListeners();
  }

  // ============================================================
  //  BILLING (PLAN §27)
  // ============================================================
  double chargesTotal(String stayId) =>
      chargesForStay(stayId).fold(0.0, (s, c) => s + c.net + c.tax);
  double paymentsTotal(String stayId) =>
      paymentsForStay(stayId).fold(0.0, (s, p) => s + p.amount);
  double outstandingBalance(String stayId) =>
      chargesTotal(stayId) - paymentsTotal(stayId);

  void addCharge({
    required String stayId,
    required String description,
    required String category,
    required double unitPrice,
    int quantity = 1,
    double discount = 0,
    required String actor,
  }) {
    final gross = unitPrice * quantity;
    final net = gross - discount;
    final tax = net * Brand.defaultTaxRate;
    charges.add(
      Charge(
        id: Fmt.chargeId(++_chargeSeq),
        stayId: stayId,
        description: description,
        category: category,
        quantity: quantity,
        unitPrice: unitPrice,
        gross: gross,
        discount: discount,
        net: net,
        tax: tax,
        at: DateTime.now(),
        source: 'manual',
        createdBy: actor,
      ),
    );
    _audit(actor, 'add-charge', stayId, '$description • ${Fmt.money(net)}');
    notifyListeners();
  }

  void recordPayment({
    required String stayId,
    required PaymentMethod method,
    required double amount,
    required String reference,
    required String actor,
  }) {
    payments.add(
      Payment(
        id: Fmt.paymentId(++_paySeq),
        stayId: stayId,
        method: method,
        amount: amount,
        at: DateTime.now(),
        reference: reference,
        recordedBy: actor,
      ),
    );
    _audit(
      actor,
      'record-payment',
      stayId,
      '${Fmt.money(amount)} • $reference',
    );
    notifyListeners();
  }

  // ============================================================
  //  EXTENSION (PLAN §24)
  // ============================================================
  ExtensionRequest requestExtension({
    required String stayId,
    required DateTime requestedCheckout,
    String? reason,
  }) {
    final stay = stayById(stayId)!;
    final type = roomTypeById(roomById(stay.roomId)!.roomTypeId)!;
    final nights = Fmt.nights(stay.checkOut, requestedCheckout);
    final cost = type.basePrice * nights;
    final ext = ExtensionRequest(
      id: 'EXT${++_extSeq}',
      stayId: stayId,
      guestId: stay.guestId,
      currentCheckout: stay.checkOut,
      requestedCheckout: requestedCheckout,
      additionalCost: cost,
      reason: reason,
      createdAt: DateTime.now(),
    );
    extensionRequests.insert(0, ext);
    stay.status = StayStatus.extensionPending;
    _audit(
      'guest',
      'request-extension',
      stayId,
      'to ${Fmt.dateNum(requestedCheckout)}, cost ${Fmt.money(cost)}',
    );
    _notify(
      title: 'Extension request • Room ${roomById(stay.roomId)?.number}',
      body: 'Requested checkout ${Fmt.dateShort(requestedCheckout)}',
      scope: 'reception',
    );
    notifyListeners();
    return ext;
  }

  bool approveExtension(String extId, String actor) {
    final ext = firstWhereOrNull(extensionRequests, (e) => e.id == extId);
    if (ext == null || ext.approved) return false;
    final stay = stayById(ext.stayId)!;
    // Re-check availability
    final room = roomById(stay.roomId)!;
    if (_roomOccupiedInRangeExcluding(
      room,
      stay,
      ext.currentCheckout,
      ext.requestedCheckout,
    )) {
      return false;
    }
    stay.checkOut = ext.requestedCheckout;
    stay.status = StayStatus.inHouse;
    ext.approved = true;
    // Add charge for extension
    charges.add(
      Charge(
        id: Fmt.chargeId(++_chargeSeq),
        stayId: stay.id,
        description:
            'Extension ${Fmt.nights(ext.currentCheckout, ext.requestedCheckout)} ${Fmt.nights(ext.currentCheckout, ext.requestedCheckout) == 1 ? 'night' : 'nights'}',
        category: 'Room',
        quantity: Fmt.nights(ext.currentCheckout, ext.requestedCheckout),
        unitPrice: roomTypeById(room.roomTypeId)!.basePrice,
        gross: ext.additionalCost,
        discount: 0,
        net: ext.additionalCost,
        tax: ext.additionalCost * Brand.defaultTaxRate,
        at: DateTime.now(),
        source: 'room',
        createdBy: actor,
      ),
    );
    _audit(
      actor,
      'approve-extension',
      stay.id,
      'to ${Fmt.dateNum(ext.requestedCheckout)}',
    );
    _notify(
      title: 'Extension approved',
      body: 'New checkout: ${Fmt.dateShort(ext.requestedCheckout)}',
      scope: 'guest',
      guestId: stay.guestId,
    );
    notifyListeners();
    return true;
  }

  void rejectExtension(String extId, String actor) {
    final ext = firstWhereOrNull(extensionRequests, (e) => e.id == extId);
    if (ext == null) return;
    final stay = stayById(ext.stayId)!;
    if (stay.status == StayStatus.extensionPending) {
      stay.status = StayStatus.inHouse;
    }
    _audit(actor, 'reject-extension', ext.stayId, null);
    _notify(
      title: 'Extension rejected',
      body: 'Checkout remains ${Fmt.dateShort(ext.currentCheckout)}',
      scope: 'guest',
      guestId: stay.guestId,
    );
    notifyListeners();
  }

  bool _roomOccupiedInRangeExcluding(
    Room room,
    Stay exclude,
    DateTime ci,
    DateTime co,
  ) {
    for (final s in stays) {
      if (s.id == exclude.id) continue;
      if (s.roomId != room.id) continue;
      if (s.status == StayStatus.checkedOut || s.status == StayStatus.closed) {
        continue;
      }
      if (_overlaps(ci, co, s.checkIn, s.checkOut)) return true;
    }
    return false;
  }

  // ============================================================
  //  ROOM TRANSFER (PLAN §22)
  // ============================================================
  void transferRoom({
    required String stayId,
    required String newRoomId,
    required String reason,
    required String actor,
  }) {
    final stay = stayById(stayId)!;
    final oldRoom = roomById(stay.roomId)!;
    final newRoom = roomById(newRoomId)!;
    stay.transfers.add(
      RoomTransfer(
        at: DateTime.now(),
        fromRoomId: oldRoom.id,
        toRoomId: newRoom.id,
        reason: reason,
        approvedBy: actor,
      ),
    );
    oldRoom.status = RoomStatus.dirty;
    oldRoom.currentStayId = null;
    stay.roomId = newRoom.id;
    newRoom.status = RoomStatus.occupied;
    newRoom.currentStayId = stay.id;
    final res = reservationById(stay.reservationId);
    if (res != null) res.assignedRoomId = newRoom.id;
    _audit(
      actor,
      'room-transfer',
      stayId,
      '${oldRoom.number} → ${newRoom.number} ($reason)',
    );
    _notify(
      title: 'Room changed',
      body: 'You have been moved to room ${newRoom.number}',
      scope: 'guest',
      guestId: stay.guestId,
    );
    notifyListeners();
  }

  void updateRoomStatus(String roomId, RoomStatus status, String actor) {
    final r = roomById(roomId);
    if (r == null) return;
    r.status = status;
    _audit(actor, 'room-status', roomId, '${r.number}: ${status.label}');
    notifyListeners();
  }

  // ============================================================
  //  CHECKOUT (PLAN §29)
  // ============================================================
  void requestCheckout(String stayId, String guestId) {
    final stay = stayById(stayId);
    if (stay == null) return;
    stay.status = StayStatus.checkoutPending;
    _audit('guest', 'request-checkout', stayId, null);
    _notify(
      title: 'Checkout request • Room ${roomById(stay.roomId)?.number}',
      body: 'Outstanding ${Fmt.money(outstandingBalance(stayId))}',
      scope: 'reception',
    );
    notifyListeners();
  }

  void completeCheckout({required String stayId, required String actor}) {
    final stay = stayById(stayId);
    if (stay == null) return;
    stay.status = StayStatus.checkedOut;
    final room = roomById(stay.roomId)!;
    room.status = RoomStatus.dirty;
    room.currentStayId = null;
    final res = reservationById(stay.reservationId);
    if (res != null) res.status = ReservationStatus.checkedOut;
    final access = firstWhereOrNull(accesses, (a) => a.stayId == stayId);
    if (access != null) access.active = false;
    _audit(actor, 'checkout', stayId, 'Room ${room.number}');
    _notify(
      title: 'Checked-out: ${guestById(stay.guestId)?.name ?? ""}',
      body: 'Room ${room.number} → dirty',
      scope: 'reception',
    );
    notifyListeners();
  }

  // ============================================================
  //  AUDIT + NOTIFY (internal)
  // ============================================================
  void _audit(String actor, String action, String target, String? detail) {
    audit.insert(
      0,
      AuditEntry(
        id: 'A${++_auditSeq}',
        at: DateTime.now(),
        actor: actor,
        action: action,
        target: target,
        detail: detail,
      ),
    );
  }

  void _auditManual(
    String actor,
    String action,
    String target,
    String? detail,
  ) {
    _audit(actor, action, target, detail);
    notifyListeners();
  }

  void _notify({
    required String title,
    required String body,
    String? scope,
    String? guestId,
  }) {
    notifications.insert(
      0,
      AppNotification(
        id: 'n${notifications.length + 1}-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        at: DateTime.now(),
        scope: scope,
        guestId: guestId,
      ),
    );
  }

  void markNotificationRead(String id) {
    final n = firstWhereOrNull(notifications, (x) => x.id == id);
    if (n != null) {
      // notifications are immutable-ish; replace via index
      final i = notifications.indexOf(n);
      notifications[i] = AppNotification(
        id: n.id,
        title: n.title,
        body: n.body,
        at: n.at,
        scope: n.scope,
        guestId: n.guestId,
        read: true,
      );
      notifyListeners();
    }
  }

  List<AppNotification> staffNotifications(String scope) =>
      notifications.where((n) => n.scope == scope).toList();

  // expose for admin actions
  void adminAddRoomType(RoomType t) {
    roomTypes.add(t);
    _audit('admin', 'create-room-type', t.id, t.name);
    notifyListeners();
  }

  void adminToggleRoomActive(String roomId) {
    final r = roomById(roomId);
    if (r == null) return;
    r.active = !r.active;
    _audit(
      'admin',
      'toggle-room-active',
      roomId,
      r.active ? 'active' : 'inactive',
    );
    notifyListeners();
  }

  // ============================================================
  //  STAFF ACCESS CODES (PLAN §4.1, §37)
  //  Generated by the admin from the admin control panel. A staff
  //  member enters the code at the unified login screen; the system
  //  validates it and routes to the role-specific dashboard.
  // ============================================================

  /// Validate a staff access code (PLAN_MOBILE-APK §5). The code prefix
  /// (R=reception, A=admin) determines the role. Returns the matching
  /// StaffAccess if active and not expired, else null. Updates lastUsedAt.
  StaffAccess? validateStaffCode(String code) {
    final c = code.trim().toUpperCase();
    final type = Fmt.codeType(c);
    if (type != 'reception' && type != 'admin') return null;
    final sa = firstWhereOrNull(staffAccesses, (a) => a.code == c && a.active);
    if (sa == null) return null;
    if (sa.expiresAt != null && DateTime.now().isAfter(sa.expiresAt!)) {
      return null;
    }
    sa.lastUsedAt = DateTime.now();
    return sa;
  }

  /// Admin creates a new staff access code for a receptionist or another
  /// admin. Format per PLAN_MOBILE-APK §5: R{6digits}{2chk} or A{6digits}{2chk}.
  StaffAccess createStaffCode({
    required String staffName,
    required String role,
    int validityDays = 90,
  }) {
    final code = role == 'admin' ? Fmt.adminCode() : Fmt.receptionCode();
    _staffCodeSeq++;
    final sa = StaffAccess(
      id: 'sa-${staffAccesses.length + 1}-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      staffName: staffName,
      role: role,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: validityDays)),
    );
    staffAccesses.insert(0, sa);
    _audit('admin', 'create-staff-code', code, '$staffName ($role)');
    notifyListeners();
    return sa;
  }

  /// Admin revokes (deactivates) a staff access code.
  void revokeStaffCode(String id) {
    final sa = firstWhereOrNull(staffAccesses, (a) => a.id == id);
    if (sa == null) return;
    sa.active = false;
    _audit('admin', 'revoke-staff-code', sa.code, sa.staffName);
    notifyListeners();
  }

  /// Admin regenerates a staff access code (new code value, same identity).
  void regenerateStaffCode(String id) {
    final sa = firstWhereOrNull(staffAccesses, (a) => a.id == id);
    if (sa == null) return;
    // New code per PLAN §5 format.
    final newCode = sa.role == 'admin' ? Fmt.adminCode() : Fmt.receptionCode();
    _staffCodeSeq++;
    final idx = staffAccesses.indexOf(sa);
    staffAccesses[idx] = StaffAccess(
      id: sa.id,
      code: newCode,
      staffName: sa.staffName,
      role: sa.role,
      createdAt: sa.createdAt,
      expiresAt: sa.expiresAt,
      lastUsedAt: sa.lastUsedAt,
      active: sa.active,
    );
    _audit('admin', 'regenerate-staff-code', newCode, sa.staffName);
    notifyListeners();
  }

  // helpers
  T? firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }
}
