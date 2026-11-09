import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../../auth/domain/user_role.dart';
import 'startup_state.dart';

final startupControllerProvider =
    StateNotifierProvider<StartupController, StartupState>((ref) {
      return StartupController(
        onboardingService: ref.watch(onboardingServiceProvider),
        supabase: Supabase.instance.client,
      );
    });

class StartupController extends StateNotifier<StartupState> {
  final OnboardingService _onboardingService;
  final SupabaseClient _supabase;

  StartupController({
    required OnboardingService onboardingService,
    required SupabaseClient supabase,
  }) : _onboardingService = onboardingService,
       _supabase = supabase,
       super(const StartupInitial()) {
    resolveStartup();
  }

  Future<void> resolveStartup() async {
    state = const StartupInitial();

    try {
      // 1. Check if the user has completed Onboarding
      final hasCompletedOnboarding = _onboardingService
          .hasCompletedOnboarding();
      if (!hasCompletedOnboarding) {
        state = const NavigateToOnboarding();
        return;
      }

      // 2. Check for an active Supabase session
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;

      if (session == null || user == null) {
        state = const NavigateToAuth();
        return;
      }

      // 3. Fetch authoritative profile & role from the database
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Authenticated user exists in Auth, but has not completed profile setup
        state = const NavigateToProfileCompletion();
        return;
      }

      final role = UserRole.fromString(response['role'] as String?);

      // 4. Role-based silent resolution
      switch (role) {
        case UserRole.customer:
          state = const NavigateToCustomerHome();
          break;
        case UserRole.restaurantOwner:
          state = const NavigateToRestaurantDashboard();
          break;
        case UserRole.unknown:
          state = const NavigateToProfileCompletion();
          break;
      }
    } on SocketException {
      state = const StartupError(
        'Unable to connect to CRAVE network. Please check your connection.',
      );
    } catch (e) {
      state = StartupError('Initialization error: ${e.toString()}');
    }
  }
}
