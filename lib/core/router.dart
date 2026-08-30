import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/features/admin/admin_shell.dart';
import 'package:hotel_platform/features/admin/admin_login_screen.dart';
import 'package:hotel_platform/features/admin/audit_log_screen.dart';
import 'package:hotel_platform/features/admin/rooms_admin_screen.dart';
import 'package:hotel_platform/features/guest/activation_screen.dart';
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
import 'package:hotel_platform/features/reception/reception_login_screen.dart';
import 'package:hotel_platform/features/reception/reception_shell.dart';
import 'package:hotel_platform/features/reception/request_manage_screen.dart';
import 'package:hotel_platform/features/reception/reservation_detail_screen.dart';
import 'package:hotel_platform/features/shell/role_selection_screen.dart';
import 'package:hotel_platform/features/website/booking_flow_screen.dart';
import 'package:hotel_platform/features/website/confirmation_screen.dart';
import 'package:hotel_platform/features/website/room_detail_screen.dart';
import 'package:hotel_platform/features/website/website_shell.dart';

GoRouter buildRouter(AppState app) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final a = Provider.of<AppState>(context, listen: false);
      if (path == '/') return null;
      if (path.startsWith('/guest') &&
          path != '/guest/activate' &&
          !a.isGuestSession) {
        return '/guest/activate';
      }
      if (path.startsWith('/reception') &&
          path != '/reception/login' &&
          !a.isStaffSession) {
        return '/reception/login';
      }
      if (path.startsWith('/admin') &&
          path != '/admin/login' &&
          !a.isStaffSession) {
        return '/admin/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      // Demo deep-links: auto-login and render the role dashboard directly,
      // so the dashboards can be opened via URL for verification/showcases.
      GoRoute(
        path: '/demo/reception',
        builder: (context, state) {
          final a = Provider.of<AppState>(context, listen: false);
          if (!a.isStaffSession) a.loginStaffSilent("reception");
          return const ReceptionShell();
        },
      ),
      GoRoute(
        path: '/demo/admin',
        builder: (context, state) {
          final a = Provider.of<AppState>(context, listen: false);
          if (!a.isStaffSession) a.loginStaffSilent("admin");
          return const AdminShell();
        },
      ),
      GoRoute(
        path: '/demo/guest',
        builder: (context, state) {
          final a = Provider.of<AppState>(context, listen: false);
          if (!a.isGuestSession) a.activateGuestSilent("204204");
          return const GuestShell();
        },
      ),
      // ---- Public website ----
      GoRoute(
        path: '/website',
        builder: (context, state) => const WebsiteShell(),
      ),
      GoRoute(
        path: '/website/room/:id',
        builder: (context, state) =>
            RoomDetailScreen(roomTypeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/website/booking',
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
        path: '/website/confirmation/:resId',
        builder: (context, state) =>
            ConfirmationScreen(reservationId: state.pathParameters['resId']!),
      ),
      // ---- Guest app ----
      GoRoute(
        path: '/guest/activate',
        builder: (context, state) => const ActivationScreen(),
      ),
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
      // ---- Reception ----
      GoRoute(
        path: '/reception/login',
        builder: (context, state) => const ReceptionLoginScreen(),
      ),
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
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminShell()),
      GoRoute(
        path: '/admin/rooms',
        builder: (context, state) => const RoomsAdminScreen(),
      ),
      GoRoute(
        path: '/admin/audit',
        builder: (context, state) => const AuditLogScreen(),
      ),
    ],
  );
}
