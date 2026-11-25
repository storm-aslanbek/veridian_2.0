import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/localization_provider.dart';
import '../services/ui_strings.dart';
import '../services/user_service.dart';
import 'auth/login_screen.dart';

import 'package:veridian/screens/home_dashboard.dart';
import 'package:veridian/screens/transfer_screen.dart';
import 'package:veridian/screens/bill_payment_screen.dart';
import 'package:veridian/screens/messages_screen.dart';
import 'package:veridian/screens/services_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<UserService>().isAuthenticated) {
      return const LoginScreen();
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (final (index, screen) in [
            const HomeDashboard(),
            TransferScreen(onHome: () => setState(() => _selectedIndex = 0)),
            const BillPaymentScreen(),
            const MessagesScreen(),
            const ServicesScreen(),
          ].indexed)
            AnimatedOpacity(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              opacity: index == _selectedIndex ? 1 : 0,
              child: screen,
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final language = context.watch<LocalizationProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  context, Icons.home_rounded, language.translate("home"), 0),
              _buildNavItem(
                  context, Icons.swap_horiz_outlined, uiText('Переводы'), 1),
              _buildNavItem(
                  context, Icons.payments_outlined, uiText('Платежи'), 2),
              _buildNavItem(context, Icons.mail_outline_rounded,
                  uiText('Сообщения'), 3),
              _buildNavItem(
                  context, Icons.grid_view_outlined, uiText('Сервисы'), 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
        child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
