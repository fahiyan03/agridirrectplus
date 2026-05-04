import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/in_app_notification_service.dart';
import '../constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final _service = SupabaseService();
  final _notifService = InAppNotificationService();

  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  // role সবসময় users TABLE থেকে
  String get role => _profile?['role'] ?? UserRole.buyer;

  AuthProvider() {
    _user = Supabase.instance.client.auth.currentUser;
    if (_user != null) {
      _loadProfile();
      _notifService.startListening(); // notification listener শুরু
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadProfile();
        _notifService.startListening(); // login হলে listener শুরু
      } else {
        _profile = null;
        _notifService.stopListening(); // logout হলে listener বন্ধ
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    try {
      _profile = await _service.getUserProfile(_user!.id);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.signIn(email, password);
      _user = response.user;
      await _loadProfile();
      _notifService.startListening();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = unexpectedErrorMessage;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
      );
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = unexpectedErrorMessage;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _notifService.stopListening();
    await _service.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }
}