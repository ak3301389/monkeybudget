import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class StorageService {
  final SharedPreferences prefs;
  
  StorageService(this.prefs);
  
  // Сохранение счетов
  void saveAccounts(List<Account> accounts) {
    final json = jsonEncode(accounts.map((a) => a.toJson()).toList());
    prefs.setString('accounts', json);
  }
  
  List<Account> loadAccounts() {
    final json = prefs.getString('accounts');
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((a) => Account.fromJson(a)).toList();
  }
  
  // Сохранение операций
  void saveTransactions(List<Transaction> transactions) {
    final json = jsonEncode(transactions.map((t) => t.toJson()).toList());
    prefs.setString('transactions', json);
  }
  
  List<Transaction> loadTransactions() {
    final json = prefs.getString('transactions');
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((t) => Transaction.fromJson(t)).toList();
  }
  
  // Сохранение категорий расходов
  void saveExpenseCategories(List<Category> categories) {
    final json = jsonEncode(categories.map((c) => c.toJson()).toList());
    prefs.setString('expense_categories', json);
  }
  
  List<Category> loadExpenseCategories() {
    final json = prefs.getString('expense_categories');
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((c) => Category.fromJson(c)).toList();
  }
  
  // Сохранение категорий доходов
  void saveIncomeCategories(List<Category> categories) {
    final json = jsonEncode(categories.map((c) => c.toJson()).toList());
    prefs.setString('income_categories', json);
  }
  
  List<Category> loadIncomeCategories() {
    final json = prefs.getString('income_categories');
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((c) => Category.fromJson(c)).toList();
  }
  
  // Сохранение подкатегорий расходов
  void saveExpenseSubCategories(List<SubCategory> subCategories) {
    final json = jsonEncode(subCategories.map((s) => s.toJson()).toList());
    prefs.setString('expense_subcategories', json);
  }
  
  List<SubCategory> loadExpenseSubCategories() {
    final json = prefs.getString('expense_subcategories');
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((s) => SubCategory.fromJson(s)).toList();
  }
  
  // Сохранение подкатегорий доходов
  void saveIncomeSubCategories(List<SubCategory> subCategories) {
    final json = jsonEncode(subCategories.map((s) => s.toJson()).toList());
    prefs.setString('income_subcategories', json);
  }
  
  List<SubCategory> loadIncomeSubCategories() {
    final json = prefs.getString('income_subcategories');
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((s) => SubCategory.fromJson(s)).toList();
  }
  
  // Сохранение регулярных платежей (старые)
  void saveRecurringPayments(List<RecurringPayment> payments) {
    final json = jsonEncode(payments.map((p) => p.toJson()).toList());
    prefs.setString('recurring_payments', json);
  }
  
  List<RecurringPayment> loadRecurringPayments() {
    final json = prefs.getString('recurring_payments');
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((p) => RecurringPayment.fromJson(p)).toList();
  }

  // ============================================================
  // НОВЫЕ МЕТОДЫ ДЛЯ ПЛАТЕЖЕЙ (Payment)
  // ============================================================

  // Сохранение платежей (новые)
  void savePayments(List<Payment> payments) {
    final json = jsonEncode(payments.map((p) => p.toJson()).toList());
    prefs.setString('payments', json);
  }
  
  List<Payment> loadPayments() {
    final json = prefs.getString('payments');
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((p) => Payment.fromJson(p)).toList();
  }
  
  // Настройки
  String getCurrency() => prefs.getString('currency') ?? '₽';
  void setCurrency(String currency) => prefs.setString('currency', currency);
  
  bool getShowNotifications() => prefs.getBool('showNotifications') ?? true;
  void setShowNotifications(bool value) => prefs.setBool('showNotifications', value);
  
  bool getIsDarkMode() => prefs.getBool('isDarkMode') ?? false;
  void setIsDarkMode(bool value) => prefs.setBool('isDarkMode', value);
  
  // Полный экспорт данных
  String exportAllData() {
    final data = {
      'accounts': loadAccounts().map((a) => a.toJson()).toList(),
      'transactions': loadTransactions().map((t) => t.toJson()).toList(),
      'expense_categories': loadExpenseCategories().map((c) => c.toJson()).toList(),
      'income_categories': loadIncomeCategories().map((c) => c.toJson()).toList(),
      'expense_subcategories': loadExpenseSubCategories().map((s) => s.toJson()).toList(),
      'income_subcategories': loadIncomeSubCategories().map((s) => s.toJson()).toList(),
      'recurring_payments': loadRecurringPayments().map((p) => p.toJson()).toList(),
      'payments': loadPayments().map((p) => p.toJson()).toList(),
      'settings': {
        'currency': getCurrency(),
        'showNotifications': getShowNotifications(),
        'isDarkMode': getIsDarkMode(),
      },
    };
    return jsonEncode(data);
  }
  
  // Полный импорт данных
  void importAllData(String json) {
    final data = jsonDecode(json);

    if (data['accounts'] != null) {
      saveAccounts((data['accounts'] as List).map((a) => Account.fromJson(a)).toList());
    }

    if (data['transactions'] != null) {
      final transactions = (data['transactions'] as List).map((t) {
        if (t['accountId'] == null && t['accountName'] != null) {
          t['accountId'] = t['accountName'];
          t['date'] = t['date'] ?? DateTime.now().toIso8601String();
          t['isPlanned'] = false;
        }
        return Transaction.fromJson(t);
      }).toList();
      saveTransactions(transactions);
    }

    // Общий формат categories (список строк)
    if (data['categories'] != null && data['expense_categories'] == null) {
      final categories = (data['categories'] as List).cast<String>();
      final expenseCategories = categories
          .where((c) => c != 'Зарплата' && c != 'Подработка')
          .map((c) => Category(c, Icons.category, '#607D8B'))
          .toList();
      final incomeCategories = categories
          .where((c) => c == 'Зарплата' || c == 'Подработка')
          .map((c) => Category(c, Icons.work, '#4CAF50'))
          .toList();
      
      if (expenseCategories.isNotEmpty) saveExpenseCategories(expenseCategories);
      if (incomeCategories.isNotEmpty) saveIncomeCategories(incomeCategories);
    }

    // Старый формат
    if (data['expense_categories'] != null) {
      saveExpenseCategories((data['expense_categories'] as List).map((c) => Category.fromJson(c)).toList());
    }

    if (data['income_categories'] != null) {
      saveIncomeCategories((data['income_categories'] as List).map((c) => Category.fromJson(c)).toList());
    }

    if (data['expense_subcategories'] != null) {
      saveExpenseSubCategories((data['expense_subcategories'] as List).map((s) => SubCategory.fromJson(s)).toList());
    }

    if (data['income_subcategories'] != null) {
      saveIncomeSubCategories((data['income_subcategories'] as List).map((s) => SubCategory.fromJson(s)).toList());
    }

    // Общий формат recurring
    if (data['recurring'] != null && data['recurring_payments'] == null) {
      saveRecurringPayments((data['recurring'] as List).map((p) => RecurringPayment.fromJson(p)).toList());
    }

    // Старый формат
    if (data['recurring_payments'] != null) {
      saveRecurringPayments((data['recurring_payments'] as List).map((p) => RecurringPayment.fromJson(p)).toList());
    }

    // НОВЫЕ ПЛАТЕЖИ
    if (data['payments'] != null) {
      savePayments((data['payments'] as List).map((p) => Payment.fromJson(p)).toList());
    }

    // Подкатегории из облака (общий формат)
    if (data['subcategories'] != null) {
      final subs = (data['subcategories'] as List).map((s) => SubCategory.fromJson(s)).toList();
      final expenseSubs = subs.where((s) => !['Зарплата', 'Подработка', 'Дежурства', 'Подарок'].contains(s.parentName)).toList();
      final incomeSubs = subs.where((s) => ['Зарплата', 'Подработка', 'Дежурства', 'Подарок'].contains(s.parentName)).toList();

      if (expenseSubs.isNotEmpty) saveExpenseSubCategories(expenseSubs);
      if (incomeSubs.isNotEmpty) saveIncomeSubCategories(incomeSubs);
    }

    if (data['settings'] != null) {
      final settings = data['settings'];
      if (settings['currency'] != null) setCurrency(settings['currency']);
      if (settings['showNotifications'] != null) setShowNotifications(settings['showNotifications']);
      if (settings['isDarkMode'] != null) setIsDarkMode(settings['isDarkMode']);
    }
  }
  
  // Очистка всех данных
  void clearAll() {
    prefs.remove('accounts');
    prefs.remove('transactions');
    prefs.remove('expense_categories');
    prefs.remove('income_categories');
    prefs.remove('expense_subcategories');
    prefs.remove('income_subcategories');
    prefs.remove('recurring_payments');
    prefs.remove('payments');
  }
  
  String? loadLastAccountId() => prefs.getString('last_account_id');
  void saveLastAccountId(String id) => prefs.setString('last_account_id', id);
  
  String? loadLastCategory() => prefs.getString('last_category');
  void saveLastCategory(String category) => prefs.setString('last_category', category);

  String? getString(String key) => prefs.getString(key);
  void setString(String key, String value) => prefs.setString(key, value);
}