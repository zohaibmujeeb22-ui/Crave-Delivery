import 'package:crave_delivery1/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/startup_controller.dart';
import '../controllers/startup_state.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for state transitions and route accordingly
    ref.listen<StartupState>(startupControllerProvider, (previous, next) {
      switch (next) {
        case NavigateToOnboarding():
          context.go('/onboarding');
          break;
        case NavigateToAuth():
          context.go('/auth');
          break;
        case NavigateToCustomerHome():
          context.go('/customer/home');
          break;
        case NavigateToRestaurantDashboard():
          context.go('/restaurant/dashboard');
          break;
        case NavigateToProfileCompletion():
          context.go('/profile/setup');
          break;
        case StartupError():
        case StartupInitial():
          break;
      }
    });

    final startupState = ref.watch(startupControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Branding — Always pristine
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CRAVE',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Food discovery. Delivered.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Network failure fallback UI
            if (startupState is StartupError)
              Positioned(
                bottom: 40,
                left: 32,
                right: 32,
                child: Column(
                  children: [
                    Text(
                      startupState.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(startupControllerProvider.notifier)
                            .resolveStartup();
                      },
                      child: const Text('Retry Connection'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
