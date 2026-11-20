import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:veridian/models/card.dart';
import 'package:veridian/services/local_storage_service.dart';

class CardService extends ChangeNotifier {
  static const String _storageKey = 'cards';
  final _uuid = const Uuid();
  List<BankCard> _cards = [];

  List<BankCard> get cards => _cards;

  // Теперь принимаем userName
  Future<void> loadCards(String userId, String userName) async {
    try {
      final cardsJson = LocalStorageService.getJsonList(_storageKey);

      if (cardsJson == null || cardsJson.isEmpty) {
        await _initializeSampleData(userId, userName);
        return;
      }

      _cards = cardsJson
          .where((json) => json['userId'] == userId)
          .map((json) {
        try {
          final card = BankCard.fromJson(json);
          // ВАЖНО: Принудительно обновляем имя на карте на текущее
          return card.copyWith(cardHolderName: userName.toUpperCase());
        } catch (e) {
          debugPrint('Error parsing card: $e');
          return null;
        }
      })
          .whereType<BankCard>()
          .toList();

      if (_cards.isEmpty) {
        await _initializeSampleData(userId, userName);
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cards: $e');
      await _initializeSampleData(userId, userName);
    }
  }

  Future<void> _initializeSampleData(String userId, String userName) async {
    try {
      final now = DateTime.now();
      final holderName = userName.toUpperCase(); // Используем имя пользователя

      final sampleCards = [
        BankCard(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id',
          cardNumber: '4532123456789012',
          cardHolderName: holderName,
          cardType: 'Debit',
          expiryDate: '12/27',
          cvv: '123',
          spendingLimit: 5000.0,
          createdAt: now.subtract(const Duration(days: 730)),
          updatedAt: now,
        ),
        BankCard(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id-2',
          cardNumber: '5412345678901234',
          cardHolderName: holderName,
          cardType: 'Credit',
          expiryDate: '08/26',
          cvv: '456',
          spendingLimit: 10000.0,
          createdAt: now.subtract(const Duration(days: 365)),
          updatedAt: now,
        ),
      ];

      final allCardsJson = LocalStorageService.getJsonList(_storageKey) ?? [];
      allCardsJson.addAll(sampleCards.map((c) => c.toJson()).toList());
      await LocalStorageService.saveJsonList(_storageKey, allCardsJson);
      _cards = sampleCards;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing sample cards: $e');
    }
  }

  Future<bool> updateCard(BankCard card) async {
    try {
      final cardsJson = LocalStorageService.getJsonList(_storageKey) ?? [];
      final index = cardsJson.indexWhere((json) => json['id'] == card.id);

      if (index != -1) {
        cardsJson[index] = card.toJson();
        await LocalStorageService.saveJsonList(_storageKey, cardsJson);

        final localIndex = _cards.indexWhere((c) => c.id == card.id);
        if (localIndex != -1) {
          _cards[localIndex] = card;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating card: $e');
      return false;
    }
  }

  Future<bool> toggleCardBlock(String cardId) async {
    try {
      final card = _cards.firstWhere((c) => c.id == cardId);
      final updatedCard = card.copyWith(
        isBlocked: !card.isBlocked,
        updatedAt: DateTime.now(),
      );
      return await updateCard(updatedCard);
    } catch (e) {
      debugPrint('Error toggling card block: $e');
      return false;
    }
  }

  Future<bool> updateSpendingLimit(String cardId, double newLimit) async {
    try {
      final card = _cards.firstWhere((c) => c.id == cardId);
      final updatedCard = card.copyWith(
        spendingLimit: newLimit,
        updatedAt: DateTime.now(),
      );
      return await updateCard(updatedCard);
    } catch (e) {
      debugPrint('Error updating spending limit: $e');
      return false;
    }
  }

  List<BankCard> getCardsByAccount(String accountId) => _cards.where((card) => card.accountId == accountId).toList();
}