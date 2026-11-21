import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkAuthAndPin(); // ⬅️ ИЗМЕНЕНО: теперь проверяет и авторизацию, и PIN
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}.${info.buildNumber}';
    });
  }

  Future<void> _checkAuthAndPin() async {
    await Future.delayed(const Duration(seconds: 2));

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
          title: const Text('Введите PIN-код'),
          content: TextField(
            controller: pinController,
            focusNode: focusNode,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
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
                    const SnackBar(content: Text('Неверный PIN-код')),
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
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Бухгалтерия',
              style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Версия $_version',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
