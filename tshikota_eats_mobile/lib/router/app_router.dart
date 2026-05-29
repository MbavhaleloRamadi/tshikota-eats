import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/buyer/buyer_shell.dart';
import '../screens/buyer/home_screen.dart';
import '../screens/buyer/store_screen.dart';
import '../screens/buyer/cart_screen.dart';
import '../screens/buyer/checkout_screen.dart';
import '../screens/buyer/order_history_screen.dart';
import '../screens/buyer/order_detail_screen.dart';
import '../screens/company/company_shell.dart';
import '../screens/company/dashboard_screen.dart';
import '../screens/company/orders_screen.dart';
import '../screens/company/menu_management_screen.dart';
import '../screens/company/analytics_screen.dart';
import '../screens/company/settings_screen.dart';
import '../screens/developer/developer_shell.dart';
import '../screens/developer/dev_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Buyer shell
      ShellRoute(
        builder: (_, __, child) => BuyerShell(child: child),
        routes: [
          GoRoute(path: '/buyer/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/buyer/cart', builder: (_, __) => const CartScreen()),
          GoRoute(
              path: '/buyer/orders',
              builder: (_, __) => const OrderHistoryScreen()),
          GoRoute(
              path: '/buyer/profile',
              builder: (_, __) =>
                  const Scaffold(body: Center(child: Text('Profile')))),
        ],
      ),

      // Outside shell
      GoRoute(
          path: '/store/:slug',
          builder: (_, state) =>
              StoreScreen(slug: state.pathParameters['slug']!)),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
          path: '/order/:orderId',
          builder: (_, state) =>
              OrderDetailScreen(orderId: state.pathParameters['orderId']!)),

      // Company shell
      ShellRoute(
        builder: (_, __, child) => CompanyShell(child: child),
        routes: [
          GoRoute(
              path: '/company/dashboard',
              builder: (_, __) => const CompanyDashboardScreen()),
          GoRoute(
              path: '/company/orders',
              builder: (_, __) => const CompanyOrdersScreen()),
          GoRoute(
              path: '/company/menu',
              builder: (_, __) => const MenuManagementScreen()),
          GoRoute(
              path: '/company/analytics',
              builder: (_, __) => const CompanyAnalyticsScreen()),
          GoRoute(
              path: '/company/settings',
              builder: (_, __) => const CompanySettingsScreen()),
        ],
      ),

      // Developer shell
      ShellRoute(
        builder: (_, __, child) => DeveloperShell(child: child),
        routes: [
          GoRoute(
              path: '/developer/dashboard',
              builder: (_, __) => const DevDashboardScreen()),
        ],
      ),
    ],
  );
});
