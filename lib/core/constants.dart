import 'package:flutter/material.dart';

/// Hotel brand constants and domain enumerations.
class Brand {
  Brand._();

  static const String hotelName = 'Lumière Grand Hotel';
  static const String hotelNameAr = 'فندق لوميير جراند';
  static const String hotelTagline = 'Stay. Service. Serenity.';
  static const String hotelTaglineAr = 'إقامة. خدمة. هدوء.';
  static const String hotelPhone = '+971 4 555 0190';
  static const String hotelEmail = 'reservations@lumieregrand.com';
  static const String hotelAddress = 'Seaside Boulevard, Jaddah Heights, UAE';
  static const String hotelAddressAr = 'كورنيش البحر، أبراج جدة، الإمارات';
  static const String hotelWhatsapp = '971455501920';

  static const double defaultTaxRate = 0.05; // 5% service tax
  static const String currencyCode = 'AED';
  static const String currencySymbol = 'AED';
}

enum ReservationStatus {
  draft,
  pending,
  confirmed,
  cancelled,
  noShow,
  checkedIn,
  checkedOut,
  completed,
}

enum StayStatus {
  expected,
  checkedIn,
  inHouse,
  extensionPending,
  checkoutPending,
  checkedOut,
  closed,
}

enum RoomStatus {
  available,
  reserved,
  occupied,
  dirty,
  cleaning,
  clean,
  inspected,
  outOfOrder,
  outOfService,
}

enum RequestStatus {
  newRequest,
  acknowledged,
  assigned,
  inProgress,
  waiting,
  completed,
  cancelled,
  rejected,
  reopened,
}

enum RequestPriority { normal, urgent }

enum ServiceCategory {
  housekeeping,
  maintenance,
  guestServices,
  reception,
}

enum AppSpace { website, guest, reception, admin }

enum AppThemeMode { light, dark, system }

extension ReservationStatusX on ReservationStatus {
  String get label {
    switch (this) {
      case ReservationStatus.draft:
        return 'Draft';
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.noShow:
        return 'No-Show';
      case ReservationStatus.checkedIn:
        return 'Checked-In';
      case ReservationStatus.checkedOut:
        return 'Checked-Out';
      case ReservationStatus.completed:
        return 'Completed';
    }
  }

  String get labelAr {
    switch (this) {
      case ReservationStatus.draft:
        return 'مسودة';
      case ReservationStatus.pending:
        return 'قيد الانتظار';
      case ReservationStatus.confirmed:
        return 'مؤكد';
      case ReservationStatus.cancelled:
        return 'ملغى';
      case ReservationStatus.noShow:
        return 'لم يحضر';
      case ReservationStatus.checkedIn:
        return 'تم تسجيل الدخول';
      case ReservationStatus.checkedOut:
        return 'تم تسجيل المغادرة';
      case ReservationStatus.completed:
        return 'مكتمل';
    }
  }
}

extension StayStatusX on StayStatus {
  String get label {
    switch (this) {
      case StayStatus.expected:
        return 'Expected';
      case StayStatus.checkedIn:
        return 'Checked-In';
      case StayStatus.inHouse:
        return 'In-House';
      case StayStatus.extensionPending:
        return 'Extension Pending';
      case StayStatus.checkoutPending:
        return 'Checkout Pending';
      case StayStatus.checkedOut:
        return 'Checked-Out';
      case StayStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case StayStatus.expected:
        return Colors.blueGrey;
      case StayStatus.checkedIn:
      case StayStatus.inHouse:
        return const Color(0xFF2E7D32);
      case StayStatus.extensionPending:
      case StayStatus.checkoutPending:
        return const Color(0xFFEF6C00);
      case StayStatus.checkedOut:
      case StayStatus.closed:
        return const Color(0xFF616161);
    }
  }
}

extension RoomStatusX on RoomStatus {
  String get label {
    switch (this) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.reserved:
        return 'Reserved';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.dirty:
        return 'Dirty';
      case RoomStatus.cleaning:
        return 'Cleaning';
      case RoomStatus.clean:
        return 'Clean';
      case RoomStatus.inspected:
        return 'Inspected';
      case RoomStatus.outOfOrder:
        return 'Out of Order';
      case RoomStatus.outOfService:
        return 'Out of Service';
    }
  }

  Color get color {
    switch (this) {
      case RoomStatus.available:
      case RoomStatus.clean:
      case RoomStatus.inspected:
        return const Color(0xFF2E7D32);
      case RoomStatus.reserved:
        return const Color(0xFF1565C0);
      case RoomStatus.occupied:
        return const Color(0xFFEF6C00);
      case RoomStatus.dirty:
        return const Color(0xFFC62828);
      case RoomStatus.cleaning:
        return const Color(0xFF6A1B9A);
      case RoomStatus.outOfOrder:
      case RoomStatus.outOfService:
        return const Color(0xFF455A64);
    }
  }

  bool get isSellable =>
      this == RoomStatus.available ||
      this == RoomStatus.clean ||
      this == RoomStatus.inspected;
}

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.newRequest:
        return 'New';
      case RequestStatus.acknowledged:
        return 'Acknowledged';
      case RequestStatus.assigned:
        return 'Assigned';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.waiting:
        return 'Waiting';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.reopened:
        return 'Reopened';
    }
  }

  Color get color {
    switch (this) {
      case RequestStatus.newRequest:
        return const Color(0xFF1565C0);
      case RequestStatus.acknowledged:
        return const Color(0xFF00838F);
      case RequestStatus.assigned:
      case RequestStatus.inProgress:
        return const Color(0xFFEF6C00);
      case RequestStatus.waiting:
        return const Color(0xFF6A1B9A);
      case RequestStatus.completed:
        return const Color(0xFF2E7D32);
      case RequestStatus.cancelled:
      case RequestStatus.rejected:
        return const Color(0xFFC62828);
      case RequestStatus.reopened:
        return const Color(0xFFAD1457);
    }
  }
}

extension ServiceCategoryX on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.housekeeping:
        return 'Housekeeping';
      case ServiceCategory.maintenance:
        return 'Maintenance';
      case ServiceCategory.guestServices:
        return 'Guest Services';
      case ServiceCategory.reception:
        return 'Reception';
    }
  }

  String get labelAr {
    switch (this) {
      case ServiceCategory.housekeeping:
        return 'تنظيف الغرف';
      case ServiceCategory.maintenance:
        return 'الصيانة';
      case ServiceCategory.guestServices:
        return 'خدمات النزيل';
      case ServiceCategory.reception:
        return 'الاستقبال';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.housekeeping:
        return Icons.cleaning_services_outlined;
      case ServiceCategory.maintenance:
        return Icons.build_outlined;
      case ServiceCategory.guestServices:
        return Icons.room_service_outlined;
      case ServiceCategory.reception:
        return Icons.support_agent;
    }
  }
}
