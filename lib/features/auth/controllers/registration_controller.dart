import 'dart:io';
import 'package:crave_delivery1/features/auth/controllers/auth_controllers.dart';
import 'package:crave_delivery1/features/auth/data/auth_repository.dart';
import 'package:crave_delivery1/features/auth/domain/models/resturant_profile.dart';
import 'package:crave_delivery1/features/auth/domain/models/user_role.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// --- STATE DEFINITION ---
@immutable
class RegistrationState {
  final UserRole selectedRole;
  final RestaurantCategory selectedCategory;
  final File? logoFile;
  final File? coverFile;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const RegistrationState({
    this.selectedRole = UserRole.customer,
    this.selectedCategory = RestaurantCategory.fastFood,
    this.logoFile,
    this.coverFile,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  bool get isCustomer => selectedRole == UserRole.customer;
  bool get isRestaurantOwner => selectedRole == UserRole.restaurantOwner;

  RegistrationState copyWith({
    UserRole? selectedRole,
    RestaurantCategory? selectedCategory,
    File? Function()? logoFile,
    File? Function()? coverFile,
    bool? isLoading,
    String? Function()? errorMessage,
    bool? isSuccess,
  }) {
    return RegistrationState(
      selectedRole: selectedRole ?? this.selectedRole,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      logoFile: logoFile != null ? logoFile() : this.logoFile,
      coverFile: coverFile != null ? coverFile() : this.coverFile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// --- PROVIDER ---
final registrationControllerProvider =
    StateNotifierProvider.autoDispose<
      RegistrationController,
      RegistrationState
    >((ref) {
      return RegistrationController(
        authRepository: ref.watch(authRepositoryProvider),
        authController: ref.read(authControllerProvider.notifier),
      );
    });

// --- CONTROLLER IMPLEMENTATION ---
class RegistrationController extends StateNotifier<RegistrationState> {
  final AuthRepository _authRepository;
  final AuthController _authController;

  RegistrationController({
    required AuthRepository authRepository,
    required AuthController authController,
  }) : _authRepository = authRepository,
       _authController = authController,
       super(const RegistrationState());

  /// Changes the registration mode (Customer vs Restaurant Owner)
  void selectRole(UserRole role) {
    if (state.selectedRole == role) return;
    state = state.copyWith(selectedRole: role, errorMessage: () => null);
  }

  /// Sets the restaurant category from the bottom sheet picker
  void selectCategory(RestaurantCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Stores local logo photo chosen by the user
  void setLogoFile(File? file) {
    state = state.copyWith(logoFile: () => file);
  }

  /// Stores local cover photo chosen by the user
  void setCoverFile(File? file) {
    state = state.copyWith(coverFile: () => file);
  }

  /// Clears any lingering error message
  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }

  /// Executes Customer registration workflow
  Future<bool> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      await _authRepository.registerCustomer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
      // Refresh top-level session to trigger automatic routing
      await _authController.restoreSession();
      return true;
    } on supabase.AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Customer registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Executes Restaurant Owner registration workflow (Owner + Restaurant + Images)
  Future<bool> registerRestaurantOwner({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String restaurantName,
    String? restaurantDescription,
    required String city,
    required String address,
    required String restaurantContact,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      await _authRepository.registerRestaurantOwner(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        restaurantName: restaurantName,
        restaurantDescription: restaurantDescription,
        category: state.selectedCategory,
        city: city,
        address: address,
        restaurantContact: restaurantContact,
        logoFile: state.logoFile,
        coverFile: state.coverFile,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
      // Refresh top-level session to trigger automatic routing
      await _authController.restoreSession();
      return true;
    } on supabase.AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Restaurant registration failed: ${e.toString()}',
      );
      return false;
    }
  }
}
