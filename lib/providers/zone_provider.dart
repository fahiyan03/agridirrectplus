import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ZoneProvider extends ChangeNotifier {
  int _selectedZone = 0; // 0 = সব zone

  int get selectedZone => _selectedZone;
  bool get isAllZones  => _selectedZone == 0;

  // Selected zone এর config
  ZoneConfig? get selectedZoneConfig {
    if (_selectedZone == 0) return null;
    return zoneConfigs.firstWhere(
          (z) => z.zone == _selectedZone,
      orElse: () => zoneConfigs.first,
    );
  }

  void selectZone(int zone) {
    if (_selectedZone == zone) return;
    _selectedZone = zone;
    notifyListeners();
  }

  void clearZone() {
    _selectedZone = 0;
    notifyListeners();
  }

  // Zone এর categories
  List<String> get currentCategories {
    if (_selectedZone == 0) {
      // সব zone এর সব categories
      return zoneConfigs.expand((z) => z.categories).toSet().toList();
    }
    return selectedZoneConfig?.categories ?? [];
  }

  // Zone এর color
  Color get currentColor {
    return selectedZoneConfig?.color ?? AppColors.primary;
  }

  // Zone এর delivery time
  String get currentDeliveryTime {
    return selectedZoneConfig?.deliveryTimeBn ?? '';
  }
}