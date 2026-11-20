import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
          title: Text(uiText('Платежи'),
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildGridItem(
              context, Icons.phone_android, uiText('Мобильная\nсвязь')),
          _buildGridItem(
              context, Icons.lightbulb_outline, uiText('Коммуналка')),
          _buildGridItem(context, Icons.wifi, uiText('Интернет')),
          _buildGridItem(context, Icons.school, uiText('Образование')),
          _buildGridItem(context, Icons.directions_car, uiText('Транспорт')),
          _buildGridItem(context, Icons.more_horiz, uiText('Прочее')),
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 30),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
