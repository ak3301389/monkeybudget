// lib/services/migration_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Сервис миграции отключён — старые платежи удалены,
// новые создаются в формате PaymentSeries + Payment.
class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateRecurringPayments() async {
    // Ничего не делаем — миграция больше не нужна
    print('ℹ️ Миграция отключена — используется новый формат платежей');
  }

  Future<void> checkDuplicates() async {
    // Ничего не делаем
  }

  Future<void> rollbackMigration() async {
    // Ничего не делаем
  }
}
