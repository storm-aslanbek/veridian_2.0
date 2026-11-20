import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:veridian/models/transaction.dart';
import 'package:veridian/services/local_storage_service.dart';

class TransactionService extends ChangeNotifier {
  static const String _storageKey = 'transactions';
  final _uuid = const Uuid();
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  Future<void> loadTransactions(String userId) async {
    try {
      final transactionsJson = LocalStorageService.getJsonList(_storageKey);

      if (transactionsJson == null || transactionsJson.isEmpty) {
        await _initializeSampleData(userId);
        return;
      }

      _transactions = transactionsJson
          .where((json) => json['userId'] == userId)
          .map((json) {
        try {
          return Transaction.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing transaction: $e');
          return null;
        }
      })
          .whereType<Transaction>()
          .toList();

      // Сортировка: сначала новые
      _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      if (_transactions.isEmpty) {
        await _initializeSampleData(userId);
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      await _initializeSampleData(userId);
    }
  }

  Future<void> _initializeSampleData(String userId) async {
    try {
      final now = DateTime.now();

      // === АДАПТИРОВАННЫЕ ДАННЫЕ ДЛЯ КАЗАХСТАНА ===
      final sampleTransactions = [
        // 1. Коммуналка (свежая)
        Transaction(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id',
          type: 'debit',
          category: 'Utilities', // Локализация переведет как "Коммуналка"
          amount: 14500.00,
          currency: 'KZT',
          recipient: 'ALSECO', // Алсеко
          description: 'Квитанция за квартиру',
          status: 'completed',
          transactionDate: now.subtract(const Duration(hours: 2)),
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
        // 2. Продукты
        Transaction(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id',
          type: 'debit',
          category: 'Food', // "Еда"
          amount: 8750.00,
          currency: 'KZT',
          recipient: 'Magnum Cash & Carry',
          description: 'Продукты',
          status: 'completed',
          transactionDate: now.subtract(const Duration(days: 1)),
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        // 3. Зарплата
        Transaction(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id',
          type: 'credit',
          category: 'Salary', // "Зарплата"
          amount: 350000.00,
          currency: 'KZT',
          recipient: 'ТОО "Veridian Group"',
          description: 'Заработная плата',
          status: 'completed',
          transactionDate: now.subtract(const Duration(days: 2)),
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        // 4. Транспорт
        Transaction(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id',
          type: 'debit',
          category: 'Transport', // "Транспорт"
          amount: 1200.00,
          currency: 'KZT',
          recipient: 'Yandex Go',
          description: 'Поездка на работу',
          status: 'completed',
          transactionDate: now.subtract(const Duration(days: 3)),
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        // 5. Интернет/Связь
        Transaction(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id',
          type: 'debit',
          category: 'Utilities',
          amount: 6500.00,
          currency: 'KZT',
          recipient: 'Kazakhtelecom',
          description: 'Интернет дома',
          status: 'completed',
          transactionDate: now.subtract(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        // 6. Развлечения
        Transaction(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id',
          type: 'debit',
          category: 'Entertainment', // "Развлечения"
          amount: 2500.00,
          currency: 'KZT',
          recipient: 'Kinopark',
          description: 'Билеты в кино',
          status: 'completed',
          transactionDate: now.subtract(const Duration(days: 6)),
          createdAt: now.subtract(const Duration(days: 6)),
          updatedAt: now.subtract(const Duration(days: 6)),
        ),
        // 7. Онай (Транспорт)
        Transaction(
          id: _uuid.v4(),
          userId: userId,
          accountId: 'sample-account-id',
          type: 'debit',
          category: 'Transport',
          amount: 2000.00,
          currency: 'KZT',
          recipient: 'ONAY!',
          description: 'Пополнение карты',
          status: 'completed',
          transactionDate: now.subtract(const Duration(days: 7)),
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(days: 7)),
        ),
      ];

      final allTransactionsJson = LocalStorageService.getJsonList(_storageKey) ?? [];
      allTransactionsJson.addAll(sampleTransactions.map((t) => t.toJson()).toList());
      await LocalStorageService.saveJsonList(_storageKey, allTransactionsJson);
      _transactions = sampleTransactions;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing sample transactions: $e');
    }
  }

  Future<bool> addTransaction(Transaction transaction) async {
    try {
      final transactionsJson = LocalStorageService.getJsonList(_storageKey) ?? [];
      transactionsJson.add(transaction.toJson());
      await LocalStorageService.saveJsonList(_storageKey, transactionsJson);
      _transactions.insert(0, transaction);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      return false;
    }
  }

  List<Transaction> getTransactionsByAccount(String accountId) => _transactions.where((t) => t.accountId == accountId).toList();

  List<Transaction> getTransactionsByCategory(String category) => _transactions.where((t) => t.category == category).toList();

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) => _transactions.where((t) => t.transactionDate.isAfter(start) && t.transactionDate.isBefore(end)).toList();

  Map<String, double> getCategorySpending() {
    final Map<String, double> categoryTotals = {};
    for (var transaction in _transactions) {
      if (transaction.type == 'debit') {
        categoryTotals[transaction.category] = (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return categoryTotals;
  }
}