import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart' as models;
import 'storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackupService {
  final StorageService storageService;
  final _firestore = FirebaseFirestore.instance;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  BackupService(this.storageService);

  // Сохранение на телефон
  Future<String> saveToPhone() async {
    try {
      final data = storageService.exportAllData();
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(data);
      return file.path;
    } catch (e) {
      debugPrint('Save to phone error: $e');
      return '';
    }
  }

  // Сохранение в Firebase
  Future<bool> saveToFirebase() async {
    try {
      final data = storageService.exportAllData();
      final parsed = jsonDecode(data);

      final categories = [
        ...(parsed['expense_categories'] as List? ?? [])
            .map((c) => c['name'] as String)
            .toList(),
        ...(parsed['income_categories'] as List? ?? [])
            .map((c) => c['name'] as String)
            .toList(),
      ];

      final syncCode = _generateSyncCode();

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('backup')
          .set({
        'syncCode': syncCode,
        'transactions': parsed['transactions'] ?? [],
        'accounts': parsed['accounts'] ?? [],
        'categories': categories,
        'subcategories': parsed['expense_subcategories'] ?? [],
        'payments': parsed['payments'] ?? [],
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Firebase save error: $e');
      return false;
    }
  }

  String _generateSyncCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final part1 =
        List.generate(3, (_) => chars[random.nextInt(chars.length)]).join();
    final part2 =
        List.generate(3, (_) => chars[random.nextInt(chars.length)]).join();
    final part3 =
        List.generate(3, (_) => chars[random.nextInt(chars.length)]).join();
    return '$part1-$part2-$part3';
  }

  // Загрузка из Firebase
  Future<bool> restoreFromFirebase() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('backup')
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        debugPrint('=== RESTORE DEBUG ===');

        // Accounts
        try {
          final accounts = (data['accounts'] as List? ?? []);
          debugPrint('Accounts count: ${accounts.length}');
          if (accounts.isNotEmpty) {
            final list = accounts
                .where((a) => a is Map)
                .map((a) =>
                    models.Account.fromJson(Map<String, dynamic>.from(a)))
                .toList();
            storageService.saveAccounts(list);
          }
        } catch (e) {
          debugPrint('Accounts error: $e');
        }

        // Transactions
        try {
          final transactions = (data['transactions'] as List? ?? []);
          debugPrint('Transactions count: ${transactions.length}');
          if (transactions.isNotEmpty) {
            final list = transactions
                .where((t) => t is Map)
                .map((t) =>
                    models.Transaction.fromJson(Map<String, dynamic>.from(t)))
                .toList();
            storageService.saveTransactions(list);
          }
        } catch (e) {
          debugPrint('Transactions error: $e');
        }

        // Categories
        try {
          final categories = (data['categories'] as List? ?? [])
              .where((c) => c is String)
              .map((c) => c.toString())
              .toList();
          debugPrint('Categories count: ${categories.length}');
          if (categories.isNotEmpty) {
            final expense = categories
                .where((c) => ![
                      'Зарплата',
                      'Подработка',
                      'Дежурства',
                      'Подарок'
                    ].contains(c))
                .toList();
            final income = categories
                .where((c) => ['Зарплата', 'Подработка', 'Дежурства', 'Подарок']
                    .contains(c))
                .toList();

            if (expense.isNotEmpty) {
              storageService.saveExpenseCategories(expense
                  .map((c) => models.Category(c, Icons.category, '#607D8B'))
                  .toList());
            }
            if (income.isNotEmpty) {
              storageService.saveIncomeCategories(income
                  .map((c) => models.Category(c, Icons.work, '#4CAF50'))
                  .toList());
            }
          }
        } catch (e) {
          debugPrint('Categories error: $e');
        }

        // Subcategories
        try {
          final subcategories = (data['subcategories'] as List? ?? []);
          debugPrint('Subcategories count: ${subcategories.length}');
          if (subcategories.isNotEmpty) {
            final list = subcategories
                .where((s) => s is Map)
                .map((s) =>
                    models.SubCategory.fromJson(Map<String, dynamic>.from(s)))
                .toList();
            storageService.saveExpenseSubCategories(list);
          }
        } catch (e) {
          debugPrint('Subcategories error: $e');
        }

        // ===== ЗАГРУЗКА ПЛАТЕЖЕЙ =====
        try {
          final payments = (data['payments'] as List? ?? []);
          debugPrint('Payments count: ${payments.length}');
          if (payments.isNotEmpty) {
            final list = payments
                .where((p) => p is Map)
                .map((p) =>
                    models.Payment.fromJson(Map<String, dynamic>.from(p)))
                .toList();
            storageService.savePayments(list);
          }
        } catch (e) {
          debugPrint('Payments error: $e');
        }
        // ===== КОНЕЦ НОВОГО =====

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Firebase restore error: $e');
      return false;
    }
  }

  Future<bool> restoreByCode(String code) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('backup')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final storedCode = data['syncCode'] as String?;

        if (storedCode == code) {
          return await restoreFromFirebase();
        }
      }

      return false;
    } catch (e) {
      debugPrint('Restore by code error: $e');
      return false;
    }
  }

  // Восстановление из файла
  Future<bool> restoreFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final data = await file.readAsString();
      storageService.importAllData(data);
      return true;
    } catch (e) {
      debugPrint('Restore from file error: $e');
      return false;
    }
  }

  Future<String?> getSyncCode() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('backup')
          .get();
      if (doc.exists) {
        return doc.data()!['syncCode'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
