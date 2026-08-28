// Data models for the hotel platform

class HotelSettings {
  final Map<String, String> values;
  HotelSettings(this.values);
  String? get hotelNameAr => values['hotel.name_ar'];
  String? get hotelNameEn => values['hotel.name_en'];
  String? get phone => values['hotel.phone'];
  String? get whatsapp => values['hotel.whatsapp'];
  String? get email => values['hotel.email'];
  String? get addressAr => values['hotel.address_ar'];
  String? get checkinTime => values['hotel.checkin_time'];
  String? get checkoutTime => values['hotel.checkout_time'];
  String? get currencySymbol => values['localization.currency_symbol_ar'];
  factory HotelSettings.fromJson(Map<String, dynamic> j) => HotelSettings(j.map((k, v) => MapEntry(k, v.toString())));
}

class RoomType {
  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final double basePrice;
  final String currency;
  final int capacity;
  final String beds;
  final double? size;
  final List<String> amenities;
  final String? imageUrl;
  final String status;
  RoomType({required this.id, required this.slug, required this.nameAr, required this.nameEn, required this.descriptionAr, required this.descriptionEn, required this.basePrice, required this.currency, required this.capacity, required this.beds, this.size, required this.amenities, this.imageUrl, required this.status});
  factory RoomType.fromJson(Map<String, dynamic> j) => RoomType(
    id: j['id'], slug: j['slug'], nameAr: j['nameAr'], nameEn: j['nameEn'],
    descriptionAr: j['descriptionAr'] ?? '', descriptionEn: j['descriptionEn'] ?? '',
    basePrice: (j['basePrice'] is num ? (j['basePrice'] as num).toDouble() : double.tryParse(j['basePrice'].toString()) ?? 0),
    currency: j['currency'] ?? 'YER', capacity: j['capacity'] ?? 2, beds: j['beds'] ?? '',
    size: j['size']?.toDouble(), amenities: List<String>.from(j['amenities'] ?? []),
    imageUrl: j['imageUrl'], status: j['status'] ?? 'published',
  );
}

class AvailabilityResult {
  final RoomType roomType;
  final int availableRooms;
  final int totalRooms;
  final double pricePerNight;
  final int nights;
  final double subtotal;
  final double discount;
  final double total;
  final String currency;
  final Map<String, dynamic>? appliedOffer;
  AvailabilityResult({required this.roomType, required this.availableRooms, required this.totalRooms, required this.pricePerNight, required this.nights, required this.subtotal, required this.discount, required this.total, required this.currency, this.appliedOffer});
  factory AvailabilityResult.fromJson(Map<String, dynamic> j) => AvailabilityResult(
    roomType: RoomType.fromJson(j['roomType']),
    availableRooms: j['availableRooms'] ?? 0, totalRooms: j['totalRooms'] ?? 0,
    pricePerNight: (j['pricePerNight'] as num?)?.toDouble() ?? 0,
    nights: j['nights'] ?? 1,
    subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0,
    discount: (j['discount'] as num?)?.toDouble() ?? 0,
    total: (j['total'] as num?)?.toDouble() ?? 0,
    currency: j['currency'] ?? 'YER',
    appliedOffer: j['appliedOffer'] as Map<String, dynamic>?,
  );
  bool get hasOffer => appliedOffer != null;
}

class Service {
  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double price;
  final String category;
  final String? imageUrl;
  final String status;
  Service({required this.id, required this.slug, required this.nameAr, required this.nameEn, this.descriptionAr, this.descriptionEn, required this.price, required this.category, this.imageUrl, required this.status});
  factory Service.fromJson(Map<String, dynamic> j) => Service(
    id: j['id'], slug: j['slug'], nameAr: j['nameAr'], nameEn: j['nameEn'],
    descriptionAr: j['descriptionAr'], descriptionEn: j['descriptionEn'],
    price: (j['price'] as num?)?.toDouble() ?? 0, category: j['category'] ?? 'general',
    imageUrl: j['imageUrl'], status: j['status'] ?? 'published',
  );
}

