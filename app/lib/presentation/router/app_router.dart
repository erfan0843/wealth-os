import 'package:go_router/go_router.dart';

import '../screens/app_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/assets/assets_screen.dart';
import '../screens/future/future_screen.dart';
import '../screens/profile/profile_screen.dart';

/// مسیرهای اصلی اپ — با Shell (Bottom Navigation).
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (ctx, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
        GoRoute(
            path: '/transactions',
            builder: (_, __) => const TransactionsScreen()),
        GoRoute(path: '/assets', builder: (_, __) => const AssetsScreen()),
        GoRoute(path: '/future', builder: (_, __) => const FutureScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);
