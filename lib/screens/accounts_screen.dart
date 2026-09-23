import 'package:flutter/material.dart';
import '../models.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class AccountsScreen extends StatefulWidget {
  final List<Account> accounts;
  final String currency;
  final Function(Account) onAddAccount;
  final Function(Account) onDeleteAccount;
  final Function(Account, Account) onUpdateAccount;
  final Function(Account) onEditAccount;
  final Function(List<Account>) onReorderAccounts;
  final List<Map<String, String>> accountColors;
  final List<Map<String, dynamic>> accountIcons;

  const AccountsScreen({
    Key? key,
    required this.accounts,
    required this.currency,
    required this.onAddAccount,
    required this.onDeleteAccount,
    required this.onUpdateAccount,
    required this.onEditAccount,
    required this.onReorderAccounts,
    required this.accountColors,
    required this.accountIcons,
  }) : super(key: key);

  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    // Сортируем счета по order
    final sortedAccounts = List<Account>.from(widget.accounts)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade50,
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
      ),
      child: ReorderableListView(
        padding: EdgeInsets.all(16),
        header: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.withOpacity(0.35),
                    Colors.blue.withOpacity(0.35),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Баланс по дебетовым картам и наличке',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                      '${_getDebitTotal().toStringAsFixed(2)} ${widget.currency}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.35),
                    Colors.deepOrange.withOpacity(0.35),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Долг по кредиткам',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                      '${_getCreditDebt().toStringAsFixed(2)} ${widget.currency}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Мои счета',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.teal, size: 30),
                  onPressed: _showAddDialog,
                ),
              ],
            ),
            SizedBox(height: 8),
          ],
        ),
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }

          final reordered = List<Account>.from(sortedAccounts);
          final moved = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, moved);

          for (int i = 0; i < reordered.length; i++) {
            reordered[i] = reordered[i].copyWith(order: i);
          }

          widget.onReorderAccounts(reordered);
        },
        children: [
          for (int i = 0; i < sortedAccounts.length; i++)
            _buildAccountCard(sortedAccounts[i], i),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account, int index) {
    return Card(
      key: ValueKey(account.id),
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => widget.onEditAccount(account),
        onLongPress: () => _showAccountMenu(account),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getColorFromHex(account.color).withOpacity(0.35),
                _getColorFromHex(account.color).withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              account.iconPath != null && account.iconPath!.isNotEmpty
                  ? Container(
                      width: 45,
                      height: 45,
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Image.asset(account.iconPath!, fit: BoxFit.contain),
                    )
                  : Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getAccountIcon(account.icon),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    if (account.bank.isNotEmpty)
                      Text(account.bank,
                          style: TextStyle(color: Colors.white70)),
                    if (account.cardNumber.isNotEmpty)
                      Text(account.cardNumber,
                          style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 16),
                    Text(
                      '${account.balance.toStringAsFixed(2)} ${widget.currency}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    if (account.type == 'credit') ...[
                      Text(
                        'Лимит: ${account.creditLimit.toStringAsFixed(0)} ${widget.currency}',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Долг: ${(account.creditLimit - account.balance).toStringAsFixed(2)} ${widget.currency}',
                        style: TextStyle(
                            color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              if (!kIsWeb)
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountMenu(Account account) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  account.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEditAccount(account);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _confirmDelete(account);
                  if (confirmed) {
                    widget.onDeleteAccount(account);
                  }
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(Account account) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить счёт?'),
          content: Text(
              '${account.name}\nВсе связанные операции также будут удалены.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final bankController = TextEditingController();
    final balanceController = TextEditingController();
    String accountType = 'cash';
    String selectedColor = '#4CAF50';
    String selectedIcon = 'wallet';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Добавить счёт'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton(
                      segments: [
                        ButtonSegment(
                            value: 'cash',
                            label: Text('Наличные'),
                            icon: Icon(Icons.money)),
                        ButtonSegment(
                            value: 'debit',
                            label: Text('Дебетовая'),
                            icon: Icon(Icons.credit_card)),
                        ButtonSegment(
                            value: 'credit',
                            label: Text('Кредитная'),
                            icon: Icon(Icons.credit_score)),
                      ],
                      selected: {accountType},
                      onSelectionChanged: (value) {
                        setState(() {
                          accountType = value.first;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                          labelText: 'Название счёта',
                          border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 12),
                    if (accountType != 'cash')
                      TextField(
                        controller: bankController,
                        decoration: InputDecoration(
                            labelText: 'Банк', border: OutlineInputBorder()),
                      ),
                    SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Начальный баланс',
                        prefixText: '${widget.currency} ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Цвет:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: widget.accountColors.map((color) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedColor = color['hex']!;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getColorFromHex(color['hex']!),
                              shape: BoxShape.circle,
                              border: selectedColor == color['hex']
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Text('Иконка:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: widget.accountIcons.map((iconData) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIcon = iconData['name'] as String;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedIcon == iconData['name']
                                  ? Colors.teal.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: selectedIcon == iconData['name']
                                  ? Border.all(color: Colors.teal, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              iconData['icon'] as IconData,
                              color: selectedIcon == iconData['name']
                                  ? Colors.teal
                                  : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
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
                    final balance =
                        double.tryParse(balanceController.text) ?? 0;
                    if (name.isEmpty) return;

                    widget.onAddAccount(Account(
                      id: DateTime.now().toString(),
                      name: name,
                      type: accountType,
                      balance: balance,
                      bank: bankController.text.trim(),
                      color: selectedColor,
                      icon: selectedIcon,
                    ));
                    Navigator.pop(context);
                  },
                  child: Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getAccountIcon(String iconName) {
    for (var iconData in widget.accountIcons) {
      if (iconData['name'] == iconName) {
        return iconData['icon'] as IconData;
      }
    }
    return Icons.account_balance_wallet;
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  double _getDebitTotal() {
    double total = 0;
    for (var account in widget.accounts) {
      if (account.type != 'credit') {
        total += account.balance;
      }
    }
    return total;
  }

  double _getCreditDebt() {
    double debt = 0;
    for (var account in widget.accounts) {
      if (account.type == 'credit') {
        debt += account.creditLimit - account.balance;
      }
    }
    return debt;
  }
}
