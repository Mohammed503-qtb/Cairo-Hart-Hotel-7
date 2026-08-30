import 'package:flutter/material.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/data/models.dart';

/// Seed / master data for the hotel platform (PLAN §2.1, §15).
class Seed {
  Seed._();

  static const HotelInfo hotel = HotelInfo(
    name: Brand.hotelName,
    nameAr: Brand.hotelNameAr,
    description:
        'A seaside grand hotel blending timeless hospitality with modern comfort. '
        'Spacious rooms, a rooftop infinity pool, and a reception that remembers you.',
    descriptionAr:
        'فندق جراند ساحلي يمزج بين الضيافة الخالدة والراحة العصرية. غرف فسيحة، '
        'مسبح لا نهائي على السطح، واستقبال لا ينساك.',
    phone: Brand.hotelPhone,
    email: Brand.hotelEmail,
    address: Brand.hotelAddress,
    addressAr: Brand.hotelAddressAr,
    whatsapp: Brand.hotelWhatsapp,
    amenities: [
      'Rooftop infinity pool',
      '24h fitness center',
      'Free high-speed Wi-Fi',
      'Concierge',
      'Valet parking',
      'Business center',
      'Spa & sauna',
      'Restaurant & lounge',
      'Airport shuttle',
      'Meeting rooms',
    ],
    galleryColors: ['amber', 'teal', 'rose', 'sand', 'emerald', 'plum'],
    checkInTime: '14:00',
    checkOutTime: '12:00',
    policies: [
      'Check-in from 14:00, check-out by 12:00.',
      'Free cancellation up to 48 hours before arrival.',
      'No-show forfeits the first night.',
      'A valid ID is required at check-in.',
      'Pets are not allowed.',
      'Smoking is not allowed inside rooms.',
    ],
    policiesAr: [
      'تسجيل الدخول من الساعة 14:00، والمغادرة حتى 12:00.',
      'إلغاء مجاني حتى 48 ساعة قبل الوصول.',
      'عدم الحضور يُفقد رسوم الليلة الأولى.',
      'مطلوب هوية سارية عند تسجيل الدخول.',
      'غير مسموح بالحيوانات الأليفة.',
      'غير مسموح بالتدخين داخل الغرف.',
    ],
  );

  static const List<RoomType> roomTypes = [
    RoomType(
      id: 'standard',
      name: 'Standard Twin',
      nameAr: 'غرفة قياسية توأم',
      description: 'A bright, comfortable room with two single beds, perfect for short city stays.',
      descriptionAr: 'غرفة مشرقة ومريحة بسريرين فرديين، مثالية للإقامات القصيرة في المدينة.',
      bedConfig: '2 single beds',
      maxOccupancy: 2,
      defaultAdults: 1,
      sizeSqm: 28,
      basePrice: 520,
      amenities: [
        'Free Wi-Fi',
        'Smart TV',
        'Work desk',
        'En-suite bathroom',
        'Tea & coffee',
      ],
      inventoryCount: 8,
      palette: [Color(0xFF6A8CAF), Color(0xFF9CB4D1)],
      icon: Icons.bed_outlined,
    ),
    RoomType(
      id: 'deluxe',
      name: 'Deluxe Double',
      nameAr: 'غرفة ديلوكس مزدوجة',
      description:
          'A spacious king-bed room with a seating area and partial sea view.',
      descriptionAr:
          'غرفة فسيحة بسرير كينغ ومنطقة جلوس وإطلالة جزئية على البحر.',
      bedConfig: '1 king bed',
      maxOccupancy: 3,
      defaultAdults: 2,
      sizeSqm: 38,
      basePrice: 780,
      amenities: [
        'Free Wi-Fi',
        '55" Smart TV',
        'Minibar',
        'Sea view',
        'Bathrobe',
        'Nespresso',
      ],
      inventoryCount: 6,
      palette: [Color(0xFFC9A24B), Color(0xFFE6C878)],
      icon: Icons.king_bed_outlined,
    ),
    RoomType(
      id: 'suite',
      name: 'Grand Suite',
      nameAr: 'جناح جراند',
      description: 'An elegant one-bedroom suite with a living room, panoramic sea view, and butler call.',
      descriptionAr:
          'جناح أنيق بغرفة نوم وصالة وإطلالة بانورامية على البحر وخدمة المدبر.',
      bedConfig: '1 king bed + sofa bed',
      maxOccupancy: 4,
      defaultAdults: 2,
      sizeSqm: 65,
      basePrice: 1450,
      amenities: [
        'Free Wi-Fi',
        'Living room',
        'Panoramic sea view',
        'Minibar',
        'Butler call',
        'Jacuzzi',
        'Espresso',
      ],
      inventoryCount: 4,
      palette: [Color(0xFF7D5A3C), Color(0xFFB5895A)],
      icon: Icons.apartment,
    ),
  ];