class Offer {
  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String? imageUrl;
  final DateTime startsAt;
  final DateTime endsAt;
  final String discountType;
  final double discountValue;
  final String status;
  Offer({required this.id, required this.slug, required this.nameAr, required this.nameEn, required this.descriptionAr, required this.descriptionEn, this.imageUrl, required this.startsAt, required this.endsAt, required this.discountType, required this.discountValue, required this.status});
  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
    id: j['id'], slug: j['slug'], nameAr: j['nameAr'], nameEn: j['nameEn'],
    descriptionAr: j['descriptionAr'] ?? '', descriptionEn: j['descriptionEn'] ?? '',
    imageUrl: j['imageUrl'], startsAt: DateTime.parse(j['startsAt']), endsAt: DateTime.parse(j['endsAt']),
    discountType: j['discountType'] ?? 'percentage', discountValue: (j['discountValue'] as num?)?.toDouble() ?? 0,
    status: j['status'] ?? 'published',
  );
}

class ContentSection {
  final String key;
  final String titleAr;
  final String titleEn;
  final bool visible;
  final int sortOrder;
  final Map<String, dynamic> config;
  ContentSection({required this.key, required this.titleAr, required this.titleEn, required this.visible, required this.sortOrder, required this.config});
  factory ContentSection.fromJson(Map<String, dynamic> j) => ContentSection(
    key: j['key'], titleAr: j['titleAr'], titleEn: j['titleEn'],
    visible: j['visible'] ?? true, sortOrder: j['sortOrder'] ?? 0,
    config: j['config'] is Map ? Map<String, dynamic>.from(j['config']) : {},
  );
}

class BookingRequest {
  final String reference;
  final String status;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final int children;
  final String guestName;
  final String guestPhone;
  final String? message;
  final String channel;
  final DateTime createdAt;
  final RoomType? roomType;
  final Reservation? reservation;
  BookingRequest({required this.reference, required this.status, required this.checkIn, required this.checkOut, required this.nights, required this.adults, required this.children, required this.guestName, required this.guestPhone, this.message, required this.channel, required this.createdAt, this.roomType, this.reservation});
  factory BookingRequest.fromJson(Map<String, dynamic> j) {
    final rt = j['roomType'];
    final res = j['reservation'];
    return BookingRequest(
      reference: j['reference'], status: j['status'],
      checkIn: DateTime.parse(j['checkIn']), checkOut: DateTime.parse(j['checkOut']),
      nights: j['nights'] ?? 1, adults: j['adults'] ?? 1, children: j['children'] ?? 0,
      guestName: j['guestName'], guestPhone: j['guestPhone'], message: j['message'],
      channel: j['channel'] ?? 'app', createdAt: DateTime.parse(j['createdAt']),
      roomType: rt != null ? RoomType.fromJson(rt) : null,
      reservation: res != null ? Reservation.fromJson(res) : null,
    );
  }
}

class Reservation {
  final String? confirmationNo;
  final String? bookingStatus;
  final String? paymentStatus;
  final double? total;
  final double? paid;
  Reservation({this.confirmationNo, this.bookingStatus, this.paymentStatus, this.total, this.paid});
  factory Reservation.fromJson(Map<String, dynamic> j) => Reservation(
    confirmationNo: j['confirmationNo'], bookingStatus: j['bookingStatus'],
    paymentStatus: j['paymentStatus'],
    total: (j['total'] as num?)?.toDouble(), paid: (j['paid'] as num?)?.toDouble(),
  );
}

class GalleryItem {
  final String id;
  final String url;
  final String? altAr;
  GalleryItem({required this.id, required this.url, this.altAr});
  factory GalleryItem.fromJson(Map<String, dynamic> j) => GalleryItem(id: j['id'], url: j['url'], altAr: j['altAr']);
}

