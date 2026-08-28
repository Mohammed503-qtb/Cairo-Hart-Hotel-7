import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/storage/app_store.dart';
import '../../core/network/api_client.dart';
import 'home_screen.dart';
import '../rooms/rooms_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../services/services_screen.dart';
import '../contact/contact_screen.dart';

class GuestShell extends StatefulWidget {
  const GuestShell({super.key});
  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  int _index = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const HomeScreen(),
      const RoomsScreen(),
      const MyBookingsScreen(),
      const ServicesScreen(),
      const ContactScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    final store = context.read<AppStore>();
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.bed_outlined), activeIcon: Icon(Icons.bed), label: 'الغرف'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'حجوزاتي'),
            BottomNavigationBarItem(icon: Icon(Icons.room_service_outlined), activeIcon: Icon(Icons.room_service), label: 'الخدمات'),
            BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), activeIcon: Icon(Icons.support_agent), label: 'تواصل'),
          ],
        ),
      ),
      floatingActionButton: _index == 0
        ? FloatingActionButton.extended(
            onPressed: () {
              if (api.isAuthenticated) {
                store.enterAdmin();
                Navigator.of(context).pushNamedAndRemoveUntil('/admin', (_) => false);
              } else {
                Navigator.of(context).pushNamed('/login');
              }
            },
            icon: const Icon(Icons.admin_panel_settings, size: 20),
            label: const Text('لوحة الإدارة'),
            backgroundColor: AppTheme.accent,
          )
        : null,
    );
  }
}
