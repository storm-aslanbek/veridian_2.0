import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

double? parseAmount(String text) =>
    double.tryParse(text.replaceAll(' ', '').replaceAll(',', '.'));

class AmountField extends StatelessWidget {
  const AmountField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
        ],
        decoration: InputDecoration(labelText: label, suffixText: '₸'),
      );
}
