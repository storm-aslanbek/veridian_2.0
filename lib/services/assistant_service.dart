import 'package:flutter/foundation.dart';
import 'package:veridian/models/assistant.dart';
import 'package:veridian/services/api_client.dart';

class AssistantService extends ChangeNotifier {
  static const _checkTimeout = Duration(seconds: 4);
  static const _historyLimit = 10;

  String? _userId;
  AssistantProfile? _profile;
  AssistantSummary? _summary;
  final List<AssistantMessage> _messages = [];

  AssistantProfile? get profile => _profile;
  AssistantSummary? get summary => _summary;
  List<AssistantMessage> get messages => List.unmodifiable(_messages);

  void bindUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _profile = null;
    _summary = null;
    _messages.clear();
  }

  Future<void> loadProfile() async {
    final response = await ApiClient.get('/assistant/profile');
    _profile = AssistantProfile.fromJson(response);
    notifyListeners();
  }

  Future<void> saveProfile(AssistantProfile profile) async {
    final response =
        await ApiClient.put('/assistant/profile', body: profile.toJson());
    _profile = AssistantProfile.fromJson(response);
    _summary = null;
    notifyListeners();
  }

  Future<void> analyze() async {
    final response = await ApiClient.get('/assistant/summary');
    _summary = AssistantSummary.fromJson(response);
    notifyListeners();
  }

  Future<void> ask(String question, String language) async {
    final userId = _userId;
    final start =
        _messages.length > _historyLimit ? _messages.length - _historyLimit : 0;
    final response = await ApiClient.post('/assistant/chat', body: {
      'message': question,
      'language': language,
      'history': _messages.sublist(start).map((m) => m.toJson()).toList(),
    });
    if (userId != _userId) return;
    _messages.add(AssistantMessage(question, isUser: true));
    _messages.add(AssistantMessage(response['reply'] as String, isUser: false));
    notifyListeners();
  }

  Future<List<PaymentWarning>> check({
    required String kind,
    required double amount,
    required String accountId,
    String? brand,
  }) async {
    try {
      final response = await ApiClient.post('/assistant/check', body: {
        'kind': kind,
        'amount': amount,
        'accountId': accountId,
        'brand': brand,
      }).timeout(_checkTimeout);
      return (response['warnings'] as List)
          .map((json) => PaymentWarning.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Assistant check skipped: $e');
      return const [];
    }
  }
}
