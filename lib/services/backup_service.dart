import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../models.dart' as models;
import 'storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackupService {
  final StorageService storageService;
  final _firestore = FirebaseFirestore.instance;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  BackupService(this.storageService);

  Future<String> saveToPhone() async {
    final data = storageService.exportAllData();
    final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';

    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(data);
      return file.path;
    } catch (_) {
      final extDir = await getExternalStorageDirectory();
      final fallbackDir = extDir ?? await getApplicationDocumentsDirectory();
      final file = File('${fallbackDir.path}/$fileName');
      await file.writeAsString(data);
      return file.path;
    }
  }

  // Сохранение в Firebase
  Future<bool> saveToFirebase() async {
    try {
      final data = storageService.exportAllData();
      final parsed = jsonDecode(data);

      final expenseCategoriesFull =
          (parsed['expense_categories'] as List? ?? []).toList();
      final incomeCategoriesFull =
          (parsed['income_categories'] as List? ?? []).toList();
      final transferCategoriesFull =
          (parsed['transfer_categories'] as List? ?? []).toList();

      String? syncCode = storageService.getString('sync_code');
      if (syncCode == null || syncCode.isEmpty) {
        syncCode = _generateSyncCode();
        storageService.setString('sync_code', syncCode);
      }

      final payload = {
        'syncCode': syncCode,
        'ownerId': _userId,
        'transactions': parsed['transactions'] ?? [],
        'accounts': parsed['accounts'] ?? [],
        'expense_categories': expenseCategoriesFull,
        'income_categories': incomeCategoriesFull,
        'transfer_categories': transferCategoriesFull,
        'subcategories': parsed['expense_subcategories'] ?? [],
        'expense_subcategories': parsed['expense_subcategories'] ?? [],
        'income_subcategories': parsed['income_subcategories'] ?? [],
        'transfer_subcategories': parsed['transfer_subcategories'] ?? [],
        'payments': parsed['payments'] ?? [],
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('backup')
          .set(payload);

      await _firestore.collection('sync_codes').doc(syncCode).set(payload);

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

  Future<bool> restoreFromFirebase() async {
    try {
      final savedCode = storageService.getString('sync_code');
      if (savedCode != null && savedCode.isNotEmpty) {
        final codeDoc =
            await _firestore.collection('sync_codes').doc(savedCode).get();
        if (codeDoc.exists) {
          await _applyCloudData(codeDoc.data()!);
          return true;
        }
      }

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('backup')
          .get();

      if (doc.exists) {
        await _applyCloudData(doc.data()!);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Firebase restore error: $e');
      return false;
    }
  }

  Future<void> _applyCloudData(Map<String, dynamic> data) async {
    try {
      final accounts = (data['accounts'] as List? ?? []);
      if (accounts.isNotEmpty) {
        final list = accounts
            .whereType<Map>()
            .map((a) => models.Account.fromJson(Map<String, dynamic>.from(a)))
            .toList();
        storageService.saveAccounts(list);
      }
    } catch (e) {
      debugPrint('Accounts error: $e');
    }

    try {
      final transactions = (data['transactions'] as List? ?? []);
      if (transactions.isNotEmpty) {
        final list = transactions
            .whereType<Map>()
            .map((t) =>
                models.Transaction.fromJson(Map<String, dynamic>.from(t)))
            .toList();
        storageService.saveTransactions(list);
      }
    } catch (e) {
      debugPrint('Transactions error: $e');
    }

    try {
      if (data['expense_categories'] != null) {
        final list = (data['expense_categories'] as List)
            .whereType<Map>()
            .map((c) => models.Category.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        if (list.isNotEmpty) {
          storageService.saveExpenseCategories(list);
        }
      }
      if (data['income_categories'] != null) {
        final list = (data['income_categories'] as List)
            .whereType<Map>()
            .map((c) => models.Category.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        if (list.isNotEmpty) {
          storageService.saveIncomeCategories(list);
        }
      }
      if (data['transfer_categories'] != null) {
        final list = (data['transfer_categories'] as List)
            .whereType<Map>()
            .map((c) => models.Category.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        if (list.isNotEmpty) {
          storageService.setString('transfer_categories',
              jsonEncode(list.map((c) => c.toJson()).toList()));
        }
      }
      if (data['expense_categories'] == null && data['categories'] != null) {
        final categories = (data['categories'] as List? ?? [])
            .whereType<String>()
            .map((c) => c.toString())
            .toList();
        if (categories.isNotEmpty) {
          final expense = categories
              .where((c) => !['Зарплата', 'Подработка', 'Дежурства', 'Подарок']
                  .contains(c))
              .toList();
          final income = categories
              .where((c) => ['Зарплата', 'Подработка', 'Дежурства', 'Подарок']
                  .contains(c))
              .toList();
          if (expense.isNotEmpty) {
            storageService.saveExpenseCategories(expense
                .map((c) => models.Category(c, 'category', '#607D8B'))
                .toList());
          }
          if (income.isNotEmpty) {
            storageService.saveIncomeCategories(income
                .map((c) => models.Category(c, 'work', '#4CAF50'))
                .toList());
          }
        }
      }
    } catch (e) {
      debugPrint('Categories error: $e');
    }

    try {
      final expenseSubsRaw =
          (data['expense_subcategories'] ?? data['subcategories']) as List? ??
              [];
      if (expenseSubsRaw.isNotEmpty) {
        final list = expenseSubsRaw
            .whereType<Map>()
            .map((s) =>
                models.SubCategory.fromJson(Map<String, dynamic>.from(s)))
            .toList();
        storageService.saveExpenseSubCategories(list);
      }

      final incomeSubsRaw = (data['income_subcategories'] as List? ?? []);
      if (incomeSubsRaw.isNotEmpty) {
        final list = incomeSubsRaw
            .whereType<Map>()
            .map((s) =>
                models.SubCategory.fromJson(Map<String, dynamic>.from(s)))
            .toList();
        storageService.saveIncomeSubCategories(list);
      }

      final transferSubsRaw = (data['transfer_subcategories'] as List? ?? []);
      if (transferSubsRaw.isNotEmpty) {
        final list = transferSubsRaw
            .whereType<Map>()
            .map((s) =>
                models.SubCategory.fromJson(Map<String, dynamic>.from(s)))
            .toList();
        storageService.setString('transfer_subcategories',
            jsonEncode(list.map((s) => s.toJson()).toList()));
      }
    } catch (e) {
      debugPrint('Subcategories error: $e');
    }

    try {
      final payments = (data['payments'] as List? ?? []);
      if (payments.isNotEmpty) {
        final list = payments
            .whereType<Map>()
            .map((p) => models.Payment.fromJson(Map<String, dynamic>.from(p)))
            .toList();
        storageService.savePayments(list);
      }
    } catch (e) {
      debugPrint('Payments error: $e');
    }
  }

  Future<bool> restoreByCode(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final doc =
          await _firestore.collection('sync_codes').doc(cleanCode).get();

      if (doc.exists) {
        storageService.setString('sync_code', cleanCode);
        await _applyCloudData(doc.data()!);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Restore by code error: $e');
      return false;
    }
  }

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
    final localCode = storageService.getString('sync_code');
    if (localCode != null && localCode.isNotEmpty) {
      return localCode;
    }
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('backup')
          .get();
      if (doc.exists) {
        final code = doc.data()!['syncCode'] as String?;
        if (code != null && code.isNotEmpty) {
          storageService.setString('sync_code', code);
        }
        return code;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
