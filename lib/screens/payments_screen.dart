import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';
import 'payment_schedule.dart';
import 'dart:convert';

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

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Payment> get _sortedPayments {
    // Показываем только неоплаченные платежи (status = 'pending')
    final filtered =
        widget.payments.where((p) => p.status == 'pending').toList();
    filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return filtered;
  }

  // Ближайшие платежи: один (самый ранний) на каждую серию
  List<Payment> get _nearestBySeries {
    final map = <String, Payment>{};
    for (final p in widget.payments) {
      if (p.status != 'pending') continue;
      final key = p.seriesId ?? p.id; // разовый платёж — сам себе серия
      final existing = map[key];
      if (existing == null || p.dueDate.isBefore(existing.dueDate)) {
        map[key] = p;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
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
    return Column(
      children: [
        // Заголовок и кнопка "+"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Платежи',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.upload_file, color: Colors.teal, size: 28),
                    tooltip: 'Импорт из файла',
                    onPressed: _importFromJson,
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.teal, size: 30),
                    onPressed: _showAddDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Вкладки
        TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(text: 'Ближайшие'),
            Tab(text: 'График'),
          ],
        ),
        // Содержимое вкладок
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUpcomingTab(),
              _buildScheduleTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTab() {
    final payments = _nearestBySeries;
    if (payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Нет запланированных платежей',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: payments.map((p) => _buildPaymentCard(p)).toList(),
    );
  }

  Widget _buildScheduleTab() {
    // Группируем все платежи по seriesId (или по id для разовых)
    final seriesMap = <String, List<Payment>>{};
    for (final p in widget.payments) {
      final key = p.seriesId ?? p.id;
      seriesMap.putIfAbsent(key, () => []).add(p);
    }

    if (seriesMap.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Нет графиков платежей',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Сортируем серии по ближайшей дате
    final entries = seriesMap.entries.toList();
    entries.sort((a, b) {
      final aMin =
          a.value.map((p) => p.dueDate).reduce((x, y) => x.isBefore(y) ? x : y);
      final bMin =
          b.value.map((p) => p.dueDate).reduce((x, y) => x.isBefore(y) ? x : y);
      return aMin.compareTo(bMin);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: entries.map((entry) {
        final seriesPayments = entry.value;
        seriesPayments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        return _buildSeriesCard(entry.key, seriesPayments);
      }).toList(),
    );
  }

  Widget _buildSeriesCard(String seriesId, List<Payment> seriesPayments) {
    final first = seriesPayments.first;
    final accountName = _getAccountName(first.fromAccountId);
    final total = seriesPayments.length;
    final paid = seriesPayments.where((p) => p.status == 'paid').length;
    final pending = total - paid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          Icons.calendar_month,
          color: Colors.teal,
        ),
        title: Text(
          first.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$accountName • ${first.amount.toStringAsFixed(2)} ${widget.currency}\n'
          'Оплачено: $paid из $total',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit_series') {
              _editSeries(seriesId, seriesPayments);
            } else if (value == 'delete_series') {
              _deleteSeries(seriesId, seriesPayments);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit_series',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Редактировать серию'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete_series',
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Удалить серию'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        children: [
          ...seriesPayments.map((p) {
            final isPaid = p.status == 'paid';
            return ListTile(
              dense: true,
              onTap: () => _editSinglePayment(p),
              leading: Icon(
                isPaid ? Icons.check_circle : Icons.schedule,
                color: isPaid ? Colors.green : Colors.grey,
                size: 20,
              ),
              title: Text(
                '${p.dueDate.day}.${p.dueDate.month}.${p.dueDate.year}',
                style: TextStyle(
                  fontWeight: isPaid ? FontWeight.normal : FontWeight.w500,
                  color: isPaid ? Colors.grey : null,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${p.amount.toStringAsFixed(2)} ${widget.currency}',
                    style: TextStyle(
                      color: isPaid ? Colors.grey : Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isPaid)
                    IconButton(
                      icon: Icon(Icons.payment, size: 20, color: Colors.green),
                      tooltip: 'Оплатить',
                      onPressed: () => widget.onPayNow(p),
                    ),
                ],
              ),
            );
          }).toList(),
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Ещё $pending платеж(ей) впереди',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  // ============ РЕДАКТИРОВАНИЕ / УДАЛЕНИЕ СЕРИИ ============

  Future<void> _deleteSeries(
      String seriesId, List<Payment> seriesPayments) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить серию?'),
        content: Text(
          'Будет удалено ${seriesPayments.length} платеж(ей) серии "${seriesPayments.first.name}". '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final p in seriesPayments) {
        widget.onDelete(p);
      }
    }
  }

  Future<void> _editSeries(
      String seriesId, List<Payment> seriesPayments) async {
    final first = seriesPayments.first;
    final pendingPayments =
        seriesPayments.where((p) => p.status != 'paid').toList();
    if (pendingPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все платежи серии уже оплачены')),
      );
      return;
    }

    final nameController = TextEditingController(text: first.name);
    final amountController =
        TextEditingController(text: first.amount.toStringAsFixed(2));
    String selectedFromAccountId = first.fromAccountId;
    String selectedToAccountId = first.toAccountId;
    String selectedCategory = first.category;
    String? selectedSubCategory = first.subCategory;
    String frequency = first.frequency;
    int interval = first.interval;
    DateTime startDate = pendingPayments.first.dueDate;
    int count = pendingPayments.length;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Редактировать серию'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Сумма',
                    prefixText: '${widget.currency} ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedFromAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Счёт',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedFromAccountId = v!),
                ),
                if (first.isIncome ||
                    first.fromAccountId != first.toAccountId) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedToAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Счёт зачисления',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedToAccountId = v!),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Периодичность',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Ежедневно')),
                    DropdownMenuItem(
                        value: 'weekly', child: Text('Каждую неделю')),
                    DropdownMenuItem(
                        value: 'biweekly', child: Text('Раз в 2 недели')),
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Каждый месяц')),
                    DropdownMenuItem(
                        value: 'yearly', child: Text('Каждый год')),
                  ],
                  onChanged: (v) => setState(() => frequency = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Интервал (1 = каждый период)',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: interval.toString()),
                  onChanged: (v) => interval = int.tryParse(v) ?? 1,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Дата начала: ${startDate.day}.${startDate.month}.${startDate.year}',
                  ),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => startDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Количество платежей',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: count.toString()),
                  onChanged: (v) => count = int.tryParse(v) ?? 12,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final newName = nameController.text.trim();
    final newAmount = _parseAmount(amountController.text);
    if (newName.isEmpty || newAmount <= 0) return;

    // 1. Удаляем все pending-платежи
    for (final p in pendingPayments) {
      widget.onDelete(p);
    }

    // 2. Генерируем новые по новому шаблону
    final schedule = PaymentSchedule.fromPattern(
      startDate: startDate,
      frequency: frequency,
      interval: interval,
      count: count,
    );

    final newSeriesId = DateTime.now().millisecondsSinceEpoch.toString();
    for (int i = 0; i < schedule.dates.length; i++) {
      widget.onAdd(Payment(
        id: '${newSeriesId}_$i',
        seriesId: newSeriesId,
        name: newName,
        amount: newAmount,
        isIncome: first.isIncome,
        category: selectedCategory,
        subCategory: selectedSubCategory,
        fromAccountId: selectedFromAccountId,
        toAccountId: selectedToAccountId,
        dueDate: schedule.dates[i],
        status: 'pending',
        frequency: frequency,
        interval: interval,
        iconPath: first.iconPath,
        color: first.color,
      ));
    }
  }

  Future<void> _editSinglePayment(Payment payment) async {
    final isPaid = payment.status == 'paid';

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${payment.name} — ${payment.dueDate.day}.${payment.dueDate.month}.${payment.dueDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            if (!isPaid)
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: const Text('Оплатить сейчас'),
                onTap: () {
                  Navigator.pop(context, 'pay');
                },
              ),
            if (!isPaid)
              ListTile(
                leading: const Icon(Icons.edit_calendar, color: Colors.blue),
                title: const Text('Изменить дату'),
                onTap: () {
                  Navigator.pop(context, 'edit_date');
                },
              ),
            if (!isPaid)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Изменить сумму'),
                onTap: () {
                  Navigator.pop(context, 'edit_amount');
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить этот платёж'),
              onTap: () {
                Navigator.pop(context, 'delete');
              },
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == 'pay') {
      widget.onPayNow(payment);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить платёж?'),
          content: Text('${payment.name} от '
              '${payment.dueDate.day}.${payment.dueDate.month}.${payment.dueDate.year}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Удалить', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        widget.onDelete(payment);
      }
    } else if (action == 'edit_date') {
      final picked = await showDatePicker(
        context: context,
        initialDate: payment.dueDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        widget.onUpdate(payment, payment.copyWith(dueDate: picked));
      }
    } else if (action == 'edit_amount') {
      final controller = TextEditingController(
        text: payment.amount.toStringAsFixed(2),
      );
      final newAmount = await showDialog<double>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Изменить сумму'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '${widget.currency} ',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, _parseAmount(controller.text)),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      );
      if (newAmount != null && newAmount > 0) {
        widget.onUpdate(payment, payment.copyWith(amount: newAmount));
      }
    }
  }

  Widget _buildPaymentCard(Payment payment) {
    final nextDate = payment.dueDate;
    final isOverdue = _isOverdue(nextDate);
    final isSoon = _isSoon(nextDate);
    final isPaid = payment.status == 'paid';

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
    // Логика:
    // - Доход: 1 иконка (счёт зачисления)
    // - Расход (услуга): 1 иконка (счёт списания)
    // - Перевод: 2 иконки (откуда → куда)

    final isTransfer = payment.fromAccountId != payment.toAccountId;

    // === ПЕРЕВОД: две иконки ===
    if (isTransfer) {
      return SizedBox(
        width: 90,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallAccountIcon(payment.fromAccountId, size: 36),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.arrow_forward,
                size: 14,
                color: Colors.blue.shade400,
              ),
            ),
            _buildSmallAccountIcon(payment.toAccountId, size: 36),
          ],
        ),
      );
    }

    // === ДОХОД: иконка счёта зачисления ===
    if (payment.isIncome) {
      return _buildSmallAccountIcon(payment.toAccountId, size: 45);
    }

    // === РАСХОД: иконка счёта списания ===
    return _buildSmallAccountIcon(payment.fromAccountId, size: 45);
  }

  Widget _buildSmallAccountIcon(String accountId, {double size = 40}) {
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

    String frequency = 'monthly';
    int interval = 1;
    int dayOfWeek = 1;

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

                // Генерируем серию платежей из всех дат графика
                final seriesId =
                    DateTime.now().millisecondsSinceEpoch.toString();
                for (int i = 0; i < schedule.dates.length; i++) {
                  final date = schedule.dates[i];
                  widget.onAdd(Payment(
                    id: '${seriesId}_$i',
                    seriesId: seriesId,
                    name: name,
                    amount: amount,
                    isIncome: isIncome,
                    category: selectedCategory!,
                    subCategory: selectedSubCategory,
                    fromAccountId: finalFromAccountId,
                    toAccountId: finalToAccountId,
                    dueDate: date,
                    status: 'pending',
                    frequency: frequency,
                    interval: interval,
                    iconPath: null,
                    color: null,
                  ));
                }

                Navigator.pop(context);
              },
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromJson() async {
    try {
      // 1. Выбор файла
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final content = utf8.decode(bytes);
      final List<dynamic> parsed = jsonDecode(content);

      // 2. Парсим в список (date, amount)
      final items = <Map<String, dynamic>>[];
      for (final item in parsed) {
        final date = DateTime.tryParse(item['date'] ?? '');
        final amount = (item['amount'] ?? 0).toDouble();
        if (date != null && amount > 0) {
          items.add({'date': date, 'amount': amount});
        }
      }
      if (items.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не содержит корректных данных')),
        );
        return;
      }

      // 3. Диалог: название, счёт, категория, тип
      final nameController = TextEditingController(
        text: result.files.first.name.replaceAll('.json', ''),
      );
      String selectedFromAccountId =
          widget.accounts.isNotEmpty ? widget.accounts.first.id : '';
      String selectedCategory = widget.expenseCategories.isNotEmpty
          ? widget.expenseCategories.first.name
          : 'Другое';
      bool isIncome = false;
      String expenseType = 'service'; // service | transfer

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Импорт платежей'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Найдено ${items.length} платежей',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название серии',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedFromAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Счёт',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedFromAccountId = v!),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Расход')),
                      ButtonSegment(value: 'income', label: Text('Доход')),
                    ],
                    selected: {isIncome ? 'income' : 'expense'},
                    onSelectionChanged: (v) =>
                        setState(() => isIncome = v.first == 'income'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                    items: (isIncome
                            ? widget.incomeCategories
                            : widget.expenseCategories)
                        .map((c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Импортировать'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true) return;

      final name = nameController.text.trim();
      if (name.isEmpty || selectedFromAccountId.isEmpty) return;

      // 4. Проверка: есть ли уже серия с таким названием + счёт
      final existingSeries = <Payment>[];
      for (final p in widget.payments) {
        if (p.name == name && p.fromAccountId == selectedFromAccountId) {
          existingSeries.add(p);
        }
      }

      // 5. Если есть — спросить про замену
      if (existingSeries.isNotEmpty) {
        final pendingExisting =
            existingSeries.where((p) => p.status != 'paid').toList();
        if (!mounted) return;
        final replace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Серия уже существует'),
            content: Text(
              'Серия "$name" уже есть (${existingSeries.length} платежей, '
              '${existingSeries.where((p) => p.status == 'paid').length} оплачено).\n\n'
              'Заменить ${pendingExisting.length} ожидающих платежей?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Заменить'),
              ),
            ],
          ),
        );
        if (replace != true) return;

        // Удаляем только pending
        for (final p in pendingExisting) {
          widget.onDelete(p);
        }
      }

      // 6. Создаём новые платежи из файла
      final newSeriesId = DateTime.now().millisecondsSinceEpoch.toString();
      final toAccountId = isIncome || expenseType == 'transfer'
          ? selectedFromAccountId
          : selectedFromAccountId;

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        widget.onAdd(Payment(
          id: '${newSeriesId}_$i',
          seriesId: newSeriesId,
          name: name,
          amount: item['amount'],
          isIncome: isIncome,
          category: selectedCategory,
          subCategory: null,
          fromAccountId: selectedFromAccountId,
          toAccountId: toAccountId,
          dueDate: item['date'],
          status: 'pending',
          frequency: 'monthly',
          interval: 1,
          iconPath: null,
          color: null,
        ));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импортировано ${items.length} платежей')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка импорта: $e')),
      );
    }
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
    String frequency = payment.frequency;
    DateTime startDate = payment.dueDate;

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
                    dueDate: newSchedule.nextDate ?? DateTime.now(),
                    status: 'pending',
                    frequency: frequency,
                    interval: 1,
                    iconPath: null,
                    color: null,
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
