import 'package:crave_delivery1/features/auth/data/auth_repository.dart';
import 'package:crave_delivery1/features/auth/domain/models/user_profile.dart';
import 'package:crave_delivery1/features/auth/domain/models/user_role.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Exhaustive state machine modeling all authentication scenarios in CRAVE.
@immutable
sealed class AuthState {
  const AuthState();

  bool get isLoading => this is AuthLoading;

  UserProfile? get userProfile {
    return switch (this) {
      CustomerAuthenticated(:final profile) => profile,
      RestaurantOwnerAuthenticated(:final profile) => profile,
      _ => null,
    };
  }
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class CustomerAuthenticated extends AuthState {
  final UserProfile profile;
  const CustomerAuthenticated(this.profile);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAuthenticated && profile == other.profile;

  @override
  int get hashCode => profile.hashCode;
}

class RestaurantOwnerAuthenticated extends AuthState {
  final UserProfile profile;
  const RestaurantOwnerAuthenticated(this.profile);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantOwnerAuthenticated && profile == other.profile;

  @override
  int get hashCode => profile.hashCode;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class ProfileCompletionRequired extends AuthState {
  final String userId;
  final String email;

  const ProfileCompletionRequired({required this.userId, required this.email});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileCompletionRequired &&
          userId == other.userId &&
          email == other.email;

  @override
  int get hashCode => userId.hashCode ^ email.hashCode;
}

class EmailVerificationPending extends AuthState {
  final String email;

  const EmailVerificationPending(this.email);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailVerificationPending && email == other.email;

  @override
  int get hashCode => email.hashCode;
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(authRepository: ref.watch(authRepositoryProvider));
  },
);

/// Riverpod StateNotifier coordinating user authentication and session states.
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    restoreSession();
  }

  /// Restores session on cold boot and maps authoritative role to state.
  Future<void> restoreSession() async {
    try {
      final user = _authRepository.currentAuthUser;
      if (user == null) {
        state = const AuthUnauthenticated();
        return;
      }

      final profile = await _authRepository.getCurrentUserProfile();
      if (profile == null) {
        // Authenticated in Auth, but missing profile in PostgreSQL (OAuth edge case)
        state = ProfileCompletionRequired(
          userId: user.id,
          email: user.email ?? '',
        );
        return;
      }

      _mapProfileToState(profile);
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Shared login for both Customers and Restaurant Owners.
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final profile = await _authRepository.loginWithEmail(
        email: email,
        password: password,
      );
      _mapProfileToState(profile);
    } on supabase.AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Native Google OAuth flow.
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final profile = await _authRepository.signInWithGoogle();
      if (profile != null) {
        _mapProfileToState(profile);
      } else {
        final currentUser = _authRepository.currentAuthUser;
        if (currentUser != null) {
          // New OAuth user needing role selection
          state = ProfileCompletionRequired(
            userId: currentUser.id,
            email: currentUser.email ?? '',
          );
        } else {
          // Prompt was dismissed by user
          state = const AuthUnauthenticated();
        }
      }
    } on supabase.AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Google Sign-In failed: ${e.toString()}');
    }
  }

  /// Native Apple Sign-In flow.
  Future<void> signInWithApple() async {
    state = const AuthLoading();
    try {
      final profile = await _authRepository.signInWithApple();
      if (profile != null) {
        _mapProfileToState(profile);
      } else {
        final currentUser = _authRepository.currentAuthUser;
        if (currentUser != null) {
          state = ProfileCompletionRequired(
            userId: currentUser.id,
            email: currentUser.email ?? '',
          );
        } else {
          state = const AuthUnauthenticated();
        }
      }
    } on supabase.AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Apple Sign-In failed: ${e.toString()}');
    }
  }

  /// Sends a password recovery email.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } on supabase.AuthException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError('Password reset failed: ${e.toString()}');
      return false;
    }
  }

  /// Terminates the active session and resets state.
  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _authRepository.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Logout failed: ${e.toString()}');
    }
  }

  /// Helper to enforce authoritative role destination.
  void _mapProfileToState(UserProfile profile) {
    if (profile.role == UserRole.restaurantOwner) {
      state = RestaurantOwnerAuthenticated(profile);
    } else {
      state = CustomerAuthenticated(profile);
    }
  }
}