  static const List<Service> services = [
    Service(
      id: 'svc-clean',
      category: ServiceCategory.housekeeping,
      name: 'Clean my room',
      nameAr: 'تنظيف غرفتي',
      description: 'Full room cleaning',
    ),
    Service(
      id: 'svc-towels',
      category: ServiceCategory.housekeeping,
      name: 'Extra towels',
      nameAr: 'مناشف إضافية',
      price: 0,
    ),
    Service(
      id: 'svc-linen',
      category: ServiceCategory.housekeeping,
      name: 'Fresh linens',
      nameAr: 'أغطية جديدة',
    ),
    Service(
      id: 'svc-toiletries',
      category: ServiceCategory.housekeeping,
      name: 'Toiletries refill',
      nameAr: 'إعادة تعبئة المستلزمات',
    ),
    Service(
      id: 'svc-ac',
      category: ServiceCategory.maintenance,
      name: 'Air conditioning issue',
      nameAr: 'مشكلة في التكييف',
    ),
    Service(
      id: 'svc-water',
      category: ServiceCategory.maintenance,
      name: 'Water / plumbing issue',
      nameAr: 'مشكلة في السباكة',
    ),
    Service(
      id: 'svc-tv',
      category: ServiceCategory.maintenance,
      name: 'TV not working',
      nameAr: 'التلفاز لا يعمل',
    ),
    Service(
      id: 'svc-wifi',
      category: ServiceCategory.maintenance,
      name: 'Wi-Fi issue',
      nameAr: 'مشكلة في الإنترنت',
    ),
    Service(
      id: 'svc-pillow',
      category: ServiceCategory.guestServices,
      name: 'Extra pillow',
      nameAr: 'وسادة إضافية',
    ),
    Service(
      id: 'svc-blanket',
      category: ServiceCategory.guestServices,
      name: 'Extra blanket',
      nameAr: 'بطانية إضافية',
    ),
    Service(
      id: 'svc-latecheckin',
      category: ServiceCategory.reception,
      name: 'Late check-in note',
      nameAr: 'تنبيه وصول متأخر',
    ),
    Service(
      id: 'svc-extension',
      category: ServiceCategory.reception,
      name: 'Extension request',
      nameAr: 'طلب تمديد',
    ),
    Service(
      id: 'svc-roomchange',
      category: ServiceCategory.reception,
      name: 'Room change',
      nameAr: 'تغيير الغرفة',
    ),
  ];

  static const List<AppUser> users = [
    AppUser(id: 'u1', name: 'Omar (Admin)', role: 'admin', username: 'admin'),
    AppUser(
      id: 'u2',
      name: 'Layla (Reception)',
      role: 'reception',
      username: 'reception',
    ),
  ];

  /// Build the physical room inventory from room types.
  /// Numbering: floor-by-type, e.g. Standard 101..108, Deluxe 201..206, Suite 301..304.
  static List<Room> buildRooms(List<RoomType> types) {
    final list = <Room>[];
    for (final t in types) {
      final startFloor = {'standard': 1, 'deluxe': 2, 'suite': 3}[t.id]!;
      for (int i = 0; i < t.inventoryCount; i++) {
        final number = '$startFloor${(i + 1).toString().padLeft(2, '0')}';
        list.add(
          Room(
            id: 'room-${t.id}-$i',
            number: number,
            roomTypeId: t.id,
            floor: startFloor,
            capacity: t.maxOccupancy,
            status: RoomStatus.available,
          ),
        );
      }
    }
    return list;
  }
}
