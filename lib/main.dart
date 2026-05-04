import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/zone_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/in_app_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qarxdcgjehbgnqozqzfm.supabase.co',         // তোমার Supabase URL এখানে বসাও
    anonKey: 'sb_publishable_lpJnfszb3J8QuLaciMu-Ow_HRTNLlvN', // তোমার Anon Key এখানে বসাও
  );

  runApp(const AgriDirectApp());
}

class AgriDirectApp extends StatelessWidget {
  const AgriDirectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AgriDirect+',
        theme: appTheme,
        // GlobalKey যোগ করা হয়েছে - in-app notification এর জন্য
        navigatorKey: InAppNotificationService().navigatorKey,
        home: const SplashScreen(),
      ),
    );
  }
}