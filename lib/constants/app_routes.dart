import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/farmer/farmer_dashboard.dart';
import '../screens/farmer/add_listing_screen.dart';
import '../screens/farmer/edit_listing_screen.dart';
import '../screens/farmer/my_listings_screen.dart';
import '../screens/farmer/incoming_orders_screen.dart';
import '../screens/farmer/farmer_order_detail_screen.dart';
import '../screens/farmer/crop_doctor_upload_screen.dart';
import '../screens/farmer/crop_doctor_result_screen.dart';
import '../screens/farmer/weather_detail_screen.dart';
import '../screens/farmer/farmer_public_profile_screen.dart';
import '../screens/buyer/buyer_home_screen.dart';
import '../screens/buyer/product_detail_screen.dart';
import '../screens/buyer/place_order_screen.dart';
import '../screens/buyer/my_orders_screen.dart';
import '../screens/buyer/buyer_order_detail_screen.dart';
import '../screens/buyer/search_filter_screen.dart';
import '../screens/buyer/rate_review_screen.dart';
import '../screens/buyer/map_view_screen.dart';
import '../screens/buyer/farmer_profile_view_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/listing_moderation_screen.dart';
import '../screens/admin/category_management_screen.dart';
import '../screens/admin/broadcast_screen.dart';
import '../screens/common/chat_screen.dart';
import '../screens/common/chat_list_screen.dart';
import '../screens/common/notification_screen.dart';
import '../screens/common/profile_screen.dart';

class AppRoutes {
  // ── Route Names ──────────────────────────────────────────

  // Auth
  static const String splash        = '/';
  static const String login         = '/login';

  // Farmer
  static const String farmerDashboard       = '/farmer/dashboard';
  static const String addListing            = '/farmer/add-listing';
  static const String editListing           = '/farmer/edit-listing';
  static const String myListings            = '/farmer/my-listings';
  static const String incomingOrders        = '/farmer/incoming-orders';
  static const String farmerOrderDetail     = '/farmer/order-detail';
  static const String cropDoctorUpload      = '/farmer/crop-doctor';
  static const String cropDoctorResult      = '/farmer/crop-doctor/result';
  static const String weatherDetail         = '/farmer/weather';
  static const String farmerPublicProfile   = '/farmer/profile';

  // Buyer
  static const String buyerHome             = '/buyer/home';
  static const String productDetail         = '/buyer/product-detail';
  static const String placeOrder            = '/buyer/place-order';
  static const String myOrders              = '/buyer/my-orders';
  static const String buyerOrderDetail      = '/buyer/order-detail';
  static const String searchFilter          = '/buyer/search';
  static const String rateReview            = '/buyer/rate-review';
  static const String mapView               = '/buyer/map';
  static const String farmerProfileView     = '/buyer/farmer-profile';

  // Admin
  static const String adminDashboard        = '/admin/dashboard';
  static const String userManagement        = '/admin/users';
  static const String listingModeration     = '/admin/listings';
  static const String categoryManagement    = '/admin/categories';
  static const String broadcast             = '/admin/broadcast';

  // Common
  static const String chat                  = '/chat';
  static const String chatList              = '/chat/list';
  static const String notifications         = '/notifications';
  static const String profile               = '/profile';

  // ── Route Generator ──────────────────────────────────────

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {

    // Auth
      case splash:
        return _route(const SplashScreen());
      case login:
        return _route(const LoginScreen());

    // Farmer
      case farmerDashboard:
        return _route(const FarmerDashboard());
      case addListing:
        return _route(const AddListingScreen());
      case editListing:
        return _route(EditListingScreen(product: args as Map<String, dynamic>));
      case myListings:
        return _route(const MyListingsScreen());
      case incomingOrders:
        return _route(const IncomingOrdersScreen());
      case farmerOrderDetail:
        return _route(FarmerOrderDetailScreen(order: args as Map<String, dynamic>));
      case cropDoctorUpload:
        return _route(const CropDoctorUploadScreen());
      case weatherDetail:
        return _route(const WeatherDetailScreen());
      case farmerPublicProfile:
        return _route(FarmerPublicProfileScreen(farmerId: args as String));

    // Buyer
      case buyerHome:
        return _route(const BuyerHomeScreen());
      case productDetail:
        return _route(ProductDetailScreen(product: args as Map<String, dynamic>));
      case myOrders:
        return _route(const MyOrdersScreen());
      case searchFilter:
        return _route(const SearchFilterScreen());
      case mapView:
        return _route(const MapViewScreen());
      case farmerProfileView:
        return _route(FarmerProfileViewScreen(farmerId: args as String));

    // Admin
      case adminDashboard:
        return _route(const AdminDashboardScreen());
      case userManagement:
        return _route(const UserManagementScreen());
      case listingModeration:
        return _route(const ListingModerationScreen());
      case categoryManagement:
        return _route(const CategoryManagementScreen());
      case broadcast:
        return _route(const BroadcastScreen());

    // Common
      case chatList:
        return _route(const ChatListScreen());
      case notifications:
        return _route(const NotificationScreen());
      case profile:
        return _route(const ProfileScreen());

      default:
        return _route(const SplashScreen());
    }
  }

  // ── Helper ───────────────────────────────────────────────

  static MaterialPageRoute _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }

  // ── Navigation Helpers ───────────────────────────────────
  // এগুলো দিয়ে যেকোনো জায়গা থেকে সহজে navigate করা যাবে

  static void goTo(BuildContext context, String route, {Object? args}) {
    Navigator.pushNamed(context, route, arguments: args);
  }

  static void goReplace(BuildContext context, String route, {Object? args}) {
    Navigator.pushReplacementNamed(context, route, arguments: args);
  }

  static void goAndClear(BuildContext context, String route, {Object? args}) {
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false, arguments: args);
  }

  static void back(BuildContext context) {
    Navigator.pop(context);
  }
}