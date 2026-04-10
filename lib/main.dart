import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'loading.dart';
import 'welcome.dart';
import 'login.dart';
import 'signup.dart';
import 'interests.dart';
import 'home.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final seenWelcome = prefs.getBool('seenWelcome') ?? false;
  final rememberMe = prefs.getBool('rememberMe') ?? false;
  final loggedInEmail = prefs.getString('loggedInEmail');

  final nextRoute = !seenWelcome
      ? '/welcome'
      : (rememberMe && loggedInEmail != null ? '/home' : '/login');

  runApp(NewsApp(nextRoute: nextRoute));
}

class NewsApp extends StatelessWidget {
  final String nextRoute;
  const NewsApp({super.key, required this.nextRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeNews',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kDark,
        colorScheme: const ColorScheme.dark(
          primary: kOrange,
          surface: kDark,
          onPrimary: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kGrey,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kOrange, width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 15),
          labelStyle: const TextStyle(color: Color(0xFF888888)),
          errorStyle: const TextStyle(color: Color(0xFFFF5252)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white38, width: 1),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF999999), fontSize: 14),
        ),
      ),
      initialRoute: '/loading',
      routes: {
        '/loading': (_) => LoadingScreen(nextRoute: nextRoute),
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
