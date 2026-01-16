import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_list_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import '../../features/capture/presentation/screens/capture_screen.dart';
import '../../features/capture/presentation/screens/review_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final isAuthRoute = state.matchedLocation == '/auth' || 
                          state.matchedLocation == '/splash';

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }

      if (isAuthenticated && state.matchedLocation == '/auth') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const SubscriptionListScreen(),
        routes: [
          GoRoute(
            path: 'subscription/:id',
            name: 'subscription-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SubscriptionDetailScreen(subscriptionId: id);
            },
          ),
          GoRoute(
            path: 'capture',
            name: 'capture',
            builder: (context, state) => const CaptureScreen(),
          ),
          GoRoute(
            path: 'review',
            name: 'review',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ReviewScreen(
                imageData: extra?['imageData'] as String? ?? '',
                filename: extra?['filename'] as String? ?? 'receipt.jpg',
                mimeType: extra?['mimeType'] as String? ?? 'image/jpeg',
              );
            },
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});
