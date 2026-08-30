import 'package:flutter/material.dart';

import 'package:hotel_platform/core/constants.dart';

/// Central domain model (see PLAN §5). One source of truth.
/// Reservation != Stay (see PLAN §6). Guest actions link to active Stay.

class HotelInfo {
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final String phone;
  final String email;
  final String address;
  final String addressAr;
  final String whatsapp;
  final List<String> amenities;
  final List<String> galleryColors; // gradient seeds used as placeholders
  final String checkInTime;
  final String checkOutTime;
  final List<String> policies;
  final List<String> policiesAr;

  const HotelInfo({
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.phone,
    required this.email,
    required this.address,
    required this.addressAr,
    required this.whatsapp,
    required this.amenities,
    required this.galleryColors,
    required this.checkInTime,
    required this.checkOutTime,
    required this.policies,
    required this.policiesAr,
  });
}

class RoomType {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final String bedConfig;
  final int maxOccupancy;
  final int defaultAdults;
  final double sizeSqm;
  final double basePrice;
  final List<String> amenities;
  final int inventoryCount; // total rooms of this type
  final List<Color> palette; // 2-color gradient for placeholder imagery
  final IconData icon;

  const RoomType({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.bedConfig,
    required this.maxOccupancy,
    required this.defaultAdults,
    required this.sizeSqm,
    required this.basePrice,
    required this.amenities,
    required this.inventoryCount,
    required this.palette,
    required this.icon,
  });
}

class Room {
  final String id;
  final String number;
  final String roomTypeId;
  final int floor;
  final int capacity;
  bool active;
  RoomStatus status;
  String? currentStayId;

  Room({
    required this.id,
    required this.number,
    required this.roomTypeId,
    required this.floor,
    required this.capacity,
    this.active = true,
    this.status = RoomStatus.available,
    this.currentStayId,
  });
}

class Guest {
  final String id;
  String name;
  String email;
  String phone;
  String? nationality;
  String? idNumber; // passport/national id used at verify
  final DateTime createdAt;

