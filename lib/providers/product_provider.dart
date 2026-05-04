import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ProductProvider extends ChangeNotifier {
  final _service = SupabaseService();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _myProducts = [];
  bool _isLoading = false;
  String? _error;
  int _selectedZone = 0; // 0 = all zones

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get myProducts => _myProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedZone => _selectedZone;

  Future<void> loadAllProducts({int? zone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (zone != null && zone > 0) {
        _products = await _service.getProductsByZone(zone);
        _selectedZone = zone;
      } else {
        _products = await _service.getAllProducts();
        _selectedZone = 0;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _myProducts = await _service.getMyProducts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required int zone,
    required double quantity,
    required String unit,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _service.createProduct(
        title: title,
        description: description,
        price: price,
        category: category,
        zone: zone,
        quantity: quantity,
        unit: unit,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
      );
      await loadMyProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _service.deleteProduct(productId);
      _myProducts.removeWhere((p) => p['id'] == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}