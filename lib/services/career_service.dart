import 'package:flutter/foundation.dart';
import 'package:veridian/models/job_opportunity.dart';
import 'package:veridian/services/api_client.dart';

class CareerService extends ChangeNotifier {
  List<JobOpportunity> _jobs = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  List<JobOpportunity> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSearched => _hasSearched;

  // Убрали employmentTypes, _selectedType и setFilter

  Future<void> searchJobs(String query) async {
    if (query.trim().isEmpty) return;

    _isLoading = true;
    _error = null;
    _jobs = [];
    _hasSearched = true;
    notifyListeners();

    try {
      // Просто передаем query, без фильтров
      final String endpoint = '/career/search?query=$query';

      debugPrint('🔍 CareerService: Запрос на $endpoint');

      final response = await ApiClient.get(endpoint);

      debugPrint('📦 CareerService: Ответ сервера: $response');

      if (response is List) {
        _jobs = response.map((json) => JobOpportunity.fromJson(json)).toList();
        debugPrint('✅ CareerService: Найдено ${_jobs.length} вакансий');
      } else {
        _error = "Сервер вернул не список: $response";
      }
    } catch (e, stacktrace) {
      debugPrint('❌ CareerService Error: $e');
      debugPrint('Stacktrace: $stacktrace');
      _error = 'Ошибка: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _jobs = [];
    _error = null;
    _hasSearched = false;
    notifyListeners();
  }
}