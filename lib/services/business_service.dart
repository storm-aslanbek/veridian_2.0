import 'package:flutter/foundation.dart';
import 'package:veridian/models/business_info.dart';
import 'package:veridian/services/api_client.dart';

class BusinessService extends ChangeNotifier {
  BusinessInfo? _result;
  bool _isLoading = false;
  String? _error;

  BusinessInfo? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkBusiness(String bin) async {
    if (bin.trim().length != 12) {
      _error = "БИН должен состоять из 12 цифр";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      // Запрос на наш сервер
      final response = await ApiClient.get('/business/check?bin=$bin');

      if (response != null) {
        _result = BusinessInfo.fromJson(response);
      }
    } catch (e) {
      debugPrint('Business check error: $e');
      _error = 'Не удалось найти информацию по этому БИН. Проверьте данные.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}