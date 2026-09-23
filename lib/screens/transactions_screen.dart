import 'package:flutter/material.dart';
import '../models.dart';
import '../services/storage_service.dart';

class TransactionsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> expenseCategories;
  final List<Category> incomeCategories;
  final List<SubCategory> expenseSubCategories;
  final List<SubCategory> incomeSubCategories;
  final String currency;
  final StorageService storageService;
  final Function(Transaction) onAddTransaction;
  final Function(Transaction, Transaction) onUpdateTransaction;
  final Function(Transaction) onDeleteTransaction;
  final Function(Category) onAddIncomeCategory;
  final Function(Category) onAddExpenseCategory;

  const TransactionsScreen({
    Key? key,
    required this.transactions,
    required this.accounts,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.expenseSubCategories,
    required this.incomeSubCategories,
    required this.currency,
    required this.storageService,
    required this.onAddTransaction,
    required this.onUpdateTransaction,
    required this.onDeleteTransaction,
    required this.onAddIncomeCategory,
    required this.onAddExpenseCategory,
  }) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filterType = 'all';
  String _filterCategory = 'all';
  String _filterAccount = 'all'; // ⭐ ДОБАВЛЕНО: фильтр по счетам
  DateTime? _filterDateStart;
  DateTime? _filterDateEnd;

  // ⭐ ДОБАВЛЕНО: вычисление сумм
  double get _totalIncome {
    return _filteredTransactions
        .where((t) => t.isIncome && !t.isTransfer)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _totalExpense {
    return _filteredTransactions
        .where((t) => !t.isIncome && !t.isTransfer)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _totalTransfer {
    return _filteredTransactions
        .where((t) => t.isTransfer)
        .fold(0, (sum, t) => sum + t.amount);
  }

  List<Transaction> get _filteredTransactions {
    var list = widget.transactions.toList();

    // Фильтр по типу
    if (_filterType != 'all') {
      list = list.where((t) {
        if (_filterType == 'income') return t.isIncome && !t.isTransfer;
        if (_filterType == 'expense') return !t.isIncome && !t.isTransfer;
        if (_filterType == 'transfer') return t.isTransfer;
        return true;
      }).toList();
    }

    // Фильтр по категории
    if (_filterCategory != 'all') {
      list = list.where((t) => t.category == _filterCategory).toList();
    }

    // ⭐ ДОБАВЛЕНО: фильтр по счету
    if (_filterAccount != 'all') {
      list = list
          .where((t) =>
              t.accountId == _filterAccount || t.toAccountId == _filterAccount)
          .toList();
    }

    // Фильтр по дате
    if (_filterDateStart != null) {
      list = list
          .where((t) =>
              t.date.isAfter(_filterDateStart!.subtract(Duration(days: 1))))
          .toList();
    }

    if (_filterDateEnd != null) {
      list = list
          .where((t) => t.date.isBefore(_filterDateEnd!.add(Duration(days: 1))))
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ⭐ ДОБАВЛЕНО: блок с суммами
        _buildSummaryCards(),
        _buildFilterBar(),
        Expanded(
          child: _filteredTransactions.isEmpty
              ? Center(
                  child: Text('Нет операций'),
                )
              : ListView.builder(
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(_filteredTransactions[index]);
                  },
                ),
        ),
      ],
    );
  }

  // ⭐ ДОБАВЛЕНО: карточки с суммами
  Widget _buildSummaryCards() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text('Доходы',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                    Text(
                      '+${_totalIncome.toStringAsFixed(2)} ${widget.currency}',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text('Расходы',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    Text(
                      '-${_totalExpense.toStringAsFixed(2)} ${widget.currency}',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_totalTransfer > 0)
            Expanded(
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text('Переводы',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold)),
                      Text(
                        '${_totalTransfer.toStringAsFixed(2)} ${widget.currency}',
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  value: _filterType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('Все')),
                    DropdownMenuItem(value: 'income', child: Text('Доходы')),
                    DropdownMenuItem(value: 'expense', child: Text('Расходы')),
                    DropdownMenuItem(
                        value: 'transfer', child: Text('Переводы')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterType = value!;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField(
                  value: _filterCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'all', child: Text('Все категории')),
                    ...widget.expenseCategories.map((c) =>
                        DropdownMenuItem(value: c.name, child: Text(c.name))),
                    ...widget.incomeCategories.map((c) =>
                        DropdownMenuItem(value: c.name, child: Text(c.name))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterCategory = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // ⭐ ДОБАВЛЕНО: фильтр по счетам
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  value: _filterAccount,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('Все счета')),
                    ...widget.accounts.map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.name))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterAccount = value!;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateRange(),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _filterDateStart != null &&
                                          _filterDateEnd != null
                                      ? '${_filterDateStart!.day}.${_filterDateStart!.month} - ${_filterDateEnd!.day}.${_filterDateEnd!.month}'
                                      : 'Дата',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_filterDateStart != null || _filterDateEnd != null)
                      IconButton(
                        icon: Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _filterDateStart = null;
                            _filterDateEnd = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ⭐ ДОБАВЛЕНО: выбор даты
  Future<void> _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _filterDateStart != null && _filterDateEnd != null
          ? DateTimeRange(
              start: _filterDateStart!,
              end: _filterDateEnd!,
            )
          : null,
    );

    if (result != null) {
      setState(() {
        _filterDateStart = result.start;
        _filterDateEnd = result.end;
      });
    }
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final account = widget.accounts.firstWhere(
      (a) => a.id == transaction.accountId,
      orElse: () =>
          Account(id: '', name: 'Неизвестно', type: 'cash', balance: 0),
    );

    Color color;
    IconData icon;
    String sign;
    String typeText;

    if (transaction.isTransfer) {
      color = Colors.blue;
      icon = Icons.swap_horiz;
      sign = '';
      typeText = 'Перевод';
    } else if (transaction.isIncome) {
      color = Colors.green;
      icon = Icons.arrow_downward;
      sign = '+';
      typeText = 'Доход';
    } else {
      color = Colors.red;
      icon = Icons.arrow_upward;
      sign = '-';
      typeText = 'Расход';
    }

    // ⭐ ИСПОЛЬЗУЕМ Dismissible ДЛЯ СВАЙПА
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) {
        _showDeleteDialog(transaction);
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: _buildTransactionLeading(transaction),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.category,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$sign${transaction.amount.toStringAsFixed(2)} ${widget.currency}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.subCategory != null)
                Text(
                  transaction.subCategory!,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (transaction.note.isNotEmpty)
                Text(
                  transaction.note,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              Text(
                '${transaction.date.day}.${transaction.date.month}.${transaction.date.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          onTap: () => _showActionDialog(transaction),
          // ⭐ УБРАЛИ КНОПКУ КОРЗИНЫ
        ),
      ),
    );
  }

  Widget _buildAccountIcon(String accountId, {double size = 40}) {
    final account = widget.accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(id: '', name: '?', type: 'cash', balance: 0),
    );

    if (account.iconPath != null && account.iconPath!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.13),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
        child: Image.asset(account.iconPath!, fit: BoxFit.contain),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Icon(
        _getAccountIcon(account.icon),
        color: Colors.grey.shade700,
        size: size * 0.6,
      ),
    );
  }

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
      case 'phone':
        return Icons.phone_android;
      case 'home':
        return Icons.home;
      case 'car':
        return Icons.directions_car;
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_cart;
      case 'travel':
        return Icons.flight;
      case 'health':
        return Icons.local_hospital;
      case 'wallet':
      default:
        return Icons.account_balance_wallet;
    }
  }

  void _showActionDialog(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Выберите действие',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(transaction);
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: Colors.orange),
                title: Text('Дублировать'),
                subtitle: Text('Создать копию операции'),
                onTap: () {
                  Navigator.pop(context);
                  _duplicateTransaction(transaction);
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _duplicateTransaction(Transaction original) {
    final duplicated = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: original.amount,
      category: original.category,
      subCategory: original.subCategory,
      isIncome: original.isIncome,
      note: original.note,
      date: DateTime.now(),
      accountId: original.accountId,
      toAccountId: original.toAccountId,
    );

    _showEditDialog(duplicated, isDuplicate: true);
  }

  void _showEditDialog(Transaction transaction, {bool isDuplicate = false}) {
    final amountController =
        TextEditingController(text: transaction.amount.toString());
    final noteController = TextEditingController(text: transaction.note);

    String selectedAccountId = transaction.accountId;
    String? selectedCategory = transaction.category;
    String? selectedSubCategory = transaction.subCategory;
    String? toAccountId = transaction.toAccountId;
    bool isIncome = transaction.isIncome;
    DateTime selectedDate = transaction.date;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isDuplicate
                  ? 'Дублировать операцию'
                  : 'Редактировать операцию'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Сумма',
                        prefixText: '${widget.currency} ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Категория'),
                      items: (isIncome
                              ? widget.incomeCategories
                              : widget.expenseCategories)
                          .map((c) => DropdownMenuItem(
                              value: c.name, child: Text(c.name)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                          selectedSubCategory = null;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    if (selectedCategory != null) ...[
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSubCategory,
                        decoration: InputDecoration(
                          labelText: 'Подкатегория',
                          border: OutlineInputBorder(),
                        ),
                        items: (isIncome
                                ? widget.incomeSubCategories
                                : widget.expenseSubCategories)
                            .where((s) => s.parentName == selectedCategory)
                            .map((s) => DropdownMenuItem(
                                  value: s.name,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedSubCategory = value),
                      ),
                    ],
                    DropdownButtonFormField(
                      value: selectedAccountId,
                      decoration: InputDecoration(labelText: 'Счёт'),
                      items: widget.accounts
                          .map((a) => DropdownMenuItem(
                              value: a.id, child: Text(a.name)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedAccountId = value!),
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      title: Text(
                          'Дата: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'),
                      leading: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Заметка',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0 || selectedCategory == null) return;

                    final updatedTransaction = transaction.copyWith(
                      amount: amount,
                      category: selectedCategory!,
                      subCategory: selectedSubCategory,
                      note: noteController.text.trim(),
                      date: selectedDate,
                      accountId: selectedAccountId,
                      toAccountId: toAccountId,
                    );

                    if (isDuplicate) {
                      widget.onAddTransaction(updatedTransaction);
                    } else {
                      widget.onUpdateTransaction(
                          transaction, updatedTransaction);
                    }

                    Navigator.pop(context);
                  },
                  child: Text(isDuplicate ? 'Дублировать' : 'Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить операцию?'),
          content: Text(
              '${transaction.category} - ${transaction.amount} ${widget.currency}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onDeleteTransaction(transaction);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Удалить', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionLeading(Transaction transaction) {
    // Если перевод — показываем две иконки
    if (transaction.isTransfer && transaction.toAccountId != null) {
      return SizedBox(
        width: 90,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAccountIcon(transaction.accountId, size: 36),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.arrow_forward,
                size: 14,
                color: Colors.blue.shade400,
              ),
            ),
            _buildAccountIcon(transaction.toAccountId!, size: 36),
          ],
        ),
      );
    }

    // Обычная операция — иконка счёта + маленькая стрелка вверх/вниз
    return SizedBox(
      width: 60,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAccountIcon(transaction.accountId, size: 36),
          SizedBox(width: 4),
          Icon(
            transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            size: 16,
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
