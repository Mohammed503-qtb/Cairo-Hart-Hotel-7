import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/features/admin/admin_shell.dart';
import 'package:hotel_platform/features/admin/audit_log_screen.dart';
import 'package:hotel_platform/features/admin/rooms_admin_screen.dart';
import 'package:hotel_platform/features/admin/staff_codes_screen.dart';
import 'package:hotel_platform/features/guest/checkout_request_screen.dart';
import 'package:hotel_platform/features/guest/extend_stay_screen.dart';
import 'package:hotel_platform/features/guest/guest_shell.dart';
import 'package:hotel_platform/features/guest/guest_bill_screen.dart';
import 'package:hotel_platform/features/guest/notifications_screen.dart';
import 'package:hotel_platform/features/guest/reception_chat_screen.dart';
import 'package:hotel_platform/features/guest/request_detail_screen.dart';
import 'package:hotel_platform/features/guest/room_change_screen.dart';
import 'package:hotel_platform/features/guest/services_screen.dart';
import 'package:hotel_platform/features/reception/check_out_screen.dart';
import 'package:hotel_platform/features/reception/reception_shell.dart';
import 'package:hotel_platform/features/reception/request_manage_screen.dart';
import 'package:hotel_platform/features/reception/reservation_detail_screen.dart';
import 'package:hotel_platform/features/shell/login_screen.dart';
import 'package:hotel_platform/features/website/about_page.dart';
import 'package:hotel_platform/features/website/facilities_page.dart';
import 'package:hotel_platform/features/website/location_page.dart';
import 'package:hotel_platform/features/website/manage_booking_screen.dart';
import 'package:hotel_platform/features/website/booking_flow_screen.dart';
import 'package:hotel_platform/features/website/confirmation_screen.dart';
import 'package:hotel_platform/features/website/room_detail_screen.dart';
import 'package:hotel_platform/features/website/website_shell.dart';

/// The platform is selected at build time. On web (kIsWeb) the binary is a
/// pure public website: home, rooms, booking engine, confirmation, manage-
/// booking lookup. On native (phone/desktop) the binary is a pure mobile app:
/// code-based login → guest / reception / admin persona. (PLAN_WEBSITE §0,
/// PLAN_MOBILE-APK §0, §2.1.)
GoRouter buildRouter(AppState app) {
  return GoRouter(
    initialLocation: kIsWeb ? '/' : '/login',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final a = Provider.of<AppState>(context, listen: false);
      if (kIsWeb) {
        // WEB: public website only. No login, no guest, no reception, no admin.
        // All website routes are open.
        return null;
      }
      // NATIVE APP: code-gated. Public website routes are not present.
      if (path == '/login') return null;
      if (path.startsWith('/guest') && !a.isGuestSession) return '/login';
      if (path.startsWith('/reception') && !a.isStaffSession) return '/login';
      if (path.startsWith('/admin') && !a.isStaffSession) return '/login';
      return null;
    },
    routes: kIsWeb ? _webRoutes : _appRoutes,
  );
}

// =====================================================================
//  WEB ROUTES — the public website (PLAN_WEBSITE).
//  Open to everyone. No login. Booking creates a reservation; the guest
//  later retrieves it via Manage-Booking (reference + verification).
// =====================================================================
final _webRoutes = <RouteBase>[
  ShellRoute(
    builder: (context, state, child) => WebsiteShell(child: child),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WebsiteHomePage()),
      GoRoute(
        path: '/rooms',
        builder: (context, state) => const WebsiteRoomsPage(),
      ),
      GoRoute(
        path: '/rooms/:id',
        builder: (context, state) =>
            RoomDetailScreen(roomTypeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/facilities',
        builder: (context, state) => const FacilitiesPage(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const WebsiteGalleryPage(),
      ),
      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationPage(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const WebsiteContactPage(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookingFlowScreen(
            roomTypeId: extra?['roomTypeId'] as String?,
            initialCheckIn: extra?['checkIn'] as DateTime?,
            initialCheckOut: extra?['checkOut'] as DateTime?,
            adults: extra?['adults'] as int? ?? 2,
          );
        },
      ),
      GoRoute(
        path: '/booking/confirmation/:resId',
        builder: (context, state) =>
            ConfirmationScreen(reservationId: state.pathParameters['resId']!),
      ),
      GoRoute(
        path: '/manage-booking',
        builder: (context, state) => const ManageBookingScreen(),
      ),
      GoRoute(
        path: '/manage-booking/:resId',
        builder: (context, state) =>
            ManageBookingScreen(reservationId: state.pathParameters['resId']),
      ),
    ],
  ),
];

// =====================================================================
//  APP ROUTES — the mobile application (PLAN_MOBILE-APK).
//  Code-gated. /login validates the code prefix (H/R/A) and routes to the
//  matching persona dashboard. No public browsing on the app.
// =====================================================================
final _appRoutes = <RouteBase>[
  GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  // Demo deep-links (auto-login via code) for verification/showcase.
  GoRoute(
    path: '/demo/guest',
    builder: (context, state) {
      final a = Provider.of<AppState>(context, listen: false);
      a.loginWithCodeSilent('H834729X7');
      return const GuestShell();
    },
  ),
  GoRoute(
    path: '/demo/reception',
    builder: (context, state) {
      final a = Provider.of<AppState>(context, listen: false);
      a.loginWithCodeSilent('R492671M3');
      return const ReceptionShell();
    },
  ),
  GoRoute(
    path: '/demo/admin',
    builder: (context, state) {
      final a = Provider.of<AppState>(context, listen: false);
      a.loginWithCodeSilent('A371849L9');
      return const AdminShell();
    },
  ),
  // ---- Guest app (mobile-first) ----
  GoRoute(path: '/guest', builder: (context, state) => const GuestShell()),
  GoRoute(
    path: '/guest/services',
    builder: (context, state) => const ServicesScreen(),
  ),
  GoRoute(
    path: '/guest/request/:id',
    builder: (context, state) =>
        RequestDetailScreen(requestId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/guest/bill',
    builder: (context, state) => const GuestBillScreen(),
  ),
  GoRoute(
    path: '/guest/extend',
    builder: (context, state) => const ExtendStayScreen(),
  ),
  GoRoute(
    path: '/guest/roomchange',
    builder: (context, state) => const RoomChangeScreen(),
  ),
  GoRoute(
    path: '/guest/checkout',
    builder: (context, state) => const CheckoutRequestScreen(),
  ),
  GoRoute(
    path: '/guest/chat',
    builder: (context, state) => const ReceptionChatScreen(),
  ),
  GoRoute(
    path: '/guest/notifications',
    builder: (context, state) => const NotificationsScreen(),
  ),
  // ---- Reception / PMS ----
  GoRoute(
    path: '/reception',
    builder: (context, state) => const ReceptionShell(),
  ),
  GoRoute(
    path: '/reception/reservation/:id',
    builder: (context, state) =>
        ReservationDetailScreen(reservationId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/reception/request/:id',
    builder: (context, state) =>
        RequestManageScreen(requestId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/reception/checkout/:stayId',
    builder: (context, state) =>
        CheckOutScreen(stayId: state.pathParameters['stayId']!),
  ),
  // ---- Admin ----
  GoRoute(path: '/admin', builder: (context, state) => const AdminShell()),
  GoRoute(
    path: '/admin/rooms',
    builder: (context, state) => const RoomsAdminScreen(),
  ),
  GoRoute(
    path: '/admin/staff-codes',
    builder: (context, state) => const StaffCodesScreen(),
  ),
  GoRoute(
    path: '/admin/audit',
    builder: (context, state) => const AuditLogScreen(),
  ),
];
