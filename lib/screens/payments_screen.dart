import 'package:flutter/material.dart';
import '../models.dart';
import '../payment_schedule.dart';

class PaymentsScreen extends StatefulWidget {
  final List<Payment> payments;
  final List<Account> accounts;
  final List<Category> expenseCategories;
  final List<Category> incomeCategories;
  final List<SubCategory> incomeSubCategories;
  final List<SubCategory> expenseSubCategories;
  final String currency;
  final Function(Payment) onAdd;
  final Function(Payment, Payment) onUpdate;
  final Function(Payment) onDelete;
  final Function(Payment) onPayNow;

  const PaymentsScreen({
    Key? key,
    required this.payments,
    required this.accounts,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.incomeSubCategories,
    required this.expenseSubCategories,
    required this.currency,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onPayNow,
  }) : super(key: key);

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> get _sortedPayments {
    final filtered =
        widget.payments.where((p) => !p.schedule.isComplete).toList();
    filtered.sort((a, b) {
      final aDate = a.schedule.nextDate ?? DateTime(2100);
      final bDate = b.schedule.nextDate ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  Map<String, List<Payment>> get _groupedByAccount {
    final map = <String, List<Payment>>{};
    for (var payment in _sortedPayments) {
      final key = payment.fromAccountId;
      map.putIfAbsent(key, () => []).add(payment);
    }
    return map;
  }

  String _getAccountName(String accountId) {
    for (var account in widget.accounts) {
      if (account.id == accountId) return account.name;
    }
    return 'Неизвестно';
  }

  String _getPaymentDescription(Payment payment) {
    if (payment.isIncome) {
      return '💰 Доход • ${_getAccountName(payment.toAccountId)}';
    } else {
      return '💳 ${_getAccountName(payment.fromAccountId)} → ${_getAccountName(payment.toAccountId)}';
    }
  }

  bool _isOverdue(DateTime date) {
    return date.isBefore(DateTime.now()) &&
        !date.isAtSameMomentAs(DateTime.now());
  }

  bool _isSoon(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 3;
  }

  double _parseAmount(String text) {
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final payments = _sortedPayments;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ближайшие платежи',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.teal, size: 30),
              onPressed: _showAddDialog,
            ),
          ],
        ),
        SizedBox(height: 8),
        if (payments.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.event_note, size: 60, color: Colors.grey.shade300),
                  SizedBox(height: 12),
                  Text(
                    'Нет запланированных платежей',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ..._groupedByAccount.entries.map((entry) {
            final accountName = _getAccountName(entry.key);
            final accountPayments = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '💳 $accountName',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                ...accountPayments.map((payment) => _buildPaymentCard(payment)),
                SizedBox(height: 8),
              ],
            );
          }),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final nextDate = payment.schedule.nextDate;
    final isOverdue = nextDate != null && _isOverdue(nextDate);
    final isSoon = nextDate != null && _isSoon(nextDate);
    final isPaid = payment.isPaid;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildPaymentIcon(payment),
        title: Text(
          payment.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${payment.amount.toStringAsFixed(2)} ${widget.currency}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: payment.isIncome ? Colors.green : Colors.red,
              ),
            ),
            Text(
              _getPaymentDescription(payment),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (nextDate != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isOverdue
                        ? Colors.red
                        : (isSoon ? Colors.orange : Colors.blue),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${nextDate.day}.${nextDate.month}.${nextDate.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue
                          ? Colors.red
                          : (isSoon ? Colors.orange : Colors.blue),
                      fontWeight:
                          isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isOverdue) ...[
                    SizedBox(width: 4),
                    Text(
                      'ПРОСРОЧЕН!',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (isSoon) ...[
                    SizedBox(width: 4),
                    Text(
                      'СКОРО',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPaid &&
                nextDate != null &&
                nextDate.isBefore(DateTime.now().add(Duration(days: 1))))
              ElevatedButton(
                onPressed: () => _showPayConfirmation(payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(payment.isIncome ? 'Зачислить' : 'Списать'),
              )
            else if (isPaid)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Оплачено ✓',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '⏳ Ожидание',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Удалить платёж?'),
                    content: Text(payment.name),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          widget.onDelete(payment);
                          Navigator.pop(context);
                        },
                        child: Text('Удалить',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () => _showEditDialog(payment),
      ),
    );
  }

  Widget _buildPaymentIcon(Payment payment) {
    // Если есть банковская иконка — показываем картинку
    if (payment.iconPath != null && payment.iconPath!.isNotEmpty) {
      return Container(
        width: 45,
        height: 45,
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Image.asset(payment.iconPath!, fit: BoxFit.contain),
      );
    }

    // Иначе — Material Icon по типу платежа
    final isOverdue = payment.schedule.nextDate != null &&
        payment.schedule.nextDate!.isBefore(DateTime.now());

    return CircleAvatar(
      backgroundColor: payment.isIncome
          ? Colors.green.shade100
          : (isOverdue ? Colors.red.shade100 : Colors.orange.shade100),
      child: Icon(
        payment.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
        color: payment.isIncome
            ? Colors.green
            : (isOverdue ? Colors.red : Colors.orange),
      ),
    );
  }

  void _showPayConfirmation(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(payment.isIncome ? 'Зачислить доход?' : 'Списать платёж?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.name, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Сумма: ${payment.amount.toStringAsFixed(2)} ${widget.currency}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Со счёта: ${_getAccountName(payment.fromAccountId)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (!payment.isIncome)
              Text(
                'На счёт: ${_getAccountName(payment.toAccountId)}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onPayNow(payment);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(payment.isIncome ? 'Зачислить' : 'Списать',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ДИАЛОГ ДОБАВЛЕНИЯ ПЛАТЕЖА
  // ============================================================

  void _showAddDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    String fromAccountId =
        widget.accounts.isNotEmpty ? widget.accounts[0].id : '';
    String toAccountId =
        widget.accounts.isNotEmpty ? widget.accounts[0].id : '';
    bool isIncome = false;
    String? selectedCategory;
    String? selectedSubCategory;
    String? selectedIconPath;
    String? selectedColor;

    String frequency = 'monthly';
    int interval = 1;
    int dayOfWeek = 1;
    int dayOfMonth = 1;
    DateTime startDate = DateTime.now();

    String expenseType = 'service';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Новый платёж'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text('Расход'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Доход'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: (value) {
                    setState(() {
                      isIncome = value.first;
                      fromAccountId = widget.accounts.isNotEmpty
                          ? widget.accounts[0].id
                          : '';
                      toAccountId = widget.accounts.isNotEmpty
                          ? widget.accounts[0].id
                          : '';
                      expenseType = 'service';
                    });
                  },
                ),
                SizedBox(height: 12),
                if (!isIncome)
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'service',
                        label: Text('Оплата услуги'),
                        icon: Icon(Icons.receipt),
                      ),
                      ButtonSegment(
                        value: 'transfer',
                        label: Text('Перевод между счетами'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {expenseType},
                    onSelectionChanged: (value) {
                      setState(() {
                        expenseType = value.first;
                        fromAccountId = widget.accounts.isNotEmpty
                            ? widget.accounts[0].id
                            : '';
                        toAccountId = widget.accounts.isNotEmpty
                            ? widget.accounts[0].id
                            : '';
                      });
                    },
                  ),
                if (!isIncome) SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
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
                if (!isIncome)
                  DropdownButtonFormField(
                    value: fromAccountId,
                    decoration: InputDecoration(labelText: 'Счёт списания'),
                    items: widget.accounts
                        .map((a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => fromAccountId = value!),
                  ),
                if (!isIncome) SizedBox(height: 12),
                if (isIncome || (!isIncome && expenseType == 'transfer'))
                  DropdownButtonFormField(
                    value: toAccountId,
                    decoration: InputDecoration(
                      labelText:
                          isIncome ? 'Счёт зачисления' : 'Счёт пополнения',
                    ),
                    items: widget.accounts
                        .map((a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (value) => setState(() => toAccountId = value!),
                  ),
                if (isIncome || (!isIncome && expenseType == 'transfer'))
                  SizedBox(height: 12),
                DropdownButtonFormField(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: 'Категория'),
                  items: (isIncome
                          ? widget.incomeCategories
                          : widget.expenseCategories)
                      .map((c) =>
                          DropdownMenuItem(value: c.name, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCategory = value),
                ),
                SizedBox(height: 12),
                if (selectedCategory != null) ...[
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
                        .map((s) => s.name)
                        .toSet()
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedSubCategory = value),
                  ),
                  SizedBox(height: 12),
                ],
                // Цвет
                Text('Цвет:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '#F44336',
                    '#E91E63',
                    '#9C27B0',
                    '#673AB7',
                    '#3F51B5',
                    '#2196F3',
                    '#00BCD4',
                    '#009688',
                    '#4CAF50',
                    '#8BC34A',
                    '#FF9800',
                    '#FF5722',
                    '#795548',
                    '#607D8B',
                    '#000000',
                    '#9E9E9E',
                  ].map((hex) {
                    final isSelected = selectedColor == hex;
                    return InkWell(
                      onTap: () => setState(() => selectedColor = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(int.parse('FF${hex.replaceAll('#', '')}',
                              radix: 16)),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                // Банковские иконки
                Text('Иконка:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Банки:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bankIcons.map((bank) {
                    final path = bank['path']!;
                    final isSelected = selectedIconPath == path;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedIconPath = path;
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: Colors.teal, width: 2)
                              : null,
                        ),
                        child: Image.asset(path, fit: BoxFit.contain),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField(
                  value: frequency,
                  decoration: InputDecoration(labelText: 'Периодичность'),
                  items: [
                    DropdownMenuItem(value: 'daily', child: Text('Ежедневно')),
                    DropdownMenuItem(
                        value: 'weekly', child: Text('Еженедельно')),
                    DropdownMenuItem(
                        value: 'biweekly', child: Text('Раз в 2 недели')),
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Ежемесячно')),
                    DropdownMenuItem(value: 'yearly', child: Text('Ежегодно')),
                  ],
                  onChanged: (value) => setState(() => frequency = value!),
                ),
                SizedBox(height: 12),
                ListTile(
                  title: Text(
                      'Дата первого платежа: ${startDate.day}.${startDate.month}.${startDate.year}'),
                  leading: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
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
                final name = nameController.text.trim();
                final amount = _parseAmount(amountController.text);
                if (name.isEmpty || amount <= 0 || selectedCategory == null)
                  return;

                final schedule = PaymentSchedule.fromPattern(
                  startDate: startDate,
                  frequency: frequency,
                  interval: interval,
                  dayOfWeek: frequency == 'weekly' ? dayOfWeek : null,
                  dayOfMonth: frequency == 'monthly' ? dayOfMonth : null,
                  count: 12,
                );

                String finalFromAccountId;
                String finalToAccountId;

                if (isIncome) {
                  finalFromAccountId = toAccountId;
                  finalToAccountId = toAccountId;
                } else if (expenseType == 'transfer') {
                  finalFromAccountId = fromAccountId;
                  finalToAccountId = toAccountId;
                } else {
                  finalFromAccountId = fromAccountId;
                  finalToAccountId = fromAccountId;
                }

                widget.onAdd(Payment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  amount: amount,
                  isIncome: isIncome,
                  category: selectedCategory!,
                  subCategory: selectedSubCategory,
                  fromAccountId: finalFromAccountId,
                  toAccountId: finalToAccountId,
                  schedule: schedule,
                  isPaid: false,
                  frequency: frequency,
                  interval: interval,
                  iconPath: selectedIconPath,
                  color: selectedColor,
                ));

                Navigator.pop(context);
              },
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ДИАЛОГ РЕДАКТИРОВАНИЯ ПЛАТЕЖА
  // ============================================================

  void _showEditDialog(Payment payment) {
    final nameController = TextEditingController(text: payment.name);
    final amountController =
        TextEditingController(text: payment.amount.toString());

    String fromAccountId = payment.fromAccountId;
    String toAccountId = payment.toAccountId;
    bool isIncome = payment.isIncome;
    String? selectedCategory = payment.category;
    String? selectedSubCategory = payment.subCategory;
    String? selectedIconPath = payment.iconPath;
    String? selectedColor = payment.color;
    String frequency = payment.frequency;
    DateTime startDate = payment.schedule.dates.first;

    String expenseType = 'service';
    if (!isIncome && fromAccountId != toAccountId) {
      expenseType = 'transfer';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Редактировать платёж'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text('Расход'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Доход'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: (value) {
                    setState(() {
                      isIncome = value.first;
                      fromAccountId = widget.accounts.isNotEmpty
                          ? widget.accounts[0].id
                          : '';
                      toAccountId = widget.accounts.isNotEmpty
                          ? widget.accounts[0].id
                          : '';
                      expenseType = 'service';
                    });
                  },
                ),
                SizedBox(height: 12),
                if (!isIncome)
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'service',
                        label: Text('Оплата услуги'),
                        icon: Icon(Icons.receipt),
                      ),
                      ButtonSegment(
                        value: 'transfer',
                        label: Text('Перевод между счетами'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {expenseType},
                    onSelectionChanged: (value) {
                      setState(() {
                        expenseType = value.first;
                        fromAccountId = widget.accounts.isNotEmpty
                            ? widget.accounts[0].id
                            : '';
                        toAccountId = widget.accounts.isNotEmpty
                            ? widget.accounts[0].id
                            : '';
                      });
                    },
                  ),
                if (!isIncome) SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
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
                if (!isIncome)
                  DropdownButtonFormField(
                    value: fromAccountId,
                    decoration: InputDecoration(labelText: 'Счёт списания'),
                    items: widget.accounts
                        .map((a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => fromAccountId = value!),
                  ),
                if (!isIncome) SizedBox(height: 12),
                if (isIncome || (!isIncome && expenseType == 'transfer'))
                  DropdownButtonFormField(
                    value: toAccountId,
                    decoration: InputDecoration(
                      labelText:
                          isIncome ? 'Счёт зачисления' : 'Счёт пополнения',
                    ),
                    items: widget.accounts
                        .map((a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (value) => setState(() => toAccountId = value!),
                  ),
                if (isIncome || (!isIncome && expenseType == 'transfer'))
                  SizedBox(height: 12),
                DropdownButtonFormField(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: 'Категория'),
                  items: (isIncome
                          ? widget.incomeCategories
                          : widget.expenseCategories)
                      .map((c) =>
                          DropdownMenuItem(value: c.name, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCategory = value),
                ),
                SizedBox(height: 12),
                if (selectedCategory != null) ...[
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
                        .map((s) => s.name)
                        .toSet()
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedSubCategory = value),
                  ),
                  SizedBox(height: 12),
                ],
                // Цвет
                Text('Цвет:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '#F44336',
                    '#E91E63',
                    '#9C27B0',
                    '#673AB7',
                    '#3F51B5',
                    '#2196F3',
                    '#00BCD4',
                    '#009688',
                    '#4CAF50',
                    '#8BC34A',
                    '#FF9800',
                    '#FF5722',
                    '#795548',
                    '#607D8B',
                    '#000000',
                    '#9E9E9E',
                  ].map((hex) {
                    final isSelected = selectedColor == hex;
                    return InkWell(
                      onTap: () => setState(() => selectedColor = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(int.parse('FF${hex.replaceAll('#', '')}',
                              radix: 16)),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
// Банковские иконки
                Text('Иконка:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Банки:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bankIcons.map((bank) {
                    final path = bank['path']!;
                    final isSelected = selectedIconPath == path;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedIconPath = path;
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: Colors.teal, width: 2)
                              : null,
                        ),
                        child: Image.asset(path, fit: BoxFit.contain),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField(
                  value: frequency,
                  decoration: InputDecoration(labelText: 'Периодичность'),
                  items: [
                    DropdownMenuItem(value: 'daily', child: Text('Ежедневно')),
                    DropdownMenuItem(
                        value: 'weekly', child: Text('Еженедельно')),
                    DropdownMenuItem(
                        value: 'biweekly', child: Text('Раз в 2 недели')),
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Ежемесячно')),
                    DropdownMenuItem(value: 'yearly', child: Text('Ежегодно')),
                  ],
                  onChanged: (value) => setState(() => frequency = value!),
                ),
                SizedBox(height: 12),
                ListTile(
                  title: Text(
                      'Дата первого платежа: ${startDate.day}.${startDate.month}.${startDate.year}'),
                  leading: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
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
                final name = nameController.text.trim();
                final amount = _parseAmount(amountController.text);
                if (name.isEmpty || amount <= 0 || selectedCategory == null)
                  return;

                final newSchedule = PaymentSchedule.fromPattern(
                  startDate: startDate,
                  frequency: frequency,
                  interval: 1,
                  dayOfWeek: frequency == 'weekly' ? 1 : null,
                  dayOfMonth: frequency == 'monthly' ? 1 : null,
                  count: 12,
                );

                String finalFromAccountId;
                String finalToAccountId;

                if (isIncome) {
                  finalFromAccountId = toAccountId;
                  finalToAccountId = toAccountId;
                } else if (expenseType == 'transfer') {
                  finalFromAccountId = fromAccountId;
                  finalToAccountId = toAccountId;
                } else {
                  finalFromAccountId = fromAccountId;
                  finalToAccountId = fromAccountId;
                }

                widget.onUpdate(
                  payment,
                  payment.copyWith(
                    name: name,
                    amount: amount,
                    isIncome: isIncome,
                    category: selectedCategory!,
                    subCategory: selectedSubCategory,
                    fromAccountId: finalFromAccountId,
                    toAccountId: finalToAccountId,
                    schedule: newSchedule,
                    frequency: frequency,
                    interval: 1,
                    iconPath: selectedIconPath, // ← ДОБАВИЛИ
                    color: selectedColor, // ← ДОБАВИЛИ
                  ),
                );

                Navigator.pop(context);
              },
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
