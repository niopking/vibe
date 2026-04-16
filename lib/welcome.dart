import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

const kDark   = Color(0xFF161616);
const kGrey   = Color(0xFF2A2A2A);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _markSeenWelcomeAndNavigate(BuildContext context, String route) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenWelcome', true);
    navigator.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildDarkTheme(),
      child: Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 1),

            // Logo + slogan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Image.asset(
                    'images/logobeztr.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      width: 36,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: kOrange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),

                  // Slogan
                  const Text(
                    'Vijesti prilagođene tebi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Brzo, jasno i uvijek u toku.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 16,
                      letterSpacing: 0.2,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Dugmad na dnu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => _markSeenWelcomeAndNavigate(context, '/signup'),
                    child: const Text('Kreiraj nalog'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _markSeenWelcomeAndNavigate(context, '/login'),
                    child: const Text('Prijavi se'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('seenWelcome', true);
                      await prefs.setBool('isGuest', true);
                      navigator.pushReplacementNamed('/home');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.38),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: const Text('Nastavi kao gost'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }
}