  Guest({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.nationality,
    this.idNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class PriceSnapshot {
  final double nightlyRate;
  final int nights;
  final double subtotal;
  final double taxRate;
  final double tax;
  final double total;

  const PriceSnapshot({
    required this.nightlyRate,
    required this.nights,
    required this.subtotal,
    required this.taxRate,
    required this.tax,
    required this.total,
  });
}

class Reservation {
  final String id;
  final String guestId;
  final String roomTypeId;
  DateTime checkIn;
  DateTime checkOut;
  int adults;
  int children;
  ReservationStatus status;
  final PriceSnapshot price;
  final PaymentMethod paymentMethod;
  double amountPaid;
  final DateTime createdAt;
  String? stayId; // set after check-in
  String? assignedRoomId;
  String? cancellationReason;

  Reservation({
    required this.id,
    required this.guestId,
    required this.roomTypeId,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.status,
    required this.price,
    required this.paymentMethod,
    required this.amountPaid,
    required this.createdAt,
    this.stayId,
    this.assignedRoomId,
    this.cancellationReason,
  });
}

enum PaymentMethod { payAtHotel, creditCard, cash }

class GuestAccess {
  final String id;
  final String stayId;
  final String guestId;
  final String code; // 6-digit activation code
  final DateTime issuedAt;
  DateTime? expiresAt;
  bool active;

  GuestAccess({
    required this.id,
    required this.stayId,
    required this.guestId,
    required this.code,
    required this.issuedAt,
    this.expiresAt,
    this.active = true,
  });
}

class Stay {
  final String id;
  final String reservationId;
  final String guestId;
  String roomId;
  DateTime checkIn;
  DateTime checkOut; // expected/actual checkout
  StayStatus status;
  final DateTime createdAt;
  String? guestAccessId;
  List<RoomTransfer> transfers;
  String? notes;

  Stay({
    required this.id,
    required this.reservationId,
    required this.guestId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.createdAt,
    this.guestAccessId,
    List<RoomTransfer>? transfers,
    this.notes,
  }) : transfers = transfers ?? [];
}

class RoomTransfer {
  final DateTime at;
  final String fromRoomId;
  final String toRoomId;
  final String reason;
  final String approvedBy;

  RoomTransfer({
    required this.at,
    required this.fromRoomId,
    required this.toRoomId,
    required this.reason,
    required this.approvedBy,
  });
}

class Service {
  final String id;
  final ServiceCategory category;
  final String name;
  final String nameAr;
  final String? description;
  final double? price;
  final bool active;

  const Service({
    required this.id,
    required this.category,
    required this.name,
    required this.nameAr,
    this.description,
    this.price,
    this.active = true,
  });
}

class GuestRequest {
  final String id;
  final String stayId;
  final String guestId;
  final String roomId;
  final String? serviceId;
  ServiceCategory category;
  String title;
  String description;
  RequestPriority priority;
  RequestStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  String? assignedTo;
  List<RequestMessage> messages;
  String? relatedChargeId;

  GuestRequest({
    required this.id,
    required this.stayId,
    required this.guestId,
    required this.roomId,
    this.serviceId,
    required this.category,
    required this.title,
    required this.description,
    this.priority = RequestPriority.normal,
    this.status = RequestStatus.newRequest,
    required this.createdAt,
    this.completedAt,
    this.assignedTo,
    List<RequestMessage>? messages,
    this.relatedChargeId,
  }) : messages = messages ?? [];
}

class RequestMessage {
  final String id;
  final String authorId; // guest id or staff user id
  final bool fromStaff;
  final String text;
  final DateTime at;

  RequestMessage({
    required this.id,
    required this.authorId,
    required this.fromStaff,
    required this.text,
    required this.at,
  });
}

class Charge {
  final String id;
  final String stayId;
  final String description;
  final String category;
  final int quantity;
  final double unitPrice;
  final double gross;
  final double discount;
  final double net;
  final double tax;
  final DateTime at;
  final String source; // 'room' | 'service' | 'manual'
  final String createdBy;

  Charge({
    required this.id,
    required this.stayId,
    required this.description,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.gross,
    required this.discount,
    required this.net,
    required this.tax,
    required this.at,
    required this.source,
    required this.createdBy,
  });
}

class Payment {
  final String id;
  final String stayId;
  final PaymentMethod method;
  final double amount;
  final DateTime at;
  final String reference;
  final String recordedBy;

  Payment({
    required this.id,
    required this.stayId,
    required this.method,
    required this.amount,
    required this.at,
    required this.reference,
    required this.recordedBy,
  });
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime at;
  final String? scope; // 'guest' | 'reception' | 'admin'
  final String? guestId;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.scope,
    this.guestId,
    this.read = false,
  });
}

class Conversation {
  final String id;
  final String stayId;
  final String guestId;
  final List<RequestMessage> messages;
  String status; // OPEN | WAITING | RESOLVED | CLOSED

  Conversation({
    required this.id,
    required this.stayId,
    required this.guestId,
    List<RequestMessage>? messages,
    this.status = 'OPEN',
  }) : messages = messages ?? [];
}

class AuditEntry {
  final String id;
  final DateTime at;
  final String actor;
  final String action;
  final String target;
  final String? detail;

  AuditEntry({
    required this.id,
    required this.at,
    required this.actor,
    required this.action,
    required this.target,
    this.detail,
  });
}

class AppUser {
  final String id;
  final String name;
  final String role; // 'admin' | 'reception'
  final String username;
  final bool active;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.username,
    this.active = true,
  });
}

class ExtensionRequest {
  final String id;
  final String stayId;
  final String guestId;
  final DateTime currentCheckout;
  final DateTime requestedCheckout;
  final double additionalCost;
  final String? reason;
  final DateTime createdAt;
  bool approved;
  final List<RequestMessage> messages;

  ExtensionRequest({
    required this.id,
    required this.stayId,
    required this.guestId,
    required this.currentCheckout,
    required this.requestedCheckout,
    required this.additionalCost,
    this.reason,
    required this.createdAt,
    this.approved = false,
    List<RequestMessage>? messages,
  }) : messages = messages ?? [];
}
