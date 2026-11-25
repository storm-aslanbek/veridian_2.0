import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/bank_account.dart';
import '../../models/card.dart';
import '../../models/transaction.dart';
import '../../models/user.dart';
import '../../services/account_service.dart';
import '../../services/bill_service.dart';
import '../../services/card_service.dart';
import '../../services/transaction_service.dart';
import '../../services/transfer_service.dart';
import '../../services/user_service.dart';
import '../app_wrapper.dart';

bool isBankingDemo(BuildContext context) =>
    context.read<DemoAccounts?>() != null;

class DemoSession extends StatefulWidget {
  const DemoSession({super.key});

  @override
  State<DemoSession> createState() => _DemoSessionState();
}

class _DemoSessionState extends State<DemoSession> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DemoAccounts()),
          ChangeNotifierProvider<UserService>(create: (_) => _DemoUser()),
          ChangeNotifierProvider<TransactionService>(
              create: (_) => _DemoHistory()),
          ChangeNotifierProvider<CardService>(create: (_) => _DemoCards()),
          ChangeNotifierProvider<BillService>(create: (_) => BillService()),
          ChangeNotifierProvider<TransferService>(
              create: (_) => TransferService()),
        ],
        child: Builder(
            builder: (context) => ChangeNotifierProvider<AccountService>.value(
                  value: context.read<DemoAccounts>(),
                  child: NavigatorPopHandler<void>(
                    onPopWithResult: (_) => _navigator.currentState!.pop(),
                    child: Navigator(
                      key: _navigator,
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                          builder: (_) => const AppWrapper()),
                    ),
                  ),
                )),
      );
}

const _userId = 'veridian-demo';
final _today = DateTime.now();

class _DemoUser extends UserService {
  @override
  User get currentUser => User(
      id: _userId,
      firstName: 'Гость',
      surname: '',
      iin: '',
      phone: '',
      createdAt: _today,
      updatedAt: _today);
  @override
  bool get isAuthenticated => true;
  @override
  Future<void> logout() async {}
}

class DemoAccounts extends AccountService {
  static BankAccount _account(
          String id, String number, String name, double balance) =>
      BankAccount(
        id: id,
        userId: _userId,
        accountNumber: number,
        accountName: name,
        accountType: 'current',
        currency: 'KZT',
        balance: balance,
        createdAt: _today,
        updatedAt: _today,
      );
  final _data = [
    _account('demo-card', 'DEMO9012', 'Повседневная карта', 140000),
    _account('demo-reserve', 'DEMO4488', 'Резервный счёт', 36000),
  ];
  @override
  List<BankAccount> get accounts => List.unmodifiable(_data);
  @override
  Future<void> loadAccounts(String userId) async {}

  // Demo operations are held in memory for the lifetime of the preview.
  bool apply(BuildContext context, String accountId, double delta,
      {String? destinationId,
      required String description,
      required String category}) {
    final index = _data.indexWhere((a) => a.id == accountId);
    final target = destinationId == null
        ? -1
        : _data.indexWhere((a) => a.id == destinationId);
    if (index < 0 ||
        !delta.isFinite ||
        delta == 0 ||
        _data[index].balance + delta < 0 ||
        (destinationId != null &&
            (target < 0 || target == index || delta > 0))) {
      return false;
    }
    _data[index] = _data[index].copyWith(balance: _data[index].balance + delta);
    if (target >= 0) {
      _data[target] =
          _data[target].copyWith(balance: _data[target].balance - delta);
    }
    final now = DateTime.now();
    context.read<TransactionService>().addTransaction(Transaction(
          id: const Uuid().v4(),
          userId: _userId,
          accountId: accountId,
          type: delta > 0 ? 'credit' : 'debit',
          category: category,
          amount: delta.abs(),
          currency: 'KZT',
          recipient: description,
          status: 'completed',
          transactionDate: now,
          createdAt: now,
          updatedAt: now,
        ));
    notifyListeners();
    return true;
  }
}

class _DemoHistory extends TransactionService {
  final _items = [
    for (final (id, category, recipient, amount) in [
      ('groceries', 'Food', 'Продукты', 12800.0),
      ('transport', 'Transport', 'Транспорт', 2900.0),
      ('entertainment', 'Entertainment', 'Кино', 4300.0),
    ])
      Transaction(
          id: id,
          userId: _userId,
          accountId: 'demo-card',
          type: 'debit',
          category: category,
          amount: amount,
          currency: 'KZT',
          recipient: recipient,
          status: 'completed',
          transactionDate: _today,
          createdAt: _today,
          updatedAt: _today),
  ];
  @override
  List<Transaction> get transactions => List.unmodifiable(_items);
  @override
  Future<bool> addTransaction(Transaction transaction) async {
    _items.insert(0, transaction);
    notifyListeners();
    return true;
  }
}

class _DemoCards extends CardService {
  final _items = [
    BankCard(
        id: 'demo-visa',
        userId: _userId,
        accountId: 'demo-card',
        cardNumber: '4000000000009012',
        cardHolderName: 'VERIDIAN DEMO',
        cardType: 'Debit',
        expiryDate: '10/31',
        cvv: '000',
        spendingLimit: 160000,
        createdAt: _today,
        updatedAt: _today),
  ];
  @override
  List<BankCard> get cards => List.unmodifiable(_items);
  @override
  Future<bool> toggleCardBlock(String cardId) async {
    final index = _items.indexWhere((card) => card.id == cardId);
    if (index < 0) return false;
    _items[index] = _items[index].copyWith(isBlocked: !_items[index].isBlocked);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateSpendingLimit(String cardId, double newLimit) async {
    final index = _items.indexWhere((card) => card.id == cardId);
    if (index < 0) return false;
    _items[index] = _items[index].copyWith(spendingLimit: newLimit);
    notifyListeners();
    return true;
  }
}
