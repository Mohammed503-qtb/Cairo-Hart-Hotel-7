import 'package:flutter/material.dart';
import '../features/home/guest_shell.dart';
import '../features/rooms/rooms_screen.dart';
import '../features/rooms/room_detail_screen.dart';
import '../features/booking/booking_flow_screen.dart';
import '../features/bookings/my_bookings_screen.dart';
import '../features/services/services_screen.dart';
import '../features/contact/contact_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/admin/admin_login_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/dashboard_screen.dart';
import '../features/admin/reservations_screen.dart';
import '../features/admin/reservation_detail_screen.dart';
import '../features/admin/rooms_screen.dart';
import '../features/admin/room_types_screen.dart';
import '../features/admin/services_screen.dart';
import '../features/admin/offers_screen.dart';
import '../features/admin/content_screen.dart';
import '../features/admin/service_requests_screen.dart';
import '../features/admin/communication_screen.dart';
import '../features/admin/settings_screen.dart';
import '../features/admin/audit_screen.dart';
import '../features/admin/users_screen.dart';
import '../features/admin/guests_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => const GuestShell(), settings: settings);
      case '/':
      case '/rooms':
        return MaterialPageRoute(builder: (_) => const RoomsScreen(), settings: settings);
      case '/room':
        final id = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => RoomDetailScreen(roomTypeId: id ?? ''), settings: settings);
      case '/booking':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => BookingFlowScreen(args: args ?? {}), settings: settings);
      case '/bookings':
        return MaterialPageRoute(builder: (_) => const MyBookingsScreen(), settings: settings);
      case '/services':
        return MaterialPageRoute(builder: (_) => const ServicesScreen(), settings: settings);
      case '/contact':
        return MaterialPageRoute(builder: (_) => const ContactScreen(), settings: settings);
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen(), settings: settings);
      case '/login':
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen(), settings: settings);
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminShell(), settings: settings);
      case '/admin/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen(), settings: settings);
      case '/admin/reservations':
        return MaterialPageRoute(builder: (_) => const ReservationsScreen(), settings: settings);
      case '/admin/reservation':
        final id = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => ReservationDetailScreen(reservationId: id ?? ''), settings: settings);
      case '/admin/rooms':
        return MaterialPageRoute(builder: (_) => const AdminRoomsScreen(), settings: settings);
      case '/admin/room-types':
        return MaterialPageRoute(builder: (_) => const AdminRoomTypesScreen(), settings: settings);
      case '/admin/services':
        return MaterialPageRoute(builder: (_) => const AdminServicesScreen(), settings: settings);
      case '/admin/offers':
        return MaterialPageRoute(builder: (_) => const AdminOffersScreen(), settings: settings);
      case '/admin/content':
        return MaterialPageRoute(builder: (_) => const ContentScreen(), settings: settings);
      case '/admin/service-requests':
        return MaterialPageRoute(builder: (_) => const AdminServiceRequestsScreen(), settings: settings);
      case '/admin/communication':
        return MaterialPageRoute(builder: (_) => const CommunicationScreen(), settings: settings);
      case '/admin/settings':
        return MaterialPageRoute(builder: (_) => const AdminSettingsScreen(), settings: settings);
      case '/admin/audit':
        return MaterialPageRoute(builder: (_) => const AuditScreen(), settings: settings);
      case '/admin/users':
        return MaterialPageRoute(builder: (_) => const AdminUsersScreen(), settings: settings);
      case '/admin/guests':
        return MaterialPageRoute(builder: (_) => const AdminGuestsScreen(), settings: settings);
      default:
        return MaterialPageRoute(builder: (_) => const GuestShell(), settings: settings);
    }
  }
}
