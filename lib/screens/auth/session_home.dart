import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/account_service.dart';
import '../../services/bill_service.dart';
import '../../services/card_service.dart';
import '../../services/loan_service.dart';
import '../../services/transaction_service.dart';
import '../../services/transfer_service.dart';
import '../../services/user_service.dart';
import '../app_wrapper.dart';
import 'login_screen.dart';

class SessionHome extends StatefulWidget {
  const SessionHome({super.key});

  @override
  State<SessionHome> createState() => _SessionHomeState();
}

class _SessionHomeState extends State<SessionHome> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final user = context.read<UserService>().currentUser;
    if (user == null) return;
    await Future.wait([
      context.read<AccountService>().loadAccounts(user.id),
      context.read<CardService>().loadCards(user.id, user.fullName.trim()),
      context.read<TransactionService>().loadTransactions(user.id),
      context.read<BillService>().loadBills(user.id),
      context.read<LoanService>().loadLoans(user.id),
      context.read<TransferService>().loadRecipients(user.id),
    ]);
    if (mounted && context.read<UserService>().currentUser?.id == user.id) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<UserService>().isAuthenticated)
      return const LoginScreen();
    if (_ready) return const AppWrapper();
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
