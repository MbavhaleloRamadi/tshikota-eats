//import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';

// Store Browsing
import '../features/store_browsing/presentation/buyer_shell.dart';
import '../features/store_browsing/presentation/home_screen.dart';
import '../features/store_browsing/presentation/store_screen.dart';

// Orders
import '../features/orders/presentation/cart_screen.dart';
import '../features/orders/presentation/checkout_screen.dart';
import '../features/orders/presentation/order_history_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';

// Buyer Profile
import '../features/buyer_profile/presentation/profile_screen.dart';

// Company Dashboard
import '../features/company_dashboard/presentation/company_shell.dart';
import '../features/company_dashboard/presentation/dashboard_screen.dart';
import '../features/company_dashboard/presentation/orders_screen.dart';
import '../features/company_dashboard/presentation/menu_management_screen.dart';
import '../features/company_dashboard/presentation/analytics_screen.dart';
import '../features/company_dashboard/presentation/settings_screen.dart';

// Developer
import '../features/developer/presentation/developer_shell.dart';
import '../features/developer/presentation/dev_dashboard_screen.dart';

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
            builder: (_, __) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: '/buyer/profile',
            builder: (_, __) => const BuyerProfileScreen(),
          ),
        ],
      ),

      // Outside shell
      GoRoute(
        path: '/store/:slug',
        builder: (_, state) => StoreScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
        path: '/order/:orderId',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),

      // Company shell
      ShellRoute(
        builder: (_, __, child) => CompanyShell(child: child),
        routes: [
          GoRoute(
            path: '/company/dashboard',
            builder: (_, __) => const CompanyDashboardScreen(),
          ),
          GoRoute(
            path: '/company/orders',
            builder: (_, __) => const CompanyOrdersScreen(),
          ),
          GoRoute(
            path: '/company/menu',
            builder: (_, __) => const MenuManagementScreen(),
          ),
          GoRoute(
            path: '/company/analytics',
            builder: (_, __) => const CompanyAnalyticsScreen(),
          ),
          GoRoute(
            path: '/company/settings',
            builder: (_, __) => const CompanySettingsScreen(),
          ),
        ],
      ),

      // Developer shell
      ShellRoute(
        builder: (_, __, child) => DeveloperShell(child: child),
        routes: [
          GoRoute(
            path: '/developer/dashboard',
            builder: (_, __) => const DevDashboardScreen(),
          ),
        ],
      ),
    ],
  );
});
