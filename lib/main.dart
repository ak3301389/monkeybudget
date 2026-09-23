import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/backup_service.dart';
import 'services/notification_service.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyD2DmbakbCQNhrCVRL2yodJoOqlnmPV9Ls",
      appId: "1:259871148413:android:66431325894da2017de414",
      messagingSenderId: "259871148413",
      projectId: "myhomebuh-cc76a",
      storageBucket: "myhomebuh-cc76a.firebasestorage.app",
    ),
  );

  final notificationService = NotificationService();
  await notificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final backupService = BackupService(storageService);

  runApp(MyApp(
    storageService: storageService,
    backupService: backupService,
  ));
}

class MyApp extends StatefulWidget {
  final StorageService storageService;
  final BackupService backupService;

  const MyApp({
    Key? key,
    required this.storageService,
    required this.backupService,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.storageService.getIsDarkMode();
  }

  void _updateTheme() {
    setState(() {
      _isDarkMode = widget.storageService.getIsDarkMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Домашняя бухгалтерия',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ru', 'RU'),
      ],
      locale: Locale('ru', 'RU'),
      home: SplashScreen(),
      routes: {
        '/home': (context) => HomeScreen(
              storageService: widget.storageService,
              backupService: widget.backupService,
              onThemeChanged: _updateTheme,
            ),
      },
    );
  }
}
