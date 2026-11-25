double _toDouble(dynamic value) => (value as num).toDouble();

List<T> _list<T>(dynamic json, T Function(Map<String, dynamic>) parse) =>
    (json as List).map((item) => parse(item as Map<String, dynamic>)).toList();

class SavingsGoal {
  final double amount;
  final double savedAmount;

  final String targetMonth;

  const SavingsGoal({
    required this.amount,
    required this.savedAmount,
    required this.targetMonth,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        amount: _toDouble(json['amount']),
        savedAmount: _toDouble(json['savedAmount']),
        targetMonth: json['targetMonth'] as String,
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'savedAmount': savedAmount,
        'targetMonth': targetMonth,
      };
}

class AssistantProfile {
  final double? salary;
  final bool anomalyAlerts;
  final Map<String, double> categoryLimits;
  final SavingsGoal? goal;

  const AssistantProfile({
    this.salary,
    this.anomalyAlerts = false,
    this.categoryLimits = const {},
    this.goal,
  });

  factory AssistantProfile.fromJson(Map<String, dynamic> json) =>
      AssistantProfile(
        salary: (json['salary'] as num?)?.toDouble(),
        anomalyAlerts: json['anomalyAlerts'] as bool,
        categoryLimits: (json['categoryLimits'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, _toDouble(value))),
        goal: json['goal'] == null
            ? null
            : SavingsGoal.fromJson(json['goal'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'salary': salary,
        'anomalyAlerts': anomalyAlerts,
        'categoryLimits': categoryLimits,
        'goal': goal?.toJson(),
      };
}

class CategorySpend {
  final String category;
  final double amount;
  final double percent;

  const CategorySpend(this.category, this.amount, this.percent);

  factory CategorySpend.fromJson(Map<String, dynamic> json) => CategorySpend(
        json['category'] as String,
        _toDouble(json['amount']),
        _toDouble(json['percent']),
      );
}

class Subscription {
  final String brand;
  final double price;
  final DateTime nextChargeDate;
  final bool overdue;

  const Subscription(this.brand, this.price, this.nextChargeDate, this.overdue);

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        json['brand'] as String,
        _toDouble(json['price']),
        DateTime.parse(json['nextChargeDate'] as String),
        json['overdue'] as bool,
      );
}

class CategoryLimit {
  final String category;
  final double limit;
  final double spent;
  final double percent;
  final String status;

  const CategoryLimit(
      this.category, this.limit, this.spent, this.percent, this.status);

  factory CategoryLimit.fromJson(Map<String, dynamic> json) => CategoryLimit(
        json['category'] as String,
        _toDouble(json['limit']),
        _toDouble(json['spent']),
        _toDouble(json['percent']),
        json['status'] as String,
      );
}

class GoalProgress {
  final SavingsGoal goal;
  final int monthsLeft;
  final double requiredMonthly;
  final String status;

  const GoalProgress(
      this.goal, this.monthsLeft, this.requiredMonthly, this.status);

  factory GoalProgress.fromJson(Map<String, dynamic> json) => GoalProgress(
        SavingsGoal.fromJson(json),
        json['monthsLeft'] as int,
        _toDouble(json['requiredMonthly']),
        json['status'] as String,
      );
}

class AssistantSummary {
  final double salary;
  final double totalExpenses;
  final List<CategorySpend> categories;
  final List<CategorySpend> topCategories;
  final double previousSamePeriod;
  final double previousFull;
  final int cutoffDay;
  final double difference;
  final double? changePercent;
  final double transfersOut;
  final double salaryLeft;
  final double perDay;
  final int daysLeft;
  final double forecastExpenses;
  final double forecastLeft;
  final bool lowConfidence;
  final List<Subscription> subscriptions;
  final double subscriptionsMonthly;
  final double subscriptionsYearly;
  final List<CategoryLimit> limits;
  final GoalProgress? goal;

  const AssistantSummary({
    required this.salary,
    required this.totalExpenses,
    required this.categories,
    required this.topCategories,
    required this.previousSamePeriod,
    required this.previousFull,
    required this.cutoffDay,
    required this.difference,
    required this.changePercent,
    required this.transfersOut,
    required this.salaryLeft,
    required this.perDay,
    required this.daysLeft,
    required this.forecastExpenses,
    required this.forecastLeft,
    required this.lowConfidence,
    required this.subscriptions,
    required this.subscriptionsMonthly,
    required this.subscriptionsYearly,
    required this.limits,
    required this.goal,
  });

  factory AssistantSummary.fromJson(Map<String, dynamic> json) {
    final comparison = json['comparison'] as Map<String, dynamic>;
    final safe = json['safeToSpend'] as Map<String, dynamic>;
    final forecast = json['forecast'] as Map<String, dynamic>;
    final subscriptions = json['subscriptions'] as Map<String, dynamic>;
    final goal = json['goal'] as Map<String, dynamic>?;
    return AssistantSummary(
      salary: _toDouble(json['salary']),
      totalExpenses: _toDouble(json['totalExpenses']),
      categories: _list(json['categories'], CategorySpend.fromJson),
      topCategories: _list(json['topCategories'], CategorySpend.fromJson),
      previousSamePeriod: _toDouble(comparison['previousSamePeriod']),
      previousFull: _toDouble(comparison['previousFull']),
      cutoffDay: comparison['cutoffDay'] as int,
      difference: _toDouble(comparison['difference']),
      changePercent: (comparison['changePercent'] as num?)?.toDouble(),
      transfersOut: _toDouble(json['transfersOut']),
      salaryLeft: _toDouble(json['salaryLeft']),
      perDay: _toDouble(safe['perDay']),
      daysLeft: safe['daysLeft'] as int,
      forecastExpenses: _toDouble(forecast['expenses']),
      forecastLeft: _toDouble(forecast['left']),
      lowConfidence: forecast['lowConfidence'] as bool,
      subscriptions: _list(subscriptions['items'], Subscription.fromJson),
      subscriptionsMonthly: _toDouble(subscriptions['monthlyTotal']),
      subscriptionsYearly: _toDouble(subscriptions['yearlyTotal']),
      limits: _list(json['limits'], CategoryLimit.fromJson),
      goal: goal == null ? null : GoalProgress.fromJson(goal),
    );
  }
}

class PaymentWarning {
  final String code;
  final double? percent;
  final String? category;

  const PaymentWarning(this.code, this.percent, this.category);

  factory PaymentWarning.fromJson(Map<String, dynamic> json) => PaymentWarning(
        json['code'] as String,
        (json['percent'] as num?)?.toDouble(),
        json['category'] as String?,
      );
}

class AssistantMessage {
  final String text;
  final bool isUser;

  const AssistantMessage(this.text, {required this.isUser});

  Map<String, dynamic> toJson() => {
        'role': isUser ? 'user' : 'assistant',
        'text': text.length > 2000 ? text.substring(0, 2000) : text,
      };
}
