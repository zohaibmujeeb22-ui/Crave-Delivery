import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract defining low-level authentication operations with Supabase.
abstract class SupabaseAuthDataSource {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    String? accessToken,
  });

  Future<AuthResponse> signInWithApple({
    required String idToken,
    required String rawNonce,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}

/// Concrete implementation communicating directly with the Supabase client.
class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseAuthDataSourceImpl({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  Session? get currentSession => _supabaseClient.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    return await _supabaseClient.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<AuthResponse> signInWithApple({
    required String idToken,
    required String rawNonce,
  }) async {
    return await _supabaseClient.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}
