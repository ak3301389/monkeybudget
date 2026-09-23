// lib/services/migration_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_budget/models.dart';
import 'package:home_budget/payment_schedule.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Миграция старых регулярных платежей в новую структуру
  Future<void> migrateRecurringPayments() async {
    try {
      print('🔄 Начинаем миграцию регулярных платежей...');
      
      // 1. Получаем все старые регулярные платежи
      final recurringSnapshot = await _firestore
          .collection('recurring')
          .get();
      
      if (recurringSnapshot.docs.isEmpty) {
        print('ℹ️ Нет старых регулярных платежей для миграции');
        return;
      }

      print('📊 Найдено ${recurringSnapshot.docs.length} старых платежей');
      
      int migratedCount = 0;
      int errorCount = 0;

      // 2. Проходим по каждому платежу
      for (var doc in recurringSnapshot.docs) {
        try {
          final oldData = doc.data();
          final oldPayment = _parseOldPayment(doc.id, oldData);
          
          if (oldPayment != null) {
            // 3. Конвертируем в новую структуру
            final newPayment = _convertToNewPayment(oldPayment);
            
            // 4. Сохраняем в новую коллекцию
            await _firestore
                .collection('payments')
                .doc(newPayment.id)
                .set(newPayment.toJson());
            
            migratedCount++;
            print('✅ Мигрирован: ${oldPayment.name}');
          }
        } catch (e) {
          errorCount++;
          print('❌ Ошибка миграции документа ${doc.id}: $e');
        }
      }

      print('🎉 Миграция завершена!');
      print('✅ Успешно: $migratedCount');
      print('❌ Ошибок: $errorCount');
      
    } catch (e) {
      print('❌ Критическая ошибка миграции: $e');
      rethrow;
    }
  }

  // Парсим старый платеж
  Payment? _parseOldPayment(String id, Map<String, dynamic> data) {
    try {
      // Определяем тип платежа (доход или расход)
      final isIncome = data['isIncome'] ?? false;
      
      // Получаем счета
      String fromAccountId = data['fromAccountId'] ?? '';
      String toAccountId = data['toAccountId'] ?? '';
      
      // Если счет не указан, ищем по категории или используем первый доступный
      if (fromAccountId.isEmpty && !isIncome) {
        // Для расходов пробуем найти счет по категории
        final category = data['category'] ?? '';
        if (category.isNotEmpty) {
          // Здесь можно добавить логику поиска счета по категории
          // Пока используем заглушку
          fromAccountId = 'account_default';
        }
      }
      
      if (toAccountId.isEmpty && isIncome) {
        toAccountId = 'account_default';
      }

      // Создаем график на основе частоты
      final frequency = data['frequency'] ?? 'monthly';
      final startDate = data['startDate'] != null 
          ? DateTime.parse(data['startDate']) 
          : DateTime.now();
      
      // Определяем количество платежей (по умолчанию 12)
      final count = data['scheduleCount'] ?? 12;

      final schedule = PaymentSchedule.fromPattern(
        startDate: startDate,
        frequency: _convertFrequency(frequency),
        count: count,
      );

      return Payment(
        id: id, // Сохраняем старый ID
        name: data['name'] ?? 'Без названия',
        amount: (data['amount'] ?? 0).toDouble(),
        isIncome: isIncome,
        category: data['category'] ?? 'Другое',
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        schedule: schedule,
        isPaid: data['isPaid'] ?? false,
      );
    } catch (e) {
      print('⚠️ Ошибка парсинга платежа $id: $e');
      return null;
    }
  }

  // Конвертируем старую частоту в новый формат
  String _convertFrequency(String oldFrequency) {
    switch (oldFrequency) {
      case 'daily':
        return 'daily';
      case 'weekly':
        return 'weekly';
      case 'biweekly':
        return 'biweekly';
      case 'monthly':
        return 'monthly';
      case 'yearly':
        return 'yearly';
      default:
        return 'monthly';
    }
  }

  // Конвертируем старый платеж в новый
  Payment _convertToNewPayment(Payment oldPayment) {
    // Если нужно изменить структуру, делаем это здесь
    return oldPayment;
  }

  // Проверка наличия дубликатов
  Future<void> checkDuplicates() async {
    try {
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .get();
      
      final recurringSnapshot = await _firestore
          .collection('recurring')
          .get();

      print('📊 Проверка дубликатов:');
      print('   payments: ${paymentsSnapshot.docs.length}');
      print('   recurring: ${recurringSnapshot.docs.length}');

      // Проверяем, есть ли уже мигрированные платежи
      final paymentIds = paymentsSnapshot.docs.map((d) => d.id).toSet();
      final recurringIds = recurringSnapshot.docs.map((d) => d.id).toSet();
      
      final duplicates = paymentIds.intersection(recurringIds);
      
      if (duplicates.isNotEmpty) {
        print('⚠️ Найдены дубликаты (${duplicates.length}):');
        duplicates.forEach((id) => print('   - $id'));
        print('💡 Рекомендуется удалить дубликаты из payments перед миграцией');
      } else {
        print('✅ Дубликатов не найдено');
      }
    } catch (e) {
      print('❌ Ошибка проверки дубликатов: $e');
    }
  }

  // Очистка всех мигрированных платежей (для отката)
  Future<void> rollbackMigration() async {
    try {
      print('🔄 Откат миграции...');
      
      // Получаем все платежи, которые были мигрированы
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .get();
      
      if (paymentsSnapshot.docs.isEmpty) {
        print('ℹ️ Нет платежей для отката');
        return;
      }

      print('📊 Найдено ${paymentsSnapshot.docs.length} платежей');
      
      // Удаляем все платежи (осторожно!)
      final batch = _firestore.batch();
      for (var doc in paymentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      print('✅ Откат выполнен! Удалено ${paymentsSnapshot.docs.length} платежей');
    } catch (e) {
      print('❌ Ошибка отката: $e');
      rethrow;
    }
  }
}