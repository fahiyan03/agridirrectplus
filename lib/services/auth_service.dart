import 'package:supabase_flutter/supabase_flutter.dart';

// supabase_service.dart এ auth methods আছে।
// এই file টা আলাদাভাবে auth logic organize করার জন্য।
// supabase_service.dart থেকে auth methods এখানে delegate করা হয়েছে।

class AuthService {
  final _supabase = Supabase.instance.client;

  // ── Current User ──────────────────────────────────────────

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // ── Sign Up ───────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? address,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role':      role,
        'phone':     phone,
        'address':   address,
      },
    );
  }

  // ── Sign In ───────────────────────────────────────────────

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email:    email,
      password: password,
    );
  }

  // ── Sign Out ──────────────────────────────────────────────

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ── Password Reset ────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // ── Update Password ───────────────────────────────────────

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ── Get Role from DB ──────────────────────────────────────
  // userMetadata নয়, সবসময় users table থেকে role নাও

  Future<String> getRoleFromDB() async {
    final userId = currentUser?.id;
    if (userId == null) return 'buyer';

    try {
      final data = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      return data['role'] ?? 'buyer';
    } catch (_) {
      return 'buyer';
    }
  }
}