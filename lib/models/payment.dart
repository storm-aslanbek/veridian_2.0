import 'package:veridian/services/ui_strings.dart';

class Brand {
  final String name;
  final String category;

  const Brand({required this.name, required this.category});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        name: json['name'] as String,
        category: json['category'] as String,
      );
}

enum MessageKind { purchase, transfer, salary }

class Payment {
  final String id;
  final String type;
  final DateTime date;
  final double price;
  final String counterparty;
  final String category;
  final bool isRead;

  const Payment({
    required this.id,
    required this.type,
    required this.date,
    required this.price,
    required this.counterparty,
    required this.category,
    required this.isRead,
  });

  bool get isIncome => type == 'transfer_in' || type == 'salary';

  MessageKind get kind => switch (type) {
        'transfer_in' || 'transfer_out' => MessageKind.transfer,
        'salary' => MessageKind.salary,
        _ => MessageKind.purchase,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        type: json['type'] as String,
        date: DateTime.parse(json['date'] as String),
        price: (json['price'] as num).toDouble(),
        counterparty: json['counterparty'] as String,
        category: json['category'] as String,
        isRead: json['isRead'] as bool,
      );
}

const brandCategories = [
  'entertainment',
  'food',
  'groceries',
  'services',
  'subscriptions',
];

String brandCategoryLabel(String category) => switch (category) {
      'entertainment' => uiText('Развлечения'),
      'food' => uiText('Еда'),
      'groceries' => uiText('Продукты'),
      'services' => uiText('Услуги'),
      'subscriptions' => uiText('Подписки'),
      _ => category,
    };
