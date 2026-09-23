import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(settings);
  }
  
  Future<void> checkRecurringPayments(List<RecurringPayment> payments) async {
    final now = DateTime.now();
    
    for (int i = 0; i < payments.length; i++) {
      final payment = payments[i];
      if (!payment.isActive) continue;
      
      final nextDate = payment.nextDate;
      if (nextDate == null) continue;
      
      // Проверяем: платёж сегодня или завтра?
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(Duration(days: 1));
      final paymentDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
      
      if (paymentDate == today || paymentDate == tomorrow) {
        final type = payment.isIncome ? 'доход' : 'платёж';
        final when = paymentDate == today ? 'Сегодня' : 'Завтра';
        
        await _showNotification(
          id: i + 1000,
          title: payment.name,
          body: '$when $type: ${payment.amount} ₽',
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