import 'package:flutter/foundation.dart';
import 'package:veridian/models/search_result.dart';
import 'package:veridian/services/api_client.dart';

class ShoppingService extends ChangeNotifier {
  List<SearchResult> _results = [];
  bool _isLoading = false;
  String? _error;

  List<SearchResult> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) return;

    _isLoading = true;
    _error = null;
    _results = []; // Очищаем старое
    notifyListeners();

    try {
      // Запрос на наш сервер, который проксирует на assau-tander.online
      final response = await ApiClient.get('/shopping/search?query=$query');

      if (response is List) {
        _results = response.map((json) => SearchResult.fromJson(json)).toList();
      } else {
        _error = "Некорректный ответ сервера";
      }
    } catch (e) {
      debugPrint('Shopping search error: $e');
      _error = 'Не удалось выполнить поиск. Проверьте соединение.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _results = [];
    _error = null;
    notifyListeners();
  }
}