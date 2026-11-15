import 'dart:io';
import 'package:crave_delivery1/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:crave_delivery1/features/auth/data/datasources/supabase_profile_datasource.dart';
import 'package:crave_delivery1/features/auth/domain/models/resturant_profile.dart';
import 'package:crave_delivery1/features/auth/domain/models/user_profile.dart';
import 'package:crave_delivery1/features/auth/domain/models/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// --- DATA SOURCE PROVIDERS ---
final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((ref) {
  return SupabaseAuthDataSourceImpl();
});

final supabaseProfileDataSourceProvider = Provider<SupabaseProfileDataSource>((
  ref,
) {
  return SupabaseProfileDataSourceImpl();
});

// --- REPOSITORY PROVIDER ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authDataSource: ref.watch(supabaseAuthDataSourceProvider),
    profileDataSource: ref.watch(supabaseProfileDataSourceProvider),
  );
});

/// Contract defining all authentication workflows available to the application.
abstract class AuthRepository {
  supabase.User? get currentAuthUser;
  Future<UserProfile?> getCurrentUserProfile();

  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  });

  Future<UserProfile> registerRestaurantOwner({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String restaurantName,
    String? restaurantDescription,
    required RestaurantCategory category,
    required String city,
    required String address,
    required String restaurantContact,
    File? logoFile,
    File? coverFile,
  });

  Future<UserProfile?> signInWithGoogle();
  Future<UserProfile?> signInWithApple();

  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}

/// Concrete implementation coordinating Auth, PostgreSQL, and Storage.
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _authDataSource;
  final SupabaseProfileDataSource _profileDataSource;

  AuthRepositoryImpl({
    required SupabaseAuthDataSource authDataSource,
    required SupabaseProfileDataSource profileDataSource,
  }) : _authDataSource = authDataSource,
       _profileDataSource = profileDataSource;

  @override
  supabase.User? get currentAuthUser => _authDataSource.currentUser;

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _authDataSource.currentUser;
    if (user == null) return null;

    final profileData = await _profileDataSource.getProfile(user.id);
    if (profileData == null) return null;

    return UserProfile.fromJson(profileData);
  }

  @override
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // 1. Authenticate with Supabase Auth
    final response = await _authDataSource.signInWithEmail(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const supabase.AuthException(
        'Login failed: User credentials invalid.',
      );
    }

    // 2. Fetch authoritative profile from PostgreSQL
    final profileData = await _profileDataSource.getProfile(user.id);
    if (profileData == null) {
      throw const supabase.AuthException('Account profile record not found.');
    }

    final userProfile = UserProfile.fromJson(profileData);

    // 3. Check account status
    if (userProfile.accountStatus == AccountStatus.suspended) {
      await _authDataSource.signOut();
      throw const supabase.AuthException(
        'This account has been suspended. Please contact support.',
      );
    }

    return userProfile;
  }

  @override
  Future<UserProfile> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    // 1. Create auth user in auth.users
    final authResponse = await _authDataSource.signUpWithEmail(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) {
      throw const supabase.AuthException(
        'Signup failed: Unable to create credentials.',
      );
    }

    // 2. Insert profile record in public.profiles with role = customer
    await _profileDataSource.createCustomerProfile(
      userId: user.id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
    );

    // 3. Return verified UserProfile
    return UserProfile(
      id: user.id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      role: UserRole.customer,
      accountStatus: AccountStatus.active,
      isProfileCompleted: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<UserProfile> registerRestaurantOwner({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String restaurantName,
    String? restaurantDescription,
    required RestaurantCategory category,
    required String city,
    required String address,
    required String restaurantContact,
    File? logoFile,
    File? coverFile,
  }) async {
    // 1. Create auth user
    final authResponse = await _authDataSource.signUpWithEmail(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) {
      throw const supabase.AuthException(
        'Signup failed: Unable to create credentials.',
      );
    }

    // 2. Upload branding assets to restaurant-assets bucket (if provided)
    String? logoUrl;
    String? coverUrl;

    if (logoFile != null) {
      logoUrl = await _profileDataSource.uploadRestaurantAsset(
        userId: user.id,
        file: logoFile,
        assetType: 'logos',
      );
    }

    if (coverFile != null) {
      coverUrl = await _profileDataSource.uploadRestaurantAsset(
        userId: user.id,
        file: coverFile,
        assetType: 'covers',
      );
    }

    // 3. Execute atomic PostgreSQL transaction RPC (created in Migration 001)
    await _profileDataSource.registerRestaurantOwner(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      restaurantName: restaurantName,
      restaurantDescription: restaurantDescription,
      category: category.displayName,
      city: city,
      address: address,
      restaurantContact: restaurantContact,
      logoUrl: logoUrl,
      coverUrl: coverUrl,
    );

    // 4. Return verified UserProfile with restaurantOwner role
    return UserProfile(
      id: user.id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      role: UserRole.restaurantOwner,
      accountStatus: AccountStatus.active,
      isProfileCompleted: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<UserProfile?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled prompt

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const supabase.AuthException(
        'Google Sign-In failed: No ID Token retrieved.',
      );
    }

    final authResponse = await _authDataSource.signInWithGoogle(
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = authResponse.user;
    if (user == null) return null;

    // Check if user already has an authoritative profile in PostgreSQL
    final profileData = await _profileDataSource.getProfile(user.id);
    if (profileData == null) {
      // New OAuth user: needs role selection screen
      return null;
    }

    return UserProfile.fromJson(profileData);
  }

  @override
  Future<UserProfile?> signInWithApple() async {
    final rawNonce =
        _authDataSource.currentUser?.id ?? DateTime.now().toIso8601String();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const supabase.AuthException(
        'Apple Sign-In failed: No Identity Token retrieved.',
      );
    }

    final authResponse = await _authDataSource.signInWithApple(
      idToken: idToken,
      rawNonce: rawNonce,
    );

    final user = authResponse.user;
    if (user == null) return null;

    final profileData = await _profileDataSource.getProfile(user.id);
    if (profileData == null) {
      return null; // Needs role selection screen
    }

    return UserProfile.fromJson(profileData);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _authDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }
}
