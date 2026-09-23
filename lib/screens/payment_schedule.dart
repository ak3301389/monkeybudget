// payment_schedule.dart
class PaymentSchedule {
  final List<DateTime> dates;
  final int currentIndex;

  PaymentSchedule({
    required this.dates,
    this.currentIndex = 0,
  });

  DateTime? get nextDate => currentIndex < dates.length ? dates[currentIndex] : null;

  bool get isComplete => currentIndex >= dates.length;

  PaymentSchedule advance() {
    if (isComplete) return this;
    return PaymentSchedule(
      dates: dates,
      currentIndex: currentIndex + 1,
    );
  }

  // Создание графика по шаблону
  factory PaymentSchedule.fromPattern({
    required DateTime startDate,
    required String frequency, // 'daily', 'weekly', 'biweekly', 'monthly', 'yearly', 'custom'
    int interval = 1,
    int? dayOfWeek,
    int? dayOfMonth,
    int count = 12, // сколько платежей вперёд генерировать
  }) {
    final dates = <DateTime>[];
    DateTime current = startDate;

    for (int i = 0; i < count; i++) {
      dates.add(current);
      current = _addInterval(current, frequency, interval, dayOfWeek, dayOfMonth);
    }
    return PaymentSchedule(dates: dates);
  }

  static DateTime _addInterval(
    DateTime date,
    String frequency,
    int interval,
    int? dayOfWeek,
    int? dayOfMonth,
  ) {
    switch (frequency) {
      case 'daily':
        return date.add(Duration(days: interval));
      case 'weekly':
        final targetDay = dayOfWeek ?? date.weekday;
        var daysUntil = (targetDay - date.weekday) % 7;
        if (daysUntil <= 0) daysUntil += 7;
        return date.add(Duration(days: daysUntil));
      case 'biweekly':
        return date.add(Duration(days: 14));
      case 'monthly':
        final targetDay = dayOfMonth ?? date.day;
        DateTime next = DateTime(date.year, date.month, targetDay);
        if (next.isBefore(date) || next.day != targetDay) {
          next = DateTime(date.year, date.month + 1, targetDay);
        }
        return next;
      case 'yearly':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date.add(Duration(days: interval));
    }
  }

  // Сериализация для хранения
  Map<String, dynamic> toJson() => {
    'dates': dates.map((d) => d.toIso8601String()).toList(),
    'currentIndex': currentIndex,
  };

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) => PaymentSchedule(
    dates: (json['dates'] as List).map((d) => DateTime.parse(d)).toList(),
    currentIndex: json['currentIndex'] ?? 0,
  );
}