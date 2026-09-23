import 'package:flutter/material.dart';
import '../models.dart';

class StatsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Account> accounts;
  final String currency;

  const StatsScreen({
    Key? key,
    required this.transactions,
    required this.accounts,
    required this.currency,
  }) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _filterType = 'month'; // month, lastMonth, year, all, custom
  DateTime? _customStart;
  DateTime? _customEnd;

  final Set<String> _expandedExpenses = {};
  final Set<String> _expandedIncomes = {};

  @override
  Widget build(BuildContext context) {
    final currency = widget.currency;
    final filtered = _getFilteredTransactions();

    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in filtered) {
      if (!t.isTransfer) {
        if (t.isIncome) {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }
    }

    // Группировка расходов: категория -> подкатегория -> сумма
    final expenseGroups = <String, Map<String, double>>{};
    for (var t in filtered.where((t) => !t.isIncome && !t.isTransfer)) {
      final cat = t.category;
      final sub = (t.subCategory == null || t.subCategory!.isEmpty)
          ? 'Без подкатегории'
          : t.subCategory!;
      expenseGroups.putIfAbsent(cat, () => {});
      expenseGroups[cat]![sub] = (expenseGroups[cat]![sub] ?? 0) + t.amount;
    }

    // Группировка доходов
    final incomeGroups = <String, Map<String, double>>{};
    for (var t in filtered.where((t) => t.isIncome && !t.isTransfer)) {
      final cat = t.category;
      final sub = (t.subCategory == null || t.subCategory!.isEmpty)
          ? 'Без подкатегории'
          : t.subCategory!;
      incomeGroups.putIfAbsent(cat, () => {});
      incomeGroups[cat]![sub] = (incomeGroups[cat]![sub] ?? 0) + t.amount;
    }

    // Сортируем категории по сумме (убывание)
    final sortedExpenses = _sortCategories(expenseGroups);
    final sortedIncomes = _sortCategories(incomeGroups);

    final colors = [
      Colors.red, Colors.orange, Colors.blue, Colors.green,
      Colors.purple, Colors.pink, Colors.teal, Colors.indigo,
    ];

    // Обычные счета и кредитки
    final regularAccounts = widget.accounts.where((a) => a.type != 'credit').toList();
    final creditAccounts = widget.accounts.where((a) => a.type == 'credit').toList();

    return Scaffold(
      appBar: AppBar(title: Text('Статистика')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // ==== Фильтр по дате ====
          _buildFilterBar(),
          SizedBox(height: 16),

          // ==== Доходы / Расходы ====
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.green),
                      Text('Доходы'),
                      Text('${totalIncome.toStringAsFixed(2)} $currency',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.red),
                      Text('Расходы'),
                      Text('${totalExpense.toStringAsFixed(2)} $currency',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // ==== Расходы по категориям ====
          if (sortedExpenses.isNotEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Расходы по категориям',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    for (int i = 0; i < sortedExpenses.length; i++)
                      _buildCategoryTile(
                        category: sortedExpenses[i].key,
                        subcategories: sortedExpenses[i].value,
                        color: colors[i % colors.length],
                        currency: currency,
                        expandedSet: _expandedExpenses,
                      ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 16),

          // ==== Доходы по категориям ====
          if (sortedIncomes.isNotEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Доходы по категориям',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    for (int i = 0; i < sortedIncomes.length; i++)
                      _buildCategoryTile(
                        category: sortedIncomes[i].key,
                        subcategories: sortedIncomes[i].value,
                        color: colors[i % colors.length],
                        currency: currency,
                        expandedSet: _expandedIncomes,
                      ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 16),

          // ==== Обычные счета ====
          if (regularAccounts.isNotEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Счета', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    for (var account in regularAccounts)
                      ListTile(
                        leading: Icon(_getAccountIcon(account.icon)),
                        title: Text(account.name),
                        trailing: Text(
                          '${account.balance.toStringAsFixed(2)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: account.balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 16),

          // ==== Кредитные карты ====
          if (creditAccounts.isNotEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Кредитные карты',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    for (var account in creditAccounts)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(account.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('${account.balance.toStringAsFixed(2)} $currency',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: account.balance >= 0 ? Colors.green : Colors.red)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Долг:',
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('${(account.creditLimit - account.balance).toStringAsFixed(2)} $currency',
                                    style: TextStyle(fontSize: 12, color: Colors.red)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Лимит:',
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('${account.creditLimit.toStringAsFixed(2)} $currency',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================
  // ФИЛЬТР ПО ДАТЕ
  // ============================================================

  Widget _buildFilterBar() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'month', child: Text('Этот месяц')),
                      DropdownMenuItem(value: 'lastMonth', child: Text('Прошлый месяц')),
                      DropdownMenuItem(value: 'year', child: Text('Этот год')),
                      DropdownMenuItem(value: 'all', child: Text('Всё время')),
                      DropdownMenuItem(value: 'custom', child: Text('Свой период')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterType = value!;
                        if (_filterType == 'custom') {
                          _selectCustomPeriod();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_filterType == 'custom' && _customStart != null && _customEnd != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${_customStart!.day}.${_customStart!.month}.${_customStart!.year} — '
                      '${_customEnd!.day}.${_customEnd!.month}.${_customEnd!.year}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: _selectCustomPeriod,
                      child: Text('Изменить'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomPeriod() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );
    if (result != null) {
      setState(() {
        _customStart = result.start;
        _customEnd = result.end;
      });
    }
  }

  List<Transaction> _getFilteredTransactions() {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (_filterType) {
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'lastMonth':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'custom':
        start = _customStart;
        end = _customEnd != null
            ? DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59)
            : null;
        break;
      case 'all':
      default:
        return widget.transactions;
    }

    return widget.transactions.where((t) {
      if (start != null && t.date.isBefore(start)) return false;
      if (end != null && t.date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  // ============================================================
  // СОРТИРОВКА КАТЕГОРИЙ
  // ============================================================

  List<MapEntry<String, Map<String, double>>> _sortCategories(
      Map<String, Map<String, double>> groups) {
    final list = groups.entries.toList();
    list.sort((a, b) {
      final sumA = a.value.values.fold<double>(0, (s, v) => s + v);
      final sumB = b.value.values.fold<double>(0, (s, v) => s + v);
      return sumB.compareTo(sumA);
    });
    return list;
  }

  // ============================================================
  // КАРТОЧКА КАТЕГОРИИ
  // ============================================================

  Widget _buildCategoryTile({
    required String category,
    required Map<String, double> subcategories,
    required Color color,
    required String currency,
    required Set<String> expandedSet,
  }) {
    final total = subcategories.values.fold<double>(0, (s, v) => s + v);
    final isExpanded = expandedSet.contains(category);

    // Сортируем подкатегории по убыванию
    final sortedSubs = subcategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxSub = sortedSubs.isNotEmpty ? sortedSubs.first.value : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                expandedSet.remove(category);
              } else {
                expandedSet.add(category);
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(2)} $currency',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 24, bottom: 8),
            child: Column(
              children: [
                for (var sub in sortedSubs)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(sub.key, style: TextStyle(fontSize: 13)),
                            Text(
                              '${sub.value.toStringAsFixed(2)} $currency',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: maxSub > 0 ? sub.value / maxSub : 0,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Divider(height: 1),
      ],
    );
  }

  // ============================================================
  // ИКОНКА СЧЁТА
  // ============================================================

  IconData _getAccountIcon(String iconName) {
    switch (iconName) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      case 'piggy':
        return Icons.savings;
      case 'wallet':
      default:
        return Icons.account_balance_wallet;
    }
  }
}