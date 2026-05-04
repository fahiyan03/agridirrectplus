import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// MyChatApp-এর constants.dart থেকে adapted
// পরিবর্তন: Orange theme → AgriDirect Green theme, AgriDirect-specific constants যোগ

// ─── SUPABASE ─────────────────────────────────────────────────

final supabase = Supabase.instance.client;

// ─── AGRIDIRECT COLORS ────────────────────────────────────────

class AppColors {
  // Primary - Green (কৃষি থিম)
  static const Color primary       = Color(0xFF2E7D32); // deep green
  static const Color primaryLight  = Color(0xFF4CAF50); // medium green
  static const Color primaryDark   = Color(0xFF1B5E20); // dark green

  // Accent
  static const Color accent        = Color(0xFFFFA000); // amber - ফসলের রঙ
  static const Color accentLight   = Color(0xFFFFCA28);

  // Background
  static const Color background    = Color(0xFFF1F8E9); // very light green
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color cardBg        = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary   = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textHint      = Color(0xFF9E9E9E);

  // Status
  static const Color success       = Color(0xFF43A047);
  static const Color warning       = Color(0xFFFFA000);
  static const Color error         = Color(0xFFD32F2F);
  static const Color info          = Color(0xFF0288D1);

  // Zone Colors
  static const Color zone1         = Color(0xFF66BB6A); // সবজি - হালকা সবুজ
  static const Color zone2         = Color(0xFF26A69A); // ফল - টিল
  static const Color zone3         = Color(0xFF42A5F5); // চাল/আলু - নীল
  static const Color zone4         = Color(0xFFAB47BC); // সারাদেশ - বেগুনি
}

// ─── LOADING WIDGET (MyChatApp-এর preloader থেকে adapted) ────

const preloader = Center(
  child: CircularProgressIndicator(color: AppColors.primary),
);

// ─── SPACING (MyChatApp-এর spacer থেকে adapted) ──────────────

const spacer = SizedBox(width: 16, height: 16);
const spacerSm = SizedBox(width: 8, height: 8);
const spacerLg = SizedBox(width: 24, height: 24);

// ─── PADDING ──────────────────────────────────────────────────

const formPadding = EdgeInsets.symmetric(vertical: 20, horizontal: 16);
const pagePadding = EdgeInsets.all(16);
const cardPadding = EdgeInsets.all(12);

// ─── ERROR MESSAGES ───────────────────────────────────────────

const unexpectedErrorMessage = 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';

// ─── PASSWORD VALIDATOR ───────────────────────────────────────

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'পাসওয়ার্ড দিন';

  if (value.length < 8) {
    return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'কমপক্ষে একটি বড় হাতের অক্ষর (A-Z) দিন';
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'কমপক্ষে একটি ছোট হাতের অক্ষর (a-z) দিন';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'কমপক্ষে একটি সংখ্যা (0-9) দিন';
  }
  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    return 'কমপক্ষে একটি বিশেষ চিহ্ন (!@#\$%) দিন';
  }

  return null;
}
// ─── ZONE CONFIG ──────────────────────────────────────────────

class ZoneConfig {
  final int zone;
  final String name;
  final String nameBn;
  final double radiusKm;
  final String deliveryTime;
  final String deliveryTimeBn;
  final Color color;
  final List<String> categories;

  const ZoneConfig({
    required this.zone,
    required this.name,
    required this.nameBn,
    required this.radiusKm,
    required this.deliveryTime,
    required this.deliveryTimeBn,
    required this.color,
    required this.categories,
  });
}

const List<ZoneConfig> zoneConfigs = [
  ZoneConfig(
    zone: 1,
    name: 'Zone 1 - Hyper Local',
    nameBn: 'জোন ১ - হাইপার লোকাল',
    radiusKm: 2,
    deliveryTime: 'Same Day',
    deliveryTimeBn: 'আজকেই ডেলিভারি',
    color: AppColors.zone1,
    categories: ['সবজি', 'মাছ', 'দুধ', 'ডিম', 'ফুল'],
  ),
  ZoneConfig(
    zone: 2,
    name: 'Zone 2 - Local',
    nameBn: 'জোন ২ - লোকাল',
    radiusKm: 7,
    deliveryTime: '1-3 Days',
    deliveryTimeBn: '১-৩ দিনের মধ্যে',
    color: AppColors.zone2,
    categories: ['ফল', 'মুরগি', 'মৌসুমি সবজি'],
  ),
  ZoneConfig(
    zone: 3,
    name: 'Zone 3 - Regional',
    nameBn: 'জোন ৩ - রিজিওনাল',
    radiusKm: 30,
    deliveryTime: 'Pre-order 7 Days',
    deliveryTimeBn: '৭ দিন আগে প্রি-অর্ডার',
    color: AppColors.zone3,
    categories: ['চাল', 'আলু', 'পেঁয়াজ', 'রসুন', 'গম'],
  ),
  ZoneConfig(
    zone: 4,
    name: 'Zone 4 - National',
    nameBn: 'জোন ৪ - সারাদেশ',
    radiusKm: 9999,
    deliveryTime: 'Courier 3-7 Days',
    deliveryTimeBn: 'কুরিয়ারে ৩-৭ দিন',
    color: AppColors.zone4,
    categories: ['শুকনো মরিচ', 'মশলা', 'চিংড়ি', 'হলুদ', 'আদা'],
  ),
];

// ─── ORDER STATUS ─────────────────────────────────────────────

class OrderStatus {
  static const String pending   = 'pending';
  static const String accepted  = 'accepted';
  static const String rejected  = 'rejected';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static String toBangla(String status) {
    switch (status) {
      case pending:   return 'অপেক্ষমাণ';
      case accepted:  return 'গৃহীত';
      case rejected:  return 'বাতিল';
      case delivered: return 'ডেলিভারি হয়েছে';
      case cancelled: return 'বাতিল করা হয়েছে';
      default:        return status;
    }
  }

  static Color toColor(String status) {
    switch (status) {
      case pending:   return AppColors.warning;
      case accepted:  return AppColors.info;
      case delivered: return AppColors.success;
      case rejected:
      case cancelled: return AppColors.error;
      default:        return AppColors.textSecondary;
    }
  }
}

// ─── USER ROLES ───────────────────────────────────────────────

class UserRole {
  static const String farmer = 'farmer';
  static const String buyer  = 'buyer';
  static const String admin  = 'admin';
}

// ─── APP THEME (MyChatApp-এর appTheme থেকে inspired, AgriDirect Green দিয়ে) ──

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    color: AppColors.cardBg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    floatingLabelStyle: const TextStyle(color: AppColors.primary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
);

// ─── SNACKBAR EXTENSION (MyChatApp-এর ShowSnackBar extension সরাসরি নেওয়া) ──

extension ShowSnackBar on BuildContext {
  void showSnackBar({
    required String message,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void showErrorSnackBar({required String message}) {
    showSnackBar(message: message, backgroundColor: AppColors.error);
  }

  void showSuccessSnackBar({required String message}) {
    showSnackBar(message: message, backgroundColor: AppColors.success);
  }
}