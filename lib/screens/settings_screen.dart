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
  final bool isDarkMode;
  final Function(String) onCurrencyChanged;
  final Function(bool) onNotificationsChanged;
  final Function(bool) onDarkModeChanged;
  final Function() onClearAll;
  
  const SettingsScreen({
    Key? key,
    required this.storageService,
    required this.backupService,
    required this.currency,
    required this.showNotifications,
    required this.isDarkMode,
    required this.onCurrencyChanged,
    required this.onNotificationsChanged,
    required this.onDarkModeChanged,
    required this.onClearAll,
  }) : super(key: key);
  
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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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
      padding: EdgeInsets.all(16),
      children: [
        Text('Настройки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
		
		        Card(
          child: ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Войти через Google'),
            subtitle: Text(_userEmail ?? 'Не выполнен вход'),
            onTap: _signInWithGoogle,
          ),
        ),
        SizedBox(height: 16),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(Icons.notifications),
                title: Text('Уведомления'),
                subtitle: Text('Напоминать о платежах'),
                value: widget.showNotifications,
                onChanged: widget.onNotificationsChanged,
              ),
              Divider(),
              SwitchListTile(
                secondary: Icon(Icons.dark_mode),
                title: Text('Тёмная тема'),
                value: widget.isDarkMode,
                onChanged: widget.onDarkModeChanged,
              ),
            ],
          ),
        ),

        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.cloud_upload),
                title: Text('Сохранить в Firebase'),
                subtitle: Text('Экспорт в облако'),
                onTap: _isBusy ? null : () => _saveToFirebase(),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.cloud_download),
                title: Text('Восстановить из Firebase'),
                subtitle: Text('Импорт из облака'),
                onTap: _isBusy ? null : () => _restoreFromFirebase(),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.key),
                title: Text('Ввести код синхронизации'),
                subtitle: Text('Подключиться к существующим данным'),
                onTap: _enterSyncCode,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.pin),
                title: Text('PIN-код'),
                subtitle: Text('Защита входа'),
                onTap: _setPin,
              ),
            ],
          ),
        ),

        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.save),
                title: Text('Сохранить в файл'),
                subtitle: Text('Экспорт данных'),
                onTap: _isBusy ? null : () => _saveToPhone(),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.folder_open),
                title: Text('Восстановить из файла'),
                subtitle: Text('Выбрать файл бэкапа'),
                onTap: _isBusy ? null : () => _restoreFromFile(),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Очистить все данные', style: TextStyle(color: Colors.red)),
                onTap: () => _confirmClearAll(),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.info),
                title: Text('О приложении'),
                subtitle: Text('Версия $_version'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.history),
                title: Text('История версий'),
                onTap: _showVersionHistory,
              ),
            ],
          ),
        ),

        if (_isBusy)
          Padding(
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
          SnackBar(content: Text(success ? '✅ Данные восстановлены! Перезапустите приложение.' : '❌ Ошибка восстановления')),
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
                title: Text('✅ Данные сохранены'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ваш код синхронизации:'),
                    SizedBox(height: 8),
                    Text(
                      code,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    SizedBox(height: 8),
                    Text('Введите этот код на другом устройстве', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
                ],
              );
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка загрузки')),
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
          title: Text('Установить PIN-код'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(labelText: 'PIN-код'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('pin_code', pinController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ PIN-код установлен')),
                );
              },
              child: Text('Сохранить'),
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
          title: Text('Код синхронизации'),
          content: TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: 'Введите код',
              hintText: 'XXX-XXX-XXX',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();
                if (code.isEmpty) return;
                
                Navigator.pop(context);
                setState(() => _isBusy = true);
                final success = await widget.backupService.restoreByCode(code);
                setState(() => _isBusy = false);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? '✅ Данные загружены!' : '❌ Неверный код')),
                );
              },
              child: Text('Подключить'),
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
      SnackBar(content: Text(success ? '✅ Данные восстановлены! Перезапустите приложение.' : '❌ Ошибка загрузки')),
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
          title: Text('История версий'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(history, style: TextStyle(fontSize: 14)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Закрыть')),
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
          title: Text('Очистить все данные?'),
          content: Text('Все счета, операции и категории будут удалены.\nЭто действие нельзя отменить!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onClearAll();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Данные очищены')),
                );
              },
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}