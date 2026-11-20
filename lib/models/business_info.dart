class BusinessInfo {
  final List<String>? bin;
  final List<String>? nameRu;
  final String? customerLegalAddress;
  final String? customerBankNameRu;
  final dynamic fullyPaid; // Может быть int или double
  final dynamic averagePaymentTime;
  final dynamic averageSigningTime;
  final dynamic terminatedContracts;
  final dynamic totalRating;

  BusinessInfo({
    this.bin,
    this.nameRu,
    this.customerLegalAddress,
    this.customerBankNameRu,
    this.fullyPaid,
    this.averagePaymentTime,
    this.averageSigningTime,
    this.terminatedContracts,
    this.totalRating,
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    // Вспомогательная функция для безопасности
    List<String>? parseToList(dynamic value) {
      if (value == null) return null;
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) return [value]; // Если пришла строка, кладем её в список
      return [value.toString()];
    }

    // Безопасное приведение к double/num
    dynamic parseNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
      return null;
    }

    return BusinessInfo(
      bin: parseToList(json['bin']),
      nameRu: parseToList(json['nameRu']),
      customerLegalAddress: json['customerLegalAddress']?.toString(),
      customerBankNameRu: json['customerBankNameRu']?.toString(),
      fullyPaid: json['fullyPaid'],
      averagePaymentTime: json['averagePaymentTime'],
      averageSigningTime: json['averageSigningTime'],
      terminatedContracts: json['terminated_contracts'],
      totalRating: parseNum(json['total_rating']), // Защита для рейтинга
    );
  }

  // Геттеры для удобного отображения (берем первый элемент из списка или дефолт)
  String get binString => (bin != null && bin!.isNotEmpty) ? bin!.first : "Не указан";
  String get nameString => (nameRu != null && nameRu!.isNotEmpty) ? nameRu!.first : "Название не найдено";
}