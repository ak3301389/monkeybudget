import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ⬅️ ДОБАВЬТЕ ЭТОТ ИМПОРТ

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkAuthAndPin();  // ⬅️ ИЗМЕНЕНО: теперь проверяет и авторизацию, и PIN
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}.${info.buildNumber}';
    });
  }

  // ⬅️ НОВЫЙ МЕТОД: проверяет авторизацию и PIN
	  Future<void> _checkAuthAndPin() async {
	  await Future.delayed(Duration(seconds: 2));

	  // 1. Проверяем авторизацию в Firebase
	  final user = FirebaseAuth.instance.currentUser;
	  print('🔍 FirebaseAuth.currentUser: ${user?.email ?? "null"}');
	  print('🔍 User UID: ${user?.uid ?? "null"}');

	  if (user == null) {
		print('❌ Пользователь НЕ вошёл');
		if (!mounted) return;
		Navigator.pushReplacementNamed(context, '/home');
		return;
	  }

	  print('✅ Пользователь вошёл: ${user.email}');
	  
	  // 2. Пользователь вошёл — проверяем PIN
	  final prefs = await SharedPreferences.getInstance();
	  final pin = prefs.getString('pin_code');

	  if (!mounted) return;

	  if (pin == null || pin.isEmpty) {
		Navigator.pushReplacementNamed(context, '/home');
	  } else {
		_showPinDialog(pin);
	  }
	}

  void _showPinDialog(String correctPin) {
    final pinController = TextEditingController();
    final focusNode = FocusNode();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });

        return AlertDialog(
          title: Text('Введите PIN-код'),
          content: TextField(
            controller: pinController,
            focusNode: focusNode,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: 'PIN-код',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.length == 4) {
                if (value == correctPin) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  pinController.clear();
                  focusNode.requestFocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Неверный PIN-код')),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Бухгалтерия',
              style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Версия $_version',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}