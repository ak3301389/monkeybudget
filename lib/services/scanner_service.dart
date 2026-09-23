import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ScannerService {
  // Парсинг QR-кода чека
  Future<Map<String, dynamic>?> parseReceipt(String qrData) async {
    debugPrint('=== QR DATA ===');
    debugPrint(qrData);
    
    // Пробуем распарсить как JSON
    try {
      final data = jsonDecode(qrData);
      debugPrint('JSON parsed successfully');
      return _extractFromJson(data);
    } catch (e) {
      debugPrint('Not JSON: $e');
    }
    
    // Пробуем извлечь данные из строки
    final amount = _extractAmount(qrData);
    if (amount > 0) {
      debugPrint('Amount found: $amount');
      return {
        'amount': amount,
        'category': 'Другое',
        'items': [],
      };
    }
    
    return null;
  }
  
  double _extractAmount(String data) {
    // Ищем "sum" или "сумма"
    final sumPatterns = [
      RegExp(r'[sS]=(\d+\.?\d*)'),
      RegExp(r'sum[":\s]+(\d+\.?\d*)'),
      RegExp(r'СУММ?[АA]:\s*(\d+\.?\d*)'),
      RegExp(r'total[":\s]+(\d+\.?\d*)'),
    ];
    
    for (var pattern in sumPatterns) {
      final match = pattern.firstMatch(data);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }
    
    return 0;
  }
  
  Map<String, dynamic>? _extractFromJson(Map<String, dynamic> data) {
    try {
      final amount = double.tryParse(data['totalSum'].toString()) ?? 
                     double.tryParse(data['sum'].toString()) ?? 0;
      
      return {
        'amount': amount,
        'category': 'Другое',
        'items': [],
      };
    } catch (e) {
      return null;
    }
  }
}