import 'package:flutter/foundation.dart';
import 'package:veridian/models/payment.dart';
import 'package:veridian/services/api_client.dart';

class PaymentService extends ChangeNotifier {
  List<Payment> _payments = [];
  List<Brand> _brands = [];

  List<Payment> get payments => _payments;
  List<Brand> get brands => _brands;
  int get unreadCount => _payments.where((payment) => !payment.isRead).length;

  Future<void> loadPayments() async {
    try {
      final response = await ApiClient.get('/notifications');
      if (response is List) {
        _payments = response.map((json) => Payment.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading payments: $e');
    }
  }

  Future<void> loadBrands() async {
    if (_brands.isNotEmpty) return;
    try {
      final response = await ApiClient.get('/catalog/brands');
      if (response is List) {
        _brands = response.map((json) => Brand.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading brands: $e');
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    try {
      await ApiClient.post('/notifications/read-all');
      await loadPayments();
    } catch (e) {
      debugPrint('Error marking payments as read: $e');
    }
  }

  Future<bool> purchase({
    required String accountId,
    required String brand,
    required double price,
  }) async {
    try {
      await ApiClient.post('/purchases', body: {
        'accountId': accountId,
        'brand': brand,
        'price': price,
      });
      await loadPayments();
      return true;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }
}