class Review {
  final String id;
  final int rating;
  final String? titleAr;
  final String bodyAr;
  final String guestName;
  final DateTime createdAt;
  Review({required this.id, required this.rating, this.titleAr, required this.bodyAr, required this.guestName, required this.createdAt});
  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'], rating: j['rating'], titleAr: j['titleAr'], bodyAr: j['bodyAr'],
    guestName: j['guestName'] ?? 'ضيف', createdAt: DateTime.parse(j['createdAt']),
  );
}

class Faq {
  final String questionAr;
  final String answerAr;
  Faq({required this.questionAr, required this.answerAr});
  factory Faq.fromJson(Map<String, dynamic> j) => Faq(questionAr: j['questionAr'], answerAr: j['answerAr']);
}

class Policy {
  final String key;
  final String titleAr;
  final String bodyAr;
  Policy({required this.key, required this.titleAr, required this.bodyAr});
  factory Policy.fromJson(Map<String, dynamic> j) => Policy(key: j['key'], titleAr: j['titleAr'], bodyAr: j['bodyAr']);
}

// ── Admin models ──
class AdminUser {
  final String id;
  final String? email;
  final String name;
  final List<String> roles;
  final List<String> roleNames;
  AdminUser({required this.id, this.email, required this.name, required this.roles, required this.roleNames});
  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['id'], email: j['email'], name: j['name'],
    roles: j['roles'] != null ? List<String>.from(j['roles']) : [],
    roleNames: j['roleNames'] != null ? List<String>.from(j['roleNames']) : [],
  );
}

class AdminReservation {
  final String id;
  final String confirmationNo;
  final String guestName;
  final String guestPhone;
  final String? guestWhatsapp;
  final String roomType;
  final String? roomNumber;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final int children;
  final double total;
  final double paid;
  final double remaining;
  final String currency;
  final String paymentStatus;
  final String bookingStatus;
  final String source;
  final DateTime createdAt;
  final String? createdBy;
  AdminReservation({required this.id, required this.confirmationNo, required this.guestName, required this.guestPhone, this.guestWhatsapp, required this.roomType, this.roomNumber, required this.checkIn, required this.checkOut, required this.nights, required this.adults, required this.children, required this.total, required this.paid, required this.remaining, required this.currency, required this.paymentStatus, required this.bookingStatus, required this.source, required this.createdAt, this.createdBy});
  factory AdminReservation.fromJson(Map<String, dynamic> j) => AdminReservation(
    id: j['id'], confirmationNo: j['confirmationNo'], guestName: j['guestName'], guestPhone: j['guestPhone'],
    guestWhatsapp: j['guestWhatsapp'], roomType: j['roomType'], roomNumber: j['roomNumber'],
    checkIn: DateTime.parse(j['checkIn']), checkOut: DateTime.parse(j['checkOut']),
    nights: j['nights'], adults: j['adults'], children: j['children'],
    total: (j['total'] as num?)?.toDouble() ?? 0, paid: (j['paid'] as num?)?.toDouble() ?? 0,
    remaining: (j['remaining'] as num?)?.toDouble() ?? 0, currency: j['currency'] ?? 'YER',
    paymentStatus: j['paymentStatus'], bookingStatus: j['bookingStatus'], source: j['source'],
    createdAt: DateTime.parse(j['createdAt']), createdBy: j['createdBy'],
  );
}

class AdminRoom {
  final String id;
  final String number;
  final int? floor;
  final String status;
  final String? notes;
  final Map<String, dynamic> roomType;
  final bool hasPendingTask;
  AdminRoom({required this.id, required this.number, this.floor, required this.status, this.notes, required this.roomType, required this.hasPendingTask});
  factory AdminRoom.fromJson(Map<String, dynamic> j) => AdminRoom(
    id: j['id'], number: j['number'], floor: j['floor'], status: j['status'], notes: j['notes'],
    roomType: Map<String, dynamic>.from(j['roomType']), hasPendingTask: j['hasPendingTask'] ?? false,
  );
}

class AuditLog {
  final String id;
  final String actor;
  final String action;
  final String entity;
  final String entityId;
  final String? oldValue;
  final String? newValue;
  final String? reason;
  final DateTime createdAt;
  AuditLog({required this.id, required this.actor, required this.action, required this.entity, required this.entityId, this.oldValue, this.newValue, this.reason, required this.createdAt});
  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
    id: j['id'], actor: j['actor'], action: j['action'], entity: j['entity'], entityId: j['entityId'],
    oldValue: j['oldValue'], newValue: j['newValue'], reason: j['reason'], createdAt: DateTime.parse(j['createdAt']),
  );
}

class ServiceRequest {
  final String? id;
  final String? reference;
  final String status;
  final String priority;
  final String category;
  final String descriptionAr;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? guest;
  final Map<String, dynamic>? room;
  final Map<String, dynamic>? service;
  final String? assignedTo;
  ServiceRequest({this.id, this.reference, required this.status, required this.priority, required this.category, required this.descriptionAr, this.createdAt, this.completedAt, this.guest, this.room, this.service, this.assignedTo});
  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
    id: j['id'], reference: j['reference'], status: j['status'], priority: j['priority'],
    category: j['category'], descriptionAr: j['descriptionAr'] ?? '',
    createdAt: j['createdAt'] != null ? DateTime.parse(j['createdAt']) : null,
    completedAt: j['completedAt'] != null ? DateTime.parse(j['completedAt']) : null,
    guest: j['guest'] != null ? Map<String, dynamic>.from(j['guest']) : null,
    room: j['room'] != null ? Map<String, dynamic>.from(j['room']) : null,
    service: j['service'] != null ? Map<String, dynamic>.from(j['service']) : null,
    assignedTo: j['assignedTo'],
  );
}

class DashboardData {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> attention;
  final List<AuditLog> recentActivity;
  final Map<String, dynamic> user;
  DashboardData({required this.stats, required this.attention, required this.recentActivity, required this.user});
  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    stats: Map<String, dynamic>.from(j['stats'] ?? {}),
    attention: j['attention'] != null ? List<Map<String, dynamic>>.from((j['attention'] as List).map((e) => Map<String, dynamic>.from(e))) : [],
    recentActivity: j['recentActivity'] != null ? List<AuditLog>.from((j['recentActivity'] as List).map((e) => AuditLog.fromJson(e))) : [],
    user: Map<String, dynamic>.from(j['user'] ?? {}),
  );
}

class HomeData {
  final HotelSettings settings;
  final List<ContentSection> sections;
  final List<RoomType> roomTypes;
  final List<Offer> offers;
  final List<Service> services;
  final List<GalleryItem> gallery;
  final List<Review> reviews;
  final Map<String, bool> flags;
  HomeData({required this.settings, required this.sections, required this.roomTypes, required this.offers, required this.services, required this.gallery, required this.reviews, required this.flags});
  factory HomeData.fromJson(Map<String, dynamic> j) => HomeData(
    settings: HotelSettings.fromJson(Map<String, dynamic>.from(j['settings'] ?? {})),
    sections: j['sections'] != null ? List<ContentSection>.from((j['sections'] as List).map((e) => ContentSection.fromJson(e))) : [],
    roomTypes: j['roomTypes'] != null ? List<RoomType>.from((j['roomTypes'] as List).map((e) => RoomType.fromJson(e))) : [],
    offers: j['offers'] != null ? List<Offer>.from((j['offers'] as List).map((e) => Offer.fromJson(e))) : [],
    services: j['services'] != null ? List<Service>.from((j['services'] as List).map((e) => Service.fromJson(e))) : [],
    gallery: j['gallery'] != null ? List<GalleryItem>.from((j['gallery'] as List).map((e) => GalleryItem.fromJson(e))) : [],
    reviews: j['reviews'] != null ? List<Review>.from((j['reviews'] as List).map((e) => Review.fromJson(e))) : [],
    flags: j['flags'] != null ? Map<String, bool>.from((j['flags'] as Map).map((k, v) => MapEntry(k, v as bool))) : {},
  );
  ContentSection? section(String key) {
    final list = sections.where((s) => s.key == key && s.visible);
    return list.isEmpty ? null : list.first;
  }
}
