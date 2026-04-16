import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'loading.dart';
import 'welcome.dart';
import 'login.dart';
import 'signup.dart';
import 'interests.dart';
import 'home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final seenWelcome = prefs.getBool('seenWelcome') ?? false;
  final rememberMe = prefs.getBool('rememberMe') ?? false;
  final loggedInEmail = prefs.getString('loggedInEmail');
  final userId = prefs.getString('userId');
  var darkMode = prefs.getBool('darkMode') ?? true;

  final nextRoute = !seenWelcome
      ? '/welcome'
      : (rememberMe && loggedInEmail != null ? '/home' : '/login');

  // If user is remembered, sync theme from Firebase
  if (rememberMe && userId != null && userId.isNotEmpty) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('korisnici')
          .doc(userId)
          .get();
      if (doc.exists) {
        darkMode = (doc.data()?['darkMode'] as bool?) ?? true;
        await prefs.setBool('darkMode', darkMode);
      }
    } catch (_) {}
  }

  darkModeNotifier.value = darkMode;

  runApp(NewsApp(nextRoute: nextRoute));
}

class NewsApp extends StatefulWidget {
  final String nextRoute;
  const NewsApp({super.key, required this.nextRoute});

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  @override
  void initState() {
    super.initState();
    darkModeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() => setState(() {});

  @override
  void dispose() {
    darkModeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeNews',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: darkModeNotifier.value ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/loading',
      routes: {
        '/loading': (_) => LoadingScreen(nextRoute: widget.nextRoute),
        '/': (_) => const WelcomeScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/interests': (_) => const InterestsScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
