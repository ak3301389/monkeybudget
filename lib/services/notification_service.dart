import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Запрос разрешения на уведомления (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Проверяет все платежи и показывает уведомления
  /// для тех, что наступают сегодня или завтра.
  Future<void> checkPayments(List<Payment> payments) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final payment in payments) {
      if (payment.status != 'pending') continue;

      final due = payment.dueDate;
      final paymentDate = DateTime(due.year, due.month, due.day);

      if (paymentDate == today || paymentDate == tomorrow) {
        final type = payment.isIncome ? 'доход' : 'платёж';
        final when = paymentDate == today ? 'Сегодня' : 'Завтра';

        await _showNotification(
          id: payment.id.hashCode,
          title: payment.name,
          body: '$when $type: ${payment.amount.toStringAsFixed(2)} ₽',
        );
      }
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'recurring_payments',
      'Регулярные платежи',
      channelDescription: 'Напоминания о регулярных платежах',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
  }
}
