import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import '../services/backup_service.dart';
import '../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final BackupService backupService;
  final String currency;
  final bool showNotifications;
  final Function(String) onCurrencyChanged;
  final Function(bool) onNotificationsChanged;
  final Function() onClearAll;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.backupService,
    required this.currency,
    required this.showNotifications,
    required this.onCurrencyChanged,
    required this.onNotificationsChanged,
    required this.onClearAll,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBusy = false;
  String _version = '';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    print('🔍 SettingsScreen _checkAuth: user = ${user?.email ?? "null"}');
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}.${info.buildNumber}';
    });
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() {
        _userEmail = googleUser.email;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Вы вошли как ${googleUser.email}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Настройки',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Войти через Google'),
            subtitle: Text(_userEmail ?? 'Не выполнен вход'),
            onTap: _signInWithGoogle,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Уведомления'),
                subtitle: const Text('Напоминать о платежах'),
                value: widget.showNotifications,
                onChanged: widget.onNotificationsChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Сохранить в Firebase'),
                subtitle: const Text('Экспорт в облако'),
                onTap: _isBusy ? null : () => _saveToFirebase(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: const Text('Восстановить из Firebase'),
                subtitle: const Text('Импорт из облака'),
                onTap: _isBusy ? null : () => _restoreFromFirebase(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('Ввести код синхронизации'),
                subtitle: const Text('Подключиться к существующим данным'),
                onTap: _enterSyncCode,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.pin),
                title: const Text('PIN-код'),
                subtitle: const Text('Защита входа'),
                onTap: _setPin,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Сохранить в файл'),
                subtitle: const Text('Экспорт данных'),
                onTap: _isBusy ? null : () => _saveToPhone(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Восстановить из файла'),
                subtitle: const Text('Выбрать файл бэкапа'),
                onTap: _isBusy ? null : () => _restoreFromFile(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Очистить все данные',
                    style: TextStyle(color: Colors.red)),
                onTap: () => _confirmClearAll(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('О приложении'),
                subtitle: Text('Версия $_version'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('История версий'),
                onTap: _showVersionHistory,
              ),
            ],
          ),
        ),
        if (_isBusy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _saveToPhone() async {
    setState(() => _isBusy = true);
    try {
      final path = await widget.backupService.saveToPhone();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Сохранено: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
    setState(() => _isBusy = false);
  }

  Future<void> _restoreFromFile() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        setState(() => _isBusy = true);
        final success = await widget.backupService.restoreFromFile(file.path);
        setState(() => _isBusy = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(success
                  ? '✅ Данные восстановлены! Перезапустите приложение.'
                  : '❌ Ошибка восстановления')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isBusy = true);
    try {
      final success = await widget.backupService.saveToFirebase();

      if (success) {
        final code = await widget.backupService.getSyncCode();

        if (code != null) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('✅ Данные сохранены'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ваш код синхронизации:'),
                    const SizedBox(height: 8),
                    Text(
                      code,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    const Text('Введите этот код на другом устройстве',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK')),
                ],
              );
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Ошибка загрузки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
    setState(() => _isBusy = false);
  }

  void _setPin() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Установить PIN-код'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'PIN-код'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('pin_code', pinController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ PIN-код установлен')),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _enterSyncCode() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Код синхронизации'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'Введите код',
              hintText: 'XXX-XXX-XXX',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();
                if (code.isEmpty) return;

                Navigator.pop(context);
                setState(() => _isBusy = true);
                final success = await widget.backupService.restoreByCode(code);
                setState(() => _isBusy = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          success ? '✅ Данные загружены!' : '❌ Неверный код')),
                );
              },
              child: const Text('Подключить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _restoreFromFirebase() async {
    setState(() => _isBusy = true);

    final success = await widget.backupService.restoreFromFirebase();

    setState(() => _isBusy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(success
              ? '✅ Данные восстановлены! Перезапустите приложение.'
              : '❌ Ошибка загрузки')),
    );
  }

  void _showVersionHistory() async {
    String history = 'История версий:\n\n';
    try {
      history += await rootBundle.loadString('version_history.txt');
    } catch (e) {
      history += 'Нет данных';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('История версий'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(history, style: const TextStyle(fontSize: 14)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть')),
          ],
        );
      },
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Очистить все данные?'),
          content: const Text(
              'Все счета, операции и категории будут удалены.\nЭто действие нельзя отменить!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onClearAll();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Данные очищены')),
                );
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
