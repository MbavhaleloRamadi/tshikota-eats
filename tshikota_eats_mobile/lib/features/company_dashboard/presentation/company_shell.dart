import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyShell extends StatelessWidget {
  final Widget child;
  const CompanyShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/company/dashboard')) return 0;
    if (loc.startsWith('/company/orders')) return 1;
    if (loc.startsWith('/company/menu')) return 2;
    if (loc.startsWith('/company/analytics')) return 3;
    if (loc.startsWith('/company/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/company/dashboard');
              break;
            case 1:
              context.go('/company/orders');
              break;
            case 2:
              context.go('/company/menu');
              break;
            case 3:
              context.go('/company/analytics');
              break;
            case 4:
              context.go('/company/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Menu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
