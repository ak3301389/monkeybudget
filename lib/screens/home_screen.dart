import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';
import '../services/scanner_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'transactions_screen.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'payments_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import '../payment_schedule.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final BackupService backupService;
  final VoidCallback? onThemeChanged;

  const HomeScreen({
    Key? key,
    required this.storageService,
    required this.backupService,
    this.onThemeChanged,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Account> accounts = [];
  List<Transaction> transactions = [];
  List<Category> expenseCategories = [];
  List<Category> incomeCategories = [];
  List<Category> transferCategories = [];
  List<SubCategory> transferSubCategories = [];
  List<SubCategory> expenseSubCategories = [];
  List<SubCategory> incomeSubCategories = [];
  List<Payment> payments = [];

  String currency = '₽';
  bool showNotifications = true;
  bool isDarkMode = false;
  int currentView = 0;

  final List<Map<String, String>> accountColors = [
    {'name': 'Бирюзовый', 'hex': '#00897B'},
    {'name': 'Синий', 'hex': '#2196F3'},
    {'name': 'Зелёный', 'hex': '#4CAF50'},
    {'name': 'Оранжевый', 'hex': '#FF9800'},
    {'name': 'Фиолетовый', 'hex': '#9C27B0'},
    {'name': 'Красный', 'hex': '#F44336'},
    {'name': 'Розовый', 'hex': '#E91E63'},
    {'name': 'Коричневый', 'hex': '#795548'},
    {'name': 'Индиго', 'hex': '#3F51B5'},
    {'name': 'Голубой', 'hex': '#03A9F4'},
    {'name': 'Лаймовый', 'hex': '#CDDC39'},
    {'name': 'Янтарный', 'hex': '#FFC107'},
    {'name': 'Глубокий оранжевый', 'hex': '#FF5722'},
    {'name': 'Тёмно-фиолетовый', 'hex': '#673AB7'},
    {'name': 'Серо-голубой', 'hex': '#607D8B'},
    {'name': 'Изумрудный', 'hex': '#009688'},
  ];

  final List<Map<String, dynamic>> accountIcons = [
    {'name': 'wallet', 'icon': Icons.account_balance_wallet},
    {'name': 'cash', 'icon': Icons.money},
    {'name': 'card', 'icon': Icons.credit_card},
    {'name': 'bank', 'icon': Icons.account_balance},
    {'name': 'piggy', 'icon': Icons.savings},
    {'name': 'phone', 'icon': Icons.phone_android},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'car', 'icon': Icons.directions_car},
    {'name': 'food', 'icon': Icons.restaurant},
    {'name': 'shopping', 'icon': Icons.shopping_cart},
    {'name': 'travel', 'icon': Icons.flight},
    {'name': 'health', 'icon': Icons.local_hospital},
  ];

  final List<Map<String, dynamic>> categoryIcons = [
    {'name': 'shopping', 'icon': Icons.shopping_cart},
    {'name': 'food', 'icon': Icons.restaurant},
    {'name': 'transport', 'icon': Icons.directions_bus},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'fun', 'icon': Icons.movie},
    {'name': 'health', 'icon': Icons.local_hospital},
    {'name': 'clothes', 'icon': Icons.checkroom},
    {'name': 'phone', 'icon': Icons.phone},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'money', 'icon': Icons.attach_money},
    {'name': 'gift', 'icon': Icons.card_giftcard},
    {'name': 'education', 'icon': Icons.school},
    {'name': 'pets', 'icon': Icons.pets},
    {'name': 'sport', 'icon': Icons.fitness_center},
    {'name': 'travel', 'icon': Icons.flight},
    {'name': 'car', 'icon': Icons.directions_car},
    {'name': 'fuel', 'icon': Icons.local_gas_station},
    {'name': 'bus', 'icon': Icons.directions_bus_filled},
    {'name': 'train', 'icon': Icons.train},
    {'name': 'flight', 'icon': Icons.airplanemode_active},
    {'name': 'hotel', 'icon': Icons.hotel},
    {'name': 'restaurant', 'icon': Icons.fastfood},
    {'name': 'coffee', 'icon': Icons.coffee},
    {'name': 'beer', 'icon': Icons.local_bar},
    {'name': 'wine', 'icon': Icons.wine_bar},
    {'name': 'cake', 'icon': Icons.cake},
    {'name': 'icecream', 'icon': Icons.icecream},
    {'name': 'groceries', 'icon': Icons.local_grocery_store},
    {'name': 'market', 'icon': Icons.storefront},
    {'name': 'pharmacy', 'icon': Icons.local_pharmacy},
    {'name': 'doctor', 'icon': Icons.medical_services},
    {'name': 'hospital', 'icon': Icons.local_hospital},
    {'name': 'medicine', 'icon': Icons.medication},
    {'name': 'fitness', 'icon': Icons.sports_gymnastics},
    {'name': 'gym', 'icon': Icons.sports_martial_arts},
    {'name': 'swimming', 'icon': Icons.pool},
    {'name': 'bike', 'icon': Icons.directions_bike},
    {'name': 'run', 'icon': Icons.directions_run},
    {'name': 'game', 'icon': Icons.sports_esports},
    {'name': 'football', 'icon': Icons.sports_soccer},
    {'name': 'basketball', 'icon': Icons.sports_basketball},
    {'name': 'tennis', 'icon': Icons.sports_tennis},
    {'name': 'music', 'icon': Icons.music_note},
    {'name': 'concert', 'icon': Icons.queue_music},
    {'name': 'theater', 'icon': Icons.theater_comedy},
    {'name': 'book', 'icon': Icons.menu_book},
    {'name': 'library', 'icon': Icons.local_library},
    {'name': 'school', 'icon': Icons.school},
    {'name': 'computer', 'icon': Icons.computer},
    {'name': 'laptop', 'icon': Icons.laptop},
    {'name': 'keyboard', 'icon': Icons.keyboard},
    {'name': 'mouse', 'icon': Icons.mouse},
    {'name': 'headphones', 'icon': Icons.headphones},
    {'name': 'camera', 'icon': Icons.camera_alt},
    {'name': 'tv', 'icon': Icons.tv},
    {'name': 'movie', 'icon': Icons.local_movies},
    {'name': 'baby', 'icon': Icons.child_care},
    {'name': 'child', 'icon': Icons.child_friendly},
    {'name': 'elderly', 'icon': Icons.elderly},
    {'name': 'family', 'icon': Icons.family_restroom},
    {'name': 'man', 'icon': Icons.man},
    {'name': 'woman', 'icon': Icons.woman},
    {'name': 'cut', 'icon': Icons.content_cut},
    {'name': 'beauty', 'icon': Icons.face_retouching_natural},
    {'name': 'spa', 'icon': Icons.spa},
    {'name': 'nail', 'icon': Icons.back_hand},
    {'name': 'tools', 'icon': Icons.handyman},
    {'name': 'repair', 'icon': Icons.build},
    {'name': 'paint', 'icon': Icons.format_paint},
    {'name': 'garden', 'icon': Icons.yard},
    {'name': 'plant', 'icon': Icons.local_florist},
    {'name': 'light', 'icon': Icons.lightbulb},
    {'name': 'water', 'icon': Icons.water_drop},
    {'name': 'electric', 'icon': Icons.bolt},
    {'name': 'gas', 'icon': Icons.local_fire_department},
    {'name': 'wifi', 'icon': Icons.wifi},
    {'name': 'internet', 'icon': Icons.language},
    {'name': 'cloud', 'icon': Icons.cloud},
    {'name': 'security', 'icon': Icons.security},
    {'name': 'key', 'icon': Icons.key},
    {'name': 'lock', 'icon': Icons.lock},
    {'name': 'bank', 'icon': Icons.account_balance},
    {'name': 'card', 'icon': Icons.credit_card},
    {'name': 'cash', 'icon': Icons.payments},
    {'name': 'wallet', 'icon': Icons.wallet},
    {'name': 'invest', 'icon': Icons.trending_up},
    {'name': 'savings', 'icon': Icons.savings},
    {'name': 'charity', 'icon': Icons.volunteer_activism},
    {'name': 'donation', 'icon': Icons.favorite},
    {'name': 'tax', 'icon': Icons.receipt_long},
    {'name': 'insurance', 'icon': Icons.shield},
    {'name': 'loan', 'icon': Icons.account_balance_wallet},
    {'name': 'mortgage', 'icon': Icons.house},
    {'name': 'rent', 'icon': Icons.apartment},
    {'name': 'furniture', 'icon': Icons.chair},
    {'name': 'kitchen', 'icon': Icons.kitchen},
    {'name': 'bath', 'icon': Icons.bathtub},
    {'name': 'bed', 'icon': Icons.bed},
    {'name': 'washer', 'icon': Icons.local_laundry_service},
    {'name': 'clean', 'icon': Icons.cleaning_services},
    {'name': 'pets_food', 'icon': Icons.pets},
    {'name': 'vet', 'icon': Icons.vaccines},
    {'name': 'grooming', 'icon': Icons.spa},
    {'name': 'subscription', 'icon': Icons.subscriptions},
    {'name': 'news', 'icon': Icons.newspaper},
    {'name': 'magazine', 'icon': Icons.menu_book},
    {'name': 'streaming', 'icon': Icons.play_circle},
    {'name': 'music_stream', 'icon': Icons.library_music},
    {'name': 'app', 'icon': Icons.apps},
    {'name': 'software', 'icon': Icons.terminal},
    {'name': 'domain', 'icon': Icons.public},
    {'name': 'server', 'icon': Icons.dns},
    {'name': 'storage', 'icon': Icons.storage},
    {'name': 'print', 'icon': Icons.print},
    {'name': 'shipping', 'icon': Icons.local_shipping},
    {'name': 'package', 'icon': Icons.inventory},
    {'name': 'mail', 'icon': Icons.mail},
    {'name': 'chat', 'icon': Icons.chat},
    {'name': 'call', 'icon': Icons.call},
    {'name': 'sms', 'icon': Icons.sms},
    {'name': 'other', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _autoSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdates();
    });
  }

  Future<void> _checkUpdates() async {
    try {
      final update = await UpdateService.checkForUpdate();
      if (update != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => UpdateDialog(
            version: update['version'],
            buildNumber: update['build'],
            url: update['url'],
            apkUrl: update['apkUrl'],
            notes: update['notes'],
          ),
        );
      }
    } catch (e) {
      print('❌ Ошибка проверки обновлений: $e');
    }
  }

  Future<void> _autoSync() async {
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      final backupService = widget.backupService;
      await backupService.restoreFromFirebase();
      _loadData();
      _checkUpcomingPayments();
    }
  }

  void _checkUpcomingPayments() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    final upcoming = payments.where((p) {
      final nextDate = p.schedule.nextDate;
      if (nextDate == null) return false;
      final date = DateTime(nextDate.year, nextDate.month, nextDate.day);
      return date == today || date == tomorrow;
    }).toList();

    if (upcoming.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('💰 Предстоящие платежи'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: upcoming.map((p) {
              final nextDate = p.schedule.nextDate!;
              final isToday =
                  DateTime(nextDate.year, nextDate.month, nextDate.day) ==
                      today;
              final type = p.isIncome ? 'Доход' : 'Платёж';
              return ListTile(
                leading: Icon(
                  p.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: p.isIncome ? Colors.green : Colors.red,
                ),
                title: Text(p.name),
                subtitle: Text('${isToday ? 'Сегодня' : 'Завтра'} • $type'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {
                        _addTransaction(Transaction(
                          id: DateTime.now().toString(),
                          amount: p.amount,
                          category: p.category,
                          isIncome: p.isIncome,
                          note: p.name,
                          date: DateTime.now(),
                          accountId: p.toAccountId,
                        ));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '✅ ${p.isIncome ? 'Доход добавлен' : 'Платёж проведён'}')),
                        );
                      },
                    ),
                    Text('${p.amount} $currency',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Позже')),
          ],
        );
      },
    );
  }

  void _loadData() {
    setState(() {
      accounts = widget.storageService.loadAccounts();
      transactions = widget.storageService.loadTransactions();
      expenseCategories = widget.storageService.loadExpenseCategories();
      incomeCategories = widget.storageService.loadIncomeCategories();
      expenseSubCategories = widget.storageService.loadExpenseSubCategories();
      incomeSubCategories = widget.storageService.loadIncomeSubCategories();
      payments = widget.storageService.loadPayments();
      currency = widget.storageService.getCurrency();
      showNotifications = widget.storageService.getShowNotifications();
      isDarkMode = widget.storageService.getIsDarkMode();

      if (accounts.isEmpty) {
        accounts = [
          Account(
              id: '1',
              name: 'Наличные',
              type: 'cash',
              balance: 0,
              color: '#4CAF50',
              icon: 'cash'),
          Account(
              id: '2',
              name: 'Дебетовая карта',
              type: 'debit',
              balance: 0,
              bank: 'Сбербанк',
              color: '#2196F3',
              icon: 'card'),
        ];
        widget.storageService.saveAccounts(accounts);
      }

      if (expenseCategories.isEmpty) {
        expenseCategories = [
          Category('Продукты', Icons.shopping_cart, '#FF5722'),
          Category('Транспорт', Icons.directions_bus, '#2196F3'),
          Category('Кафе', Icons.restaurant, '#FF9800'),
          Category('Жильё', Icons.home, '#9C27B0'),
        ];
        widget.storageService.saveExpenseCategories(expenseCategories);
      }

      if (incomeCategories.isEmpty) {
        incomeCategories = [
          Category('Зарплата', Icons.work, '#4CAF50'),
          Category('Подработка', Icons.timer, '#8BC34A'),
        ];
        widget.storageService.saveIncomeCategories(incomeCategories);
      }
      final transferCategoriesJson =
          widget.storageService.getString('transfer_categories');
      if (transferCategoriesJson != null) {
        transferCategories = (jsonDecode(transferCategoriesJson) as List)
            .map((c) => Category.fromJson(c))
            .toList();
      } else {
        transferCategories = [
          Category('Перевод на карту', Icons.credit_card, '#2196F3'),
          Category('Перевод на счёт', Icons.account_balance, '#4CAF50'),
          Category('Погашение кредита', Icons.payment, '#FF9800'),
        ];
        widget.storageService.setString('transfer_categories',
            jsonEncode(transferCategories.map((c) => c.toJson()).toList()));
      }
    });

    if (accounts.isEmpty && transactions.isEmpty) {
      _checkLocalBackups();
    }
  }

  Future<void> _checkLocalBackups() async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) return;

      final files = directory
          .listSync()
          .where((f) =>
              f is File &&
              f.path.contains('backup_') &&
              f.path.endsWith('.json'))
          .toList()
          .cast<File>();

      if (files.isEmpty) return;

      files.sort((a, b) => b.path.compareTo(a.path));

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Найдена резервная копия'),
            content: Text(
                'Восстановить данные из файла?\n\n${files.first.path.split('/').last}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Нет'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await widget.backupService
                      .restoreFromFile(files.first.path);
                  if (success) {
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Данные восстановлены!')),
                    );
                  }
                },
                child: Text('Да'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Backup check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💰 Домашняя бухгалтерия'),
        actions: [
          IconButton(
            icon: Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatsScreen(
                    transactions: transactions,
                    accounts: accounts,
                    currency: currency,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: currentView == 0
          ? TransactionsScreen(
              transactions: transactions,
              accounts: accounts,
              expenseCategories: expenseCategories,
              incomeCategories: incomeCategories,
              expenseSubCategories: expenseSubCategories,
              incomeSubCategories: incomeSubCategories,
              currency: currency,
              storageService: widget.storageService,
              onAddTransaction: _addTransaction,
              onUpdateTransaction: _updateTransaction,
              onDeleteTransaction: _deleteTransaction,
              onAddIncomeCategory: _addIncomeCategory,
              onAddExpenseCategory: _addExpenseCategory,
            )
          : currentView == 1
              ? AccountsScreen(
                  accounts: accounts,
                  currency: currency,
                  onAddAccount: _addAccount,
                  onDeleteAccount: _deleteAccount,
                  onUpdateAccount: _updateAccount,
                  onEditAccount: _showEditAccountDialog,
                  onReorderAccounts: _reorderAccounts,
                  accountColors: accountColors,
                  accountIcons: accountIcons,
                )
              : currentView == 2
                  ? PaymentsScreen(
                      payments: payments,
                      accounts: accounts,
                      expenseCategories: expenseCategories,
                      incomeCategories: incomeCategories,
                      incomeSubCategories: incomeSubCategories,
                      expenseSubCategories: expenseSubCategories,
                      currency: currency,
                      onAdd: _addPayment,
                      onUpdate: _updatePayment,
                      onDelete: _deletePayment,
                      onPayNow: _onPayNow,
                    )
                  : currentView == 3
                      ? CategoriesScreen(
                          expenseCategories: expenseCategories,
                          incomeCategories: incomeCategories,
                          transferCategories: transferCategories,
                          transferSubCategories: transferSubCategories,
                          expenseSubCategories: expenseSubCategories,
                          incomeSubCategories: incomeSubCategories,
                          onAddExpenseCategory: _addExpenseCategory,
                          onAddIncomeCategory: _addIncomeCategory,
                          onDeleteExpenseCategory: _deleteExpenseCategory,
                          onDeleteIncomeCategory: _deleteIncomeCategory,
                          onAddTransferCategory: _addTransferCategory,
                          onDeleteTransferCategory: _deleteTransferCategory,
                          onAddTransferSubCategory: _addTransferSubCategory,
                          onDeleteTransferSubCategory:
                              _deleteTransferSubCategory,
                          onAddExpenseSubCategory: _addExpenseSubCategory,
                          onAddIncomeSubCategory: _addIncomeSubCategory,
                          onDeleteExpenseSubCategory: _deleteExpenseSubCategory,
                          onDeleteIncomeSubCategory: _deleteIncomeSubCategory,
                          categoryIcons: categoryIcons,
                        )
                      : SettingsScreen(
                          storageService: widget.storageService,
                          backupService: widget.backupService,
                          currency: currency,
                          showNotifications: showNotifications,
                          isDarkMode: isDarkMode,
                          onCurrencyChanged: _changeCurrency,
                          onNotificationsChanged: _changeNotifications,
                          onDarkModeChanged: _changeDarkMode,
                          onClearAll: _clearAll,
                        ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentView < 5 ? currentView : 0,
        onDestinationSelected: (index) {
          setState(() {
            currentView = index;
          });
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.receipt), label: 'Операции'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet), label: 'Счета'),
          NavigationDestination(icon: Icon(Icons.repeat), label: 'Платежи'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Категории'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
      floatingActionButton: currentView == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _showAddTransactionDialog();
              },
              icon: Icon(Icons.add),
              label: Text('Операция'),
            )
          : currentView == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    _showAddAccountDialog();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Счёт'),
                )
              : null,
    );
  }

  void _showAddTransactionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Добавить операцию',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTypeButton(
                        'income', 'Доход', Icons.arrow_downward, Colors.green),
                    _buildTypeButton(
                        'expense', 'Расход', Icons.arrow_upward, Colors.red),
                    _buildTypeButton(
                        'transfer', 'Перевод', Icons.swap_horiz, Colors.blue),
                    _buildTypeButton(
                        'scan', 'Сканер', Icons.qr_code_scanner, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeButton(
      String type, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (type == 'transfer') {
          _showTransferDialog();
        } else if (type == 'scan') {
          _showScannerDialog();
        } else {
          _showIncomeExpenseDialog(type == 'income');
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  void _showIncomeExpenseDialog(bool isIncome) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedAccountId = widget.storageService.loadLastAccountId() ??
        (accounts.isNotEmpty ? accounts[0].id : '');
    String? selectedCategory = widget.storageService.loadLastCategory();
    String? selectedSubCategory;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isIncome ? 'Добавить доход' : 'Добавить расход'),
              content: SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField(
                      value: selectedAccountId,
                      decoration: InputDecoration(labelText: 'Счёт'),
                      items: accounts.map((account) {
                        return DropdownMenuItem(
                            value: account.id, child: Text(account.name));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAccountId = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onTap: () {
                        _hideKeyboard();
                        Future.delayed(Duration(milliseconds: 50), () {
                          SystemChannels.textInput
                              .invokeMethod('TextInput.show');
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Сумма (например: 100+50+25)',
                        prefixText: '$currency ',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calculate),
                          onPressed: () => _showCalculator(amountController),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Autocomplete<String>(
                      initialValue:
                          TextEditingValue(text: selectedCategory ?? ''),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        final categories =
                            isIncome ? incomeCategories : expenseCategories;
                        return categories.map((c) => c.name).where((name) =>
                            name
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (value) {
                        setState(() {
                          selectedCategory = value;
                          selectedSubCategory = null;
                        });
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.text,
                          onTap: () {
                            _hideKeyboard();
                            Future.delayed(Duration(milliseconds: 50), () {
                              SystemChannels.textInput
                                  .invokeMethod('TextInput.show');
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Категория',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            selectedCategory = value;
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              final categories = isIncome
                                  ? incomeCategories
                                  : expenseCategories;
                              final exists =
                                  categories.any((c) => c.name == value);
                              if (!exists) {
                                setState(() {
                                  if (isIncome) {
                                    incomeCategories.add(
                                        Category(value, Icons.work, '#4CAF50'));
                                    widget.storageService
                                        .saveIncomeCategories(incomeCategories);
                                  } else {
                                    expenseCategories.add(Category(
                                        value, Icons.category, '#607D8B'));
                                    widget.storageService.saveExpenseCategories(
                                        expenseCategories);
                                  }
                                });
                              }
                              selectedCategory = value;
                            }
                          },
                        );
                      },
                    ),
                    if (selectedCategory != null)
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          final subs = (isIncome
                                  ? incomeSubCategories
                                  : expenseSubCategories)
                              .where((s) => s.parentName == selectedCategory)
                              .map((s) => s.name);
                          if (textEditingValue.text.isEmpty) return subs;
                          return subs.where((name) => name
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (value) {
                          setState(() {
                            selectedSubCategory = value;
                          });
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            keyboardType: TextInputType.text,
                            onTap: () {
                              _hideKeyboard();
                              Future.delayed(Duration(milliseconds: 50), () {
                                SystemChannels.textInput
                                    .invokeMethod('TextInput.show');
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Подкатегория',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              selectedSubCategory = value;
                            },
                            onSubmitted: (value) {
                              if (value.isNotEmpty &&
                                  selectedCategory != null) {
                                final subs = isIncome
                                    ? incomeSubCategories
                                    : expenseSubCategories;
                                final exists = subs.any((s) =>
                                    s.name == value &&
                                    s.parentName == selectedCategory);
                                if (!exists) {
                                  setState(() {
                                    if (isIncome) {
                                      incomeSubCategories.add(SubCategory(value,
                                          selectedCategory!, Icons.work));
                                      widget.storageService
                                          .saveIncomeSubCategories(
                                              incomeSubCategories);
                                    } else {
                                      expenseSubCategories.add(SubCategory(
                                          value,
                                          selectedCategory!,
                                          Icons.category));
                                      widget.storageService
                                          .saveExpenseSubCategories(
                                              expenseSubCategories);
                                    }
                                  });
                                }
                                selectedSubCategory = value;
                              }
                            },
                          );
                        },
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
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      keyboardType: TextInputType.text,
                      onTap: () {
                        _hideKeyboard();
                        Future.delayed(Duration(milliseconds: 50), () {
                          SystemChannels.textInput
                              .invokeMethod('TextInput.show');
                        });
                      },
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
                    final amount = _parseAmount(amountController.text);
                    if (amount <= 0 || selectedCategory == null) return;
                    final categories =
                        isIncome ? incomeCategories : expenseCategories;
                    final categoryExists =
                        categories.any((c) => c.name == selectedCategory);
                    if (!categoryExists &&
                        selectedCategory != null &&
                        selectedCategory!.isNotEmpty) {
                      setState(() {
                        if (isIncome) {
                          incomeCategories.add(Category(
                              selectedCategory!, Icons.work, '#4CAF50'));
                          widget.storageService
                              .saveIncomeCategories(incomeCategories);
                        } else {
                          expenseCategories.add(Category(
                              selectedCategory!, Icons.category, '#607D8B'));
                          widget.storageService
                              .saveExpenseCategories(expenseCategories);
                        }
                      });
                    }
                    if (selectedSubCategory != null &&
                        selectedSubCategory!.isNotEmpty &&
                        selectedCategory != null &&
                        selectedCategory!.isNotEmpty) {
                      final subs =
                          isIncome ? incomeSubCategories : expenseSubCategories;
                      final exists = subs.any((s) =>
                          s.name == selectedSubCategory &&
                          s.parentName == selectedCategory);
                      if (!exists) {
                        setState(() {
                          if (isIncome) {
                            incomeSubCategories.add(SubCategory(
                              selectedSubCategory!,
                              selectedCategory!,
                              Icons.work,
                            ));
                            widget.storageService
                                .saveIncomeSubCategories(incomeSubCategories);
                          } else {
                            expenseSubCategories.add(SubCategory(
                              selectedSubCategory!,
                              selectedCategory!,
                              Icons.category,
                            ));
                            widget.storageService
                                .saveExpenseSubCategories(expenseSubCategories);
                          }
                        });
                      }
                    }
                    _addTransaction(Transaction(
                      id: DateTime.now().toString(),
                      amount: amount,
                      category: selectedCategory!,
                      subCategory: selectedSubCategory,
                      isIncome: isIncome,
                      note: noteController.text.trim(),
                      date: selectedDate,
                      accountId: selectedAccountId,
                    ));
                    widget.storageService.saveLastAccountId(selectedAccountId);
                    widget.storageService.saveLastCategory(selectedCategory!);
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Операция добавлена')),
                    );
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

  void _showScannerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Сканер чека'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Выберите способ:'),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Сканировать камерой'),
                onPressed: () {
                  Navigator.pop(context);
                  _scanWithCamera();
                },
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.paste),
                label: Text('Вставить QR-код'),
                onPressed: () {
                  Navigator.pop(context);
                  _pasteQrCode();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Закрыть')),
          ],
        );
      },
    );
  }

  void _scanWithCamera() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      final scannerService = ScannerService();
      final parsed = await scannerService.parseReceipt(result);
      if (parsed != null && mounted) {
        _showScannedReceipt(parsed);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось распознать чек')),
        );
      }
    }
  }

  void _pasteQrCode() {
    final qrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('QR-код чека'),
          content: TextField(
            controller: qrController,
            decoration: InputDecoration(
              labelText: 'Вставьте QR-код',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final qrData = qrController.text.trim();
                if (qrData.isEmpty) return;

                final scannerService = ScannerService();
                final result = await scannerService.parseReceipt(qrData);

                Navigator.pop(context);

                if (result != null) {
                  _showScannedReceipt(result);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Не удалось распознать чек')),
                  );
                }
              },
              child: Text('Распознать'),
            ),
          ],
        );
      },
    );
  }

  void _showScannedReceipt(Map<String, dynamic> data) {
    final amountController =
        TextEditingController(text: data['amount'].toString());
    String selectedAccount = accounts.isNotEmpty ? accounts[0].id : '';
    String selectedCategory =
        expenseCategories.isNotEmpty ? expenseCategories[0].name : 'Продукты';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Чек распознан'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Сумма'),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(labelText: 'Категория'),
                    items: expenseCategories.map((c) {
                      return DropdownMenuItem(
                          value: c.name, child: Text(c.name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategory = value!);
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedAccount,
                    decoration: InputDecoration(labelText: 'Счёт'),
                    items: accounts.map((a) {
                      return DropdownMenuItem(value: a.id, child: Text(a.name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedAccount = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Отмена')),
                ElevatedButton(
                  onPressed: () {
                    final amount = _parseAmount(amountController.text);
                    if (amount <= 0) return;

                    _addTransaction(Transaction(
                      id: DateTime.now().toString(),
                      amount: amount,
                      category: selectedCategory,
                      isIncome: false,
                      note: 'Из чека',
                      date: DateTime.now(),
                      accountId: selectedAccount,
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

  void _showTransferDialog() {
    final amountController = TextEditingController();
    String fromAccountId = accounts.isNotEmpty ? accounts[0].id : '';
    String toAccountId = accounts.length > 1 ? accounts[1].id : '';
    DateTime selectedDate = DateTime.now();
    String? selectedCategory;
    String? selectedSubCategory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Перевод между счетами'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField(
                      value: fromAccountId,
                      decoration: InputDecoration(labelText: 'Со счёта'),
                      items: accounts.map((account) {
                        return DropdownMenuItem(
                            value: account.id, child: Text(account.name));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          fromAccountId = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField(
                      value: toAccountId,
                      decoration: InputDecoration(labelText: 'На счёт'),
                      items: accounts
                          .where((a) => a.id != fromAccountId)
                          .map((account) {
                        return DropdownMenuItem(
                            value: account.id, child: Text(account.name));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          toAccountId = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Сумма',
                        prefixText: '$currency ',
                        border: OutlineInputBorder(),
                      ),
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
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return transferCategories.map((c) => c.name);
                        }
                        return transferCategories.map((c) => c.name).where(
                            (name) => name
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.text,
                          onTap: () {
                            _hideKeyboard();
                            Future.delayed(Duration(milliseconds: 50), () {
                              SystemChannels.textInput
                                  .invokeMethod('TextInput.show');
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Категория',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            selectedCategory = value;
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              final exists = transferCategories
                                  .any((c) => c.name == value);
                              if (!exists) {
                                setState(() {
                                  transferCategories.add(Category(
                                      value, Icons.swap_horiz, '#2196F3'));
                                });
                              }
                              selectedCategory = value;
                            }
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        final subs = transferSubCategories
                            .where((s) => s.parentName == selectedCategory)
                            .map((s) => s.name);
                        if (textEditingValue.text.isEmpty) return subs;
                        return subs.where((name) => name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (value) {
                        setState(() {
                          selectedSubCategory = value;
                        });
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.text,
                          onTap: () {
                            _hideKeyboard();
                            Future.delayed(Duration(milliseconds: 50), () {
                              SystemChannels.textInput
                                  .invokeMethod('TextInput.show');
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Подкатегория',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            selectedSubCategory = value;
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty && selectedCategory != null) {
                              final exists = transferSubCategories.any((s) =>
                                  s.name == value &&
                                  s.parentName == selectedCategory);
                              if (!exists) {
                                setState(() {
                                  transferSubCategories.add(SubCategory(value,
                                      selectedCategory!, Icons.swap_horiz));
                                });
                              }
                              selectedSubCategory = value;
                            }
                          },
                        );
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
                    final amount = _parseAmount(amountController.text);
                    if (amount <= 0 || fromAccountId == toAccountId) return;

                    if (selectedCategory != null &&
                        selectedCategory!.isNotEmpty) {
                      final exists = transferCategories
                          .any((c) => c.name == selectedCategory);
                      if (!exists) {
                        setState(() {
                          transferCategories.add(Category(
                              selectedCategory!, Icons.swap_horiz, '#2196F3'));
                        });
                      }
                    }

                    if (selectedSubCategory != null &&
                        selectedSubCategory!.isNotEmpty &&
                        selectedCategory != null) {
                      final exists = transferSubCategories.any((s) =>
                          s.name == selectedSubCategory &&
                          s.parentName == selectedCategory);
                      if (!exists) {
                        setState(() {
                          transferSubCategories.add(SubCategory(
                              selectedSubCategory!,
                              selectedCategory!,
                              Icons.swap_horiz));
                        });
                      }
                    }

                    _addTransaction(Transaction(
                      id: DateTime.now().toString(),
                      amount: amount,
                      category: selectedCategory ?? 'Перевод',
                      subCategory: selectedSubCategory,
                      isIncome: false,
                      note: '',
                      date: selectedDate,
                      accountId: fromAccountId,
                      toAccountId: toAccountId,
                    ));

                    Navigator.pop(context);
                  },
                  child: Text('Перевести'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final bankController = TextEditingController();
    final creditLimitController = TextEditingController();
    String accountType = 'cash';
    String selectedColor = '#4CAF50';
    String selectedIcon = 'wallet';
    String? selectedIconPath;

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
                          labelText: 'Название', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Баланс',
                        prefixText: '$currency ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: bankController,
                      decoration: InputDecoration(
                        labelText: 'Банк',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (accountType == 'credit') ...[
                      SizedBox(height: 12),
                      TextField(
                        controller: creditLimitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Кредитный лимит',
                          prefixText: '$currency ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    Text('Цвет:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: accountColors.map((color) {
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
                    SizedBox(height: 8),
                    Text('Material:',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Wrap(
                      spacing: 8,
                      children: accountIcons.map((iconData) {
                        final isSelected = selectedIconPath == null &&
                            selectedIcon == iconData['name'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIcon = iconData['name'] as String;
                              selectedIconPath = null;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              iconData['icon'] as IconData,
                              color: isSelected ? Colors.teal : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
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
                    final balance = _parseAmount(balanceController.text);
                    final bank = bankController.text.trim();
                    final creditLimit =
                        _parseAmount(creditLimitController.text);
                    if (name.isEmpty) return;

                    _addAccount(Account(
                      id: DateTime.now().toString(),
                      name: name,
                      type: accountType,
                      balance: balance,
                      bank: bank,
                      creditLimit: creditLimit,
                      color: selectedColor,
                      icon: selectedIcon,
                      iconPath: selectedIconPath,
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

  void _showEditAccountDialog(Account account) {
    final nameController = TextEditingController(text: account.name);
    final balanceController =
        TextEditingController(text: account.balance.toString());
    final bankController = TextEditingController(text: account.bank);
    final creditLimitController =
        TextEditingController(text: account.creditLimit.toString());

    String accountType = account.type;
    String selectedColor = account.color;
    String selectedIcon = account.icon;
    String? selectedIconPath = account.iconPath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Редактировать счёт'),
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
                          labelText: 'Название', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Баланс',
                        prefixText: '$currency ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: bankController,
                      decoration: InputDecoration(
                        labelText: 'Банк',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (accountType == 'credit') ...[
                      SizedBox(height: 12),
                      TextField(
                        controller: creditLimitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Кредитный лимит',
                          prefixText: '$currency ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    Text('Цвет:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: accountColors.map((color) {
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
                    SizedBox(height: 8),
                    Text('Material:',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Wrap(
                      spacing: 8,
                      children: accountIcons.map((iconData) {
                        final isSelected = selectedIconPath == null &&
                            selectedIcon == iconData['name'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIcon = iconData['name'] as String;
                              selectedIconPath = null;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              iconData['icon'] as IconData,
                              color: isSelected ? Colors.teal : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
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
                    final balance = _parseAmount(balanceController.text);
                    final bank = bankController.text.trim();
                    final creditLimit =
                        _parseAmount(creditLimitController.text);
                    if (name.isEmpty) return;

                    final updatedAccount = Account(
                      id: account.id,
                      name: name,
                      type: accountType,
                      balance: balance,
                      bank: bank,
                      creditLimit: creditLimit,
                      color: selectedColor,
                      icon: selectedIcon,
                      iconPath: selectedIconPath,
                    );

                    _updateAccount(account, updatedAccount);
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

  // Транзакции
  void _addTransaction(Transaction t) {
    setState(() {
      transactions.insert(0, t);

      if (t.isTransfer) {
        _updateAccountBalance(t.accountId, -t.amount);
        _updateAccountBalance(t.toAccountId!, t.amount);
      } else {
        _updateAccountBalance(t.accountId, t.isIncome ? t.amount : -t.amount);
      }

      widget.storageService.saveTransactions(transactions);
      widget.storageService.saveAccounts(accounts);
    });
    _saveToFirebase();
  }

  void _updateTransaction(Transaction oldT, Transaction newT) {
    setState(() {
      int index = transactions.indexWhere((t) => t.id == oldT.id);
      if (index != -1) {
        transactions[index] = newT;
      }
      widget.storageService.saveTransactions(transactions);
    });
    _saveToFirebase();
  }

  void _deleteTransaction(Transaction t) {
    setState(() {
      transactions.removeWhere((x) => x.id == t.id);

      if (t.isTransfer) {
        _updateAccountBalance(t.accountId, t.amount);
        if (t.toAccountId != null) {
          _updateAccountBalance(t.toAccountId!, -t.amount);
        }
      } else {
        _updateAccountBalance(t.accountId, t.isIncome ? -t.amount : t.amount);
      }

      widget.storageService.saveTransactions(transactions);
      widget.storageService.saveAccounts(accounts);
    });
    _saveToFirebase();
  }

  // Счета
  void _addAccount(Account a) {
    setState(() {
      accounts.add(a);
      widget.storageService.saveAccounts(accounts);
    });
  }

  void _updateAccount(Account oldA, Account newA) {
    setState(() {
      int index = accounts.indexWhere((a) => a.id == oldA.id);
      if (index != -1) {
        accounts[index] = newA;
      }
      widget.storageService.saveAccounts(accounts);
    });
  }

  void _reorderAccounts(List<Account> reordered) {
    setState(() {
      accounts = reordered;
      widget.storageService.saveAccounts(accounts);
    });
    _saveToFirebase();
  }

  void _deleteAccount(Account a) {
    setState(() {
      accounts.removeWhere((x) => x.id == a.id);
      transactions
          .removeWhere((t) => t.accountId == a.id || t.toAccountId == a.id);
      widget.storageService.saveAccounts(accounts);
      widget.storageService.saveTransactions(transactions);
    });
  }

  void _updateAccountBalance(String accountId, double delta) {
    int index = accounts.indexWhere((a) => a.id == accountId);
    if (index != -1) {
      accounts[index] =
          accounts[index].copyWith(balance: accounts[index].balance + delta);
    }
  }

  // Категории
  void _addExpenseCategory(Category c) {
    setState(() {
      expenseCategories.add(c);
      widget.storageService.saveExpenseCategories(expenseCategories);
    });
  }

  void _addIncomeCategory(Category c) {
    setState(() {
      incomeCategories.add(c);
      widget.storageService.saveIncomeCategories(incomeCategories);
    });
  }

  void _deleteExpenseCategory(Category c) {
    setState(() {
      expenseCategories.removeWhere((x) => x.name == c.name);
      widget.storageService.saveExpenseCategories(expenseCategories);
    });
  }

  void _deleteIncomeCategory(Category c) {
    setState(() {
      incomeCategories.removeWhere((x) => x.name == c.name);
      widget.storageService.saveIncomeCategories(incomeCategories);
    });
  }

  void _addTransferCategory(Category c) {
    setState(() {
      transferCategories.add(c);
      widget.storageService.setString('transfer_categories',
          jsonEncode(transferCategories.map((c) => c.toJson()).toList()));
    });
  }

  void _deleteTransferCategory(Category c) {
    setState(() {
      transferCategories.removeWhere((x) => x.name == c.name);
      widget.storageService.setString('transfer_categories',
          jsonEncode(transferCategories.map((c) => c.toJson()).toList()));
    });
  }

  void _addTransferSubCategory(SubCategory s) {
    setState(() {
      transferSubCategories.add(s);
    });
  }

  void _deleteTransferSubCategory(SubCategory s) {
    setState(() {
      transferSubCategories
          .removeWhere((x) => x.name == s.name && x.parentName == s.parentName);
    });
  }

  void _addExpenseSubCategory(SubCategory s) {
    setState(() {
      expenseSubCategories.add(s);
      widget.storageService.saveExpenseSubCategories(expenseSubCategories);
    });
  }

  void _addIncomeSubCategory(SubCategory s) {
    setState(() {
      incomeSubCategories.add(s);
      widget.storageService.saveIncomeSubCategories(incomeSubCategories);
    });
  }

  void _deleteExpenseSubCategory(SubCategory s) {
    setState(() {
      expenseSubCategories
          .removeWhere((x) => x.name == s.name && x.parentName == s.parentName);
      widget.storageService.saveExpenseSubCategories(expenseSubCategories);
    });
  }

  void _deleteIncomeSubCategory(SubCategory s) {
    setState(() {
      incomeSubCategories
          .removeWhere((x) => x.name == s.name && x.parentName == s.parentName);
      widget.storageService.saveIncomeSubCategories(incomeSubCategories);
    });
  }

  void _addPayment(Payment p) {
    setState(() {
      payments.add(p);
      widget.storageService.savePayments(payments);
    });
    _saveToFirebase();
  }

  void _updatePayment(Payment oldP, Payment newP) {
    setState(() {
      int index = payments.indexWhere((p) => p.id == oldP.id);
      if (index != -1) {
        payments[index] = newP;
      }
      widget.storageService.savePayments(payments);
    });
    _saveToFirebase();
  }

  void _deletePayment(Payment p) {
    setState(() {
      payments.removeWhere((x) => x.id == p.id);
      widget.storageService.savePayments(payments);
    });
    _saveToFirebase();
  }

  void _onPayNow(Payment payment) {
    // ⭐ ДОХОД: только зачисление
    if (payment.isIncome) {
      final toAccount = accounts.firstWhere(
        (a) => a.id == payment.toAccountId,
        orElse: () => throw Exception('Счёт зачисления не найден'),
      );

      final updatedTo = toAccount.copyWith(
        balance: toAccount.balance + payment.amount,
      );

      final newSchedule = _getNextSchedule(payment);

      final updatedPayment = payment.copyWith(
        isPaid: true,
        schedule: newSchedule,
      );

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: payment.amount,
        category: payment.category,
        isIncome: true,
        note: '${payment.name} (автоматическое зачисление)',
        date: DateTime.now(),
        accountId: payment.toAccountId,
        toAccountId: null,
      );

      setState(() {
        final paymentIndex = payments.indexWhere((p) => p.id == payment.id);
        if (paymentIndex != -1) {
          payments[paymentIndex] = updatedPayment;
        }

        final toIndex = accounts.indexWhere((a) => a.id == toAccount.id);
        if (toIndex != -1) {
          accounts[toIndex] = updatedTo;
        }

        transactions.insert(0, transaction);

        widget.storageService.savePayments(payments);
        widget.storageService.saveAccounts(accounts);
        widget.storageService.saveTransactions(transactions);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Доход "${payment.name}" успешно зачислен!'),
          backgroundColor: Colors.green,
        ),
      );
      _saveToFirebase();
      return;
    }

    // ⭐ РАСХОДЫ: проверяем, перевод это или услуга
    final isTransfer = payment.fromAccountId != payment.toAccountId;

    if (isTransfer) {
      // ⭐ ПЕРЕВОД: списываем с одного, зачисляем на другой
      final fromAccount = accounts.firstWhere(
        (a) => a.id == payment.fromAccountId,
        orElse: () => throw Exception('Счёт списания не найден'),
      );
      final toAccount = accounts.firstWhere(
        (a) => a.id == payment.toAccountId,
        orElse: () => throw Exception('Счёт пополнения не найден'),
      );

      if (fromAccount.balance < payment.amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Недостаточно средств на счету "${fromAccount.name}"'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedFrom = fromAccount.copyWith(
        balance: fromAccount.balance - payment.amount,
      );
      final updatedTo = toAccount.copyWith(
        balance: toAccount.balance + payment.amount,
      );

      final newSchedule = _getNextSchedule(payment);

      final updatedPayment = payment.copyWith(
        isPaid: true,
        schedule: newSchedule,
      );

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: payment.amount,
        category: payment.category,
        isIncome: false,
        note: '${payment.name} (перевод)',
        date: DateTime.now(),
        accountId: payment.fromAccountId,
        toAccountId: payment.toAccountId,
      );

      setState(() {
        final paymentIndex = payments.indexWhere((p) => p.id == payment.id);
        if (paymentIndex != -1) {
          payments[paymentIndex] = updatedPayment;
        }

        final fromIndex = accounts.indexWhere((a) => a.id == fromAccount.id);
        if (fromIndex != -1) {
          accounts[fromIndex] = updatedFrom;
        }
        final toIndex = accounts.indexWhere((a) => a.id == toAccount.id);
        if (toIndex != -1) {
          accounts[toIndex] = updatedTo;
        }

        transactions.insert(0, transaction);

        widget.storageService.savePayments(payments);
        widget.storageService.saveAccounts(accounts);
        widget.storageService.saveTransactions(transactions);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Перевод "${payment.name}" выполнен!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // ⭐ УСЛУГА (обычный расход): просто списываем
    final fromAccount = accounts.firstWhere(
      (a) => a.id == payment.fromAccountId,
      orElse: () => throw Exception('Счёт списания не найден'),
    );

    if (fromAccount.balance < payment.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Недостаточно средств на счету "${fromAccount.name}"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedFrom = fromAccount.copyWith(
      balance: fromAccount.balance - payment.amount,
    );

    final newSchedule = _getNextSchedule(payment);

    final updatedPayment = payment.copyWith(
      isPaid: true,
      schedule: newSchedule,
    );

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: payment.amount,
      category: payment.category,
      isIncome: false,
      note: '${payment.name} (автоматическое списание)',
      date: DateTime.now(),
      accountId: payment.fromAccountId,
      toAccountId: null,
    );

    setState(() {
      final paymentIndex = payments.indexWhere((p) => p.id == payment.id);
      if (paymentIndex != -1) {
        payments[paymentIndex] = updatedPayment;
      }

      final fromIndex = accounts.indexWhere((a) => a.id == fromAccount.id);
      if (fromIndex != -1) {
        accounts[fromIndex] = updatedFrom;
      }

      transactions.insert(0, transaction);

      widget.storageService.savePayments(payments);
      widget.storageService.saveAccounts(accounts);
      widget.storageService.saveTransactions(transactions);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Платёж "${payment.name}" успешно списан!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  PaymentSchedule _getNextSchedule(Payment payment) {
    final currentDate = payment.schedule.nextDate;
    if (currentDate == null) {
      return payment.schedule.advance();
    }

    DateTime? nextDate;
    switch (payment.frequency) {
      case 'daily':
        nextDate = currentDate.add(Duration(days: payment.interval));
        break;
      case 'weekly':
        nextDate = currentDate.add(Duration(days: 7 * payment.interval));
        break;
      case 'biweekly':
        nextDate = currentDate.add(Duration(days: 14));
        break;
      case 'monthly':
        final day = currentDate.day;
        if (currentDate.month == 12) {
          nextDate = DateTime(currentDate.year + 1, 1, day);
        } else {
          nextDate = DateTime(currentDate.year, currentDate.month + 1, day);
        }
        if (nextDate.day != day) {
          if (currentDate.month == 12) {
            nextDate = DateTime(currentDate.year + 1, 1, 0);
          } else {
            nextDate = DateTime(currentDate.year, currentDate.month + 1, 0);
          }
        }
        break;
      case 'yearly':
        nextDate =
            DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
        break;
      default:
        nextDate = currentDate.add(Duration(days: payment.interval));
    }

    return PaymentSchedule.fromPattern(
      startDate: nextDate,
      frequency: payment.frequency,
      interval: payment.interval,
      count: 12,
    );
  }

  // ⭐ СОХРАНЕНИЕ В FIREBASE
  Future<void> _saveToFirebase() async {
    try {
      print('📤 Сохраняем в Firebase...');
      await widget.backupService.saveToFirebase();
      print('✅ Успешно сохранено в Firebase!');
    } catch (e) {
      print('❌ Ошибка сохранения в Firebase: $e');
      debugPrint('❌ Ошибка сохранения в Firebase: $e');
    }
  }

  // Настройки
  void _changeCurrency(String c) {
    setState(() {
      currency = c;
      widget.storageService.setCurrency(c);
    });
  }

  void _changeNotifications(bool value) {
    setState(() {
      showNotifications = value;
      widget.storageService.setShowNotifications(value);
    });
  }

  void _changeDarkMode(bool value) {
    setState(() {
      isDarkMode = value;
      widget.storageService.setIsDarkMode(value);
    });
    widget.onThemeChanged?.call();
  }

  void _clearAll() {
    setState(() {
      accounts = [
        Account(
            id: '1',
            name: 'Наличные',
            type: 'cash',
            balance: 0,
            color: '#4CAF50',
            icon: 'cash'),
      ];
      transactions = [];
      payments = [];
      widget.storageService.clearAll();
      widget.storageService.saveAccounts(accounts);
    });
  }

  void _showCalculator(TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) {
        final calcController = TextEditingController();
        String result = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Калькулятор'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: calcController,
                    decoration: InputDecoration(
                      hintText: 'Например: 100+50+25',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('Результат: $result',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Отмена')),
                ElevatedButton(
                  onPressed: () {
                    final sum = _calculateSum(calcController.text);
                    controller.text = sum.toString();
                    Navigator.pop(context);
                  },
                  child: Text('Вставить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _calculateSum(String input) {
    try {
      final parts = input.split('+');
      double sum = 0;
      for (var part in parts) {
        sum += double.tryParse(part.trim()) ?? 0;
      }
      return sum;
    } catch (e) {
      return double.tryParse(input) ?? 0;
    }
  }

  void _hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  double _parseAmount(String text) {
    print('📝 Парсим сумму: "$text"');
    final result = text.replaceAll(',', '.');
    print('📝 После замены: "$result"');
    final parsed = double.tryParse(result) ?? 0;
    print('📝 Результат: $parsed');
    return parsed;
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
