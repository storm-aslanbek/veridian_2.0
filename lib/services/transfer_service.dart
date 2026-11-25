import 'package:flutter/foundation.dart';
import 'package:veridian/models/transfer_recipient.dart';
import 'package:veridian/services/api_client.dart';

class TransferService extends ChangeNotifier {
  List<TransferRecipient> _recipients = [];

  List<TransferRecipient> get recipients => _recipients;

  // Хелпер для очистки номера (ТОЧНО ТАКОЙ ЖЕ, КАК В USER SERVICE)
  String _formatPhoneForServer(String rawPhone) {
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');

    // Если начинается с 8, меняем на 7
    if (digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    }
    // Если 10 цифр, добавляем 7
    if (digits.length == 10) {
      digits = '7$digits';
    }

    // Если начинается с 7, оставляем как есть
    return digits;
  }

  Future<void> loadRecipients(String userId) async {
    try {
      final response = await ApiClient.get('/recipients');
      if (response is List) {
        _recipients =
            response.map((json) => TransferRecipient.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading recipients: $e');
    }
  }

  // Поиск пользователя (ИСПРАВЛЕНО)
  Future<Map<String, String>?> searchUserByPhone(String phone) async {
    try {
      final cleanPhone =
          _formatPhoneForServer(phone); // Чистим номер перед отправкой

      final response = await ApiClient.post('/users/search', body: {
        'phone': cleanPhone,
      });

      if (response != null) {
        return {
          'firstName': response['firstName'],
          'surname': response['surname'],
          'patronymic': response['patronymic'] ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('User search failed: $e');
      return null;
    }
  }

  // Перевод по номеру (ИСПРАВЛЕНО)
  Future<bool> performPhoneTransfer({
    required String sourceAccountId,
    required String phoneNumber,
    required double amount,
    String? description,
  }) async {
    try {
      final cleanPhone = _formatPhoneForServer(phoneNumber); // Чистим номер

      await ApiClient.post('/transfers/phone', body: {
        'accountId': sourceAccountId,
        'phoneNumber': cleanPhone,
        'amount': amount,
        'description': description,
      });
      return true;
    } catch (e) {
      debugPrint('Phone Transfer failed: $e');
      return false;
    }
  }

  Future<bool> performCardTransfer({
    required String sourceAccountId,
    required String targetCardNumber,
    required double amount,
    String? description,
  }) async {
    try {
      await ApiClient.post('/transfers/card', body: {
        'accountId': sourceAccountId,
        'cardNumber': targetCardNumber,
        'amount': amount,
        'description': description,
      });
      return true;
    } catch (e) {
      debugPrint('Card Transfer failed: $e');
      return false;
    }
  }

  Future<bool> addRecipient(TransferRecipient recipient) async {
    try {
      final response =
          await ApiClient.post('/recipients', body: recipient.toJson());
      final newRecipient = TransferRecipient.fromJson(response);
      _recipients.add(newRecipient);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding recipient: $e');
      return false;
    }
  }
}
