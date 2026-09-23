import 'package:flutter/material.dart';
import 'payment_schedule.dart';

class Account {
  final String id;
  final String name;
  final String type; // cash, debit, credit
  final double balance;
  final double creditLimit;
  final String bank;
  final String cardNumber;
  final String color;
  final String icon;
  final String? iconPath;
  final int order;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.creditLimit = 0,
    this.bank = '',
    this.cardNumber = '',
    this.color = '#00897B',
    this.icon = 'wallet',
    this.iconPath,
    this.order = 0,
  });

  Account copyWith({
    String? name,
    String? type,
    double? balance,
    double? creditLimit,
    String? bank,
    String? cardNumber,
    String? color,
    String? icon,
    String? iconPath,
    int? order,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      bank: bank ?? this.bank,
      cardNumber: cardNumber ?? this.cardNumber,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      iconPath: iconPath ?? this.iconPath,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'balance': balance,
        'creditLimit': creditLimit,
        'bank': bank,
        'cardNumber': cardNumber,
        'color': color,
        'icon': icon,
        'iconPath': iconPath,
        'order': order,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] ?? DateTime.now().toString(),
        name: json['name'] ?? '',
        type: json['type'] ?? 'cash',
        balance: (json['balance'] ?? 0).toDouble(),
        creditLimit: (json['creditLimit'] ?? 0).toDouble(),
        bank: json['bank'] ?? '',
        cardNumber: json['cardNumber'] ?? '',
        color: json['color'] ?? '#4CAF50',
        icon: json['icon'] ?? 'wallet',
        iconPath: json['iconPath'],
        order: json['order'] ?? 0,
      );
}

class Category {
  final String name;
  final IconData icon;
  final String color;

  Category(this.name, this.icon, this.color);

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon.codePoint.toString(),
        'color': color,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        json['name'] ?? '',
        // ignore: non_const_argument_for_const_parameter
        IconData(int.tryParse(json['icon']?.toString() ?? '0') ?? 0,
            fontFamily: 'MaterialIcons'),
        json['color'] ?? '#607D8B',
      );
}

class SubCategory {
  final String name;
  final String parentName;
  final IconData icon;

  SubCategory(this.name, this.parentName, this.icon);

  Map<String, dynamic> toJson() => {
        'name': name,
        'parentName': parentName,
        'icon': icon.codePoint.toString(),
      };

  factory SubCategory.fromJson(Map<String, dynamic> json) => SubCategory(
        json['name'] ?? '',
        json['parentName'] ?? '',
        // ignore: non_const_argument_for_const_parameter
        IconData(int.tryParse(json['icon']?.toString() ?? '0') ?? 0,
            fontFamily: 'MaterialIcons'),
      );
}

class Transaction {
  final String id;
  final double amount;
  final String category;
  final String? subCategory;
  final bool isIncome;
  final String note;
  final DateTime date;
  final String accountId;
  final String? toAccountId;
  final bool isPlanned;
  final DateTime? plannedDate;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    this.subCategory,
    required this.isIncome,
    required this.note,
    required this.date,
    required this.accountId,
    this.toAccountId,
    this.isPlanned = false,
    this.plannedDate,
  });

  bool get isTransfer => toAccountId != null;

  Transaction copyWith({
    double? amount,
    String? category,
    String? subCategory,
    bool? isIncome,
    String? note,
    DateTime? date,
    String? accountId,
    String? toAccountId,
    bool? isPlanned,
    DateTime? plannedDate,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      isPlanned: isPlanned ?? this.isPlanned,
      plannedDate: plannedDate ?? this.plannedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'subCategory': subCategory,
        'isIncome': isIncome,
        'note': note,
        'date': date.toIso8601String(),
        'accountId': accountId,
        'toAccountId': toAccountId,
        'isPlanned': isPlanned,
        'plannedDate': plannedDate?.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] ?? DateTime.now().toString(),
        amount: (json['amount'] ?? 0).toDouble(),
        category: json['category'] ?? '',
        subCategory: json['subCategory'],
        isIncome: json['isIncome'] ?? false,
        note: json['note'] ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        accountId: json['accountId'] ?? json['accountName'] ?? '',
        toAccountId: json['toAccountId'],
        isPlanned: json['isPlanned'] ?? false,
        plannedDate: json['plannedDate'] != null
            ? DateTime.tryParse(json['plannedDate'].toString())
            : null,
      );
}

class RecurringPayment {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String? subCategory;
  final bool isIncome;
  final String accountId;
  String? fromAccountId;
  String? paymentType;
  final String frequency;
  final int interval;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final DateTime? startDate;
  final DateTime? nextDate;
  final bool isActive;

  RecurringPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.subCategory,
    required this.isIncome,
    required this.accountId,
    this.fromAccountId,
    this.paymentType,
    required this.frequency,
    this.interval = 1,
    this.dayOfWeek,
    this.dayOfMonth,
    this.startDate,
    this.nextDate,
    this.isActive = true,
  });

  RecurringPayment copyWith({
    String? name,
    double? amount,
    String? category,
    String? subCategory,
    bool? isIncome,
    String? accountId,
    String? fromAccountId,
    String? paymentType,
    String? frequency,
    int? interval,
    int? dayOfWeek,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? nextDate,
    bool? isActive,
  }) {
    return RecurringPayment(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      isIncome: isIncome ?? this.isIncome,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      paymentType: paymentType ?? this.paymentType,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate ?? this.startDate,
      nextDate: nextDate ?? this.nextDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category,
        'subCategory': subCategory,
        'isIncome': isIncome,
        'accountId': accountId,
        'fromAccountId': fromAccountId,
        'paymentType': paymentType,
        'frequency': frequency,
        'interval': interval,
        'dayOfWeek': dayOfWeek,
        'dayOfMonth': dayOfMonth,
        'startDate': startDate?.toIso8601String(),
        'nextDate': nextDate?.toIso8601String(),
        'isActive': isActive,
      };

  factory RecurringPayment.fromJson(Map<String, dynamic> json) =>
      RecurringPayment(
        id: json['id'] ?? DateTime.now().toString(),
        name: json['name'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        category: json['category'] ?? '',
        subCategory: json['subCategory'],
        isIncome: json['isIncome'] ?? false,
        accountId: json['accountId'] ?? json['accountName'] ?? '',
        fromAccountId: json['fromAccountId'],
        paymentType: json['paymentType'],
        frequency: json['frequency'] ?? 'monthly',
        interval: json['interval'] ?? 1,
        dayOfWeek: json['dayOfWeek'],
        dayOfMonth: json['dayOfMonth'],
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'].toString())
            : null,
        nextDate: json['nextDate'] != null
            ? DateTime.tryParse(json['nextDate'].toString())
            : null,
        isActive: json['isActive'] ?? true,
      );
}

// ============================================================
// НОВАЯ МОДЕЛЬ ПЛАТЕЖА (для раздела "Ближайшие платежи")
// ============================================================

class Payment {
  final String id;
  final String name;
  final double amount;
  final bool isIncome;
  final String category;
  final String? subCategory;
  final String fromAccountId;
  final String toAccountId;
  final PaymentSchedule schedule;
  final bool isPaid;
  final String frequency;
  final int interval;
  final String? iconPath;
  final String? color;

  Payment({
    required this.id,
    required this.name,
    required this.amount,
    required this.isIncome,
    required this.category,
    this.subCategory,
    required this.fromAccountId,
    required this.toAccountId,
    required this.schedule,
    this.isPaid = false,
    this.frequency = 'monthly',
    this.interval = 1,
    this.iconPath,
    this.color,
  });

  Payment copyWith({
    String? id,
    String? name,
    double? amount,
    bool? isIncome,
    String? category,
    String? subCategory,
    String? fromAccountId,
    String? toAccountId,
    PaymentSchedule? schedule,
    bool? isPaid,
    String? frequency,
    int? interval,
    String? iconPath,
    String? color,
  }) {
    return Payment(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      schedule: schedule ?? this.schedule,
      isPaid: isPaid ?? this.isPaid,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      iconPath: iconPath ?? this.iconPath,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'isIncome': isIncome,
        'category': category,
        'subCategory': subCategory,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'schedule': schedule.toJson(),
        'isPaid': isPaid,
        'frequency': frequency,
        'interval': interval,
        'iconPath': iconPath,
        'color': color,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        name: json['name'],
        amount: (json['amount'] ?? 0).toDouble(),
        isIncome: json['isIncome'],
        category: json['category'],
        subCategory: json['subCategory'],
        fromAccountId: json['fromAccountId'],
        toAccountId: json['toAccountId'],
        schedule: PaymentSchedule.fromJson(json['schedule']),
        isPaid: json['isPaid'] ?? false,
        frequency: json['frequency'] ?? 'monthly',
        interval: json['interval'] ?? 1,
        iconPath: json['iconPath'],
        color: json['color'],
      );
}

// ============================================================
// СПИСОК БАНКОВСКИХ ИКОНОК
// ============================================================

final List<Map<String, String>> bankIcons = [
  {'name': 'Сбер', 'path': 'assets/icons/banks/sber.png'},
  {'name': 'Альфа', 'path': 'assets/icons/banks/alfa.png'},
  {'name': 'Т-Банк', 'path': 'assets/icons/banks/tbank.png'},
  {'name': 'АТБ', 'path': 'assets/icons/banks/atb.png'},
  {'name': 'Халва', 'path': 'assets/icons/banks/halva.png'},
  {'name': 'Озон', 'path': 'assets/icons/banks/ozon.png'},
  {'name': 'WB', 'path': 'assets/icons/banks/wb.png'},
];
