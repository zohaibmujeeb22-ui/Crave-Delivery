import 'package:crave_delivery1/app/app_colors.dart';
import 'package:crave_delivery1/features/auth/presentation/screens/oauth_selection_screen.dart';
import 'package:crave_delivery1/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/shared_prefs_service.dart';
import '../features/auth/controllers/auth_state.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

/// Bridges Riverpod AuthState changes to GoRouter's refreshListenable.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, _) {
      notifyListeners();
    });
  }
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final hasCompletedOnboarding = ref
          .read(onboardingServiceProvider)
          .hasCompletedOnboarding();

      final currentPath = state.uri.path;

      // 1. Splash screen controls its own silent initial resolution
      if (currentPath == '/') return null;

      // 2. Onboarding Guard: First-time users must see onboarding
      if (!hasCompletedOnboarding) {
        return currentPath == '/onboarding' ? null : '/onboarding';
      }

      // If user has completed onboarding and tries to re-enter onboarding, route to auth
      if (hasCompletedOnboarding && currentPath == '/onboarding') {
        return '/auth';
      }

      // 3. Auth States & Route Guards
      final isAuthRoute =
          currentPath == '/auth' ||
          currentPath == '/signup' ||
          currentPath == '/forgot-password';

      switch (authState) {
        case CustomerAuthenticated():
          if (isAuthRoute ||
              currentPath.startsWith('/restaurant') ||
              currentPath == '/profile/setup') {
            return '/customer/home';
          }
          break;

        case RestaurantOwnerAuthenticated():
          if (isAuthRoute ||
              currentPath.startsWith('/customer') ||
              currentPath == '/profile/setup') {
            return '/restaurant/dashboard';
          }
          break;

        case ProfileCompletionRequired():
          if (currentPath != '/profile/setup') {
            return '/profile/setup';
          }
          break;

        case AuthUnauthenticated():
        case AuthError():
        case AuthInitial():
          if (currentPath.startsWith('/customer') ||
              currentPath.startsWith('/restaurant') ||
              currentPath == '/profile/setup' ||
              currentPath == '/customer/home' ||
              currentPath == '/restaurant/dashboard') {
            return '/auth';
          }
          break;

        case EmailVerificationPending():
        case AuthLoading():
          break;
      }

      return null; // No redirect needed; proceed to destination
    },
    routes: [
      // Splash
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Shared Authentication Portal
      GoRoute(path: '/auth', builder: (context, state) => const LoginScreen()),

      // Registration Flow
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Password Recovery
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // New OAuth First-Time Setup
      GoRoute(
        path: '/profile/setup',
        builder: (context, state) => const OAuthRoleSelectionScreen(),
      ),

      // Customer Area (Future Marketplace Milestone)
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => const RoleHomePlaceholder(
          title: 'Customer Discovery Feed',
          subtitle: 'Browse food reels, discover restaurants, and order COD.',
          icon: Icons.fastfood_rounded,
        ),
      ),

      // Restaurant Partner Area (Future Console Milestone)
      GoRoute(
        path: '/restaurant/dashboard',
        builder: (context, state) => const RoleHomePlaceholder(
          title: 'Restaurant Console',
          subtitle: 'Live kitchen order alerts, menu management, and sales.',
          icon: Icons.storefront_rounded,
        ),
      ),
    ],
  );
});

/// High-contrast placeholder for protected destinations until future milestones are implemented.
class RoleHomePlaceholder extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const RoleHomePlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.userProfile;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, ${user?.fullName ?? "Partner"}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E24),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out of CRAVE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
