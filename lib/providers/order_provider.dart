import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  final _service = SupabaseService();

  List<Map<String, dynamic>> _myOrders = [];
  List<Map<String, dynamic>> _incomingOrders = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get myOrders => _myOrders;
  List<Map<String, dynamic>> get incomingOrders => _incomingOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Buyer: আমার অর্ডার লোড করো ───────────────────────────
  Future<void> loadMyOrdersAsBuyer() async {
    _isLoading = true;
    _error = null; // FIX: পুরনো error clear করো
    notifyListeners();
    try {
      _myOrders = await _service.getMyOrdersAsBuyer();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Farmer: আসা অর্ডার লোড করো ──────────────────────────
  Future<void> loadIncomingOrdersAsFarmer() async {
    _isLoading = true;
    _error = null; // FIX: পুরনো error clear করো
    notifyListeners();
    try {
      _incomingOrders = await _service.getIncomingOrdersAsFarmer();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Buyer: অর্ডার দাও ────────────────────────────────────
  Future<bool> placeOrder({
    required String productId,
    required String farmerId,
    required double quantity,
    required double totalPrice,
    String? deliveryAddress,
    String? notes,
  }) async {
    _error = null;
    try {
      await _service.createOrder(
        productId: productId,
        farmerId: farmerId,
        quantity: quantity,
        totalPrice: totalPrice,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );
      await loadMyOrdersAsBuyer();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Farmer: অর্ডার status আপডেট করো ─────────────────────
  // FIX: isFarmer parameter — কে call করছে তার ভিত্তিতে সঠিক list reload করো
  // Farmer accept/reject/deliver → isFarmer: true (default)
  // Buyer cancel → isFarmer: false
  Future<bool> updateStatus(
      String orderId,
      String status, {
        bool isFarmer = true,
      }) async {
    _error = null;
    try {
      await _service.updateOrderStatus(orderId, status);
      if (isFarmer) {
        await loadIncomingOrdersAsFarmer();
      } else {
        await loadMyOrdersAsBuyer();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Buyer: অর্ডার বাতিল করো ──────────────────────────────
  // FIX: আগে cancelOrder ছিল না — buyer cancel করতে পারত না
  Future<bool> cancelOrder(String orderId) async {
    _error = null;
    try {
      await _service.updateOrderStatus(orderId, 'cancelled');
      await loadMyOrdersAsBuyer();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}