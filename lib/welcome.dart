import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kOrange = Color(0xFFFF8200);
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              const _Logo(size: 64),
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.15),
                  children: [
                    TextSpan(text: 'Vibe', style: TextStyle(color: kOrange)),
                    TextSpan(text: 'News', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Vijesti prilagođene tebi.\nBrzo, jasno, bez šuma.',
                style: TextStyle(color: Color(0xFF999999), fontSize: 17, height: 1.55),
              ),

              const Spacer(flex: 3),

              const _FeatureRow(icon: Icons.bolt_rounded,     label: 'Uvijek svježe vijesti'),
              const SizedBox(height: 12),
              const _FeatureRow(icon: Icons.tune_rounded,     label: 'Personalizovani feed'),
              const SizedBox(height: 12),
              const _FeatureRow(icon: Icons.bookmark_rounded, label: 'Sačuvaj za čitanje'),

              const Spacer(flex: 2),

              ElevatedButton(
                onPressed: () => _markSeenWelcomeAndNavigate(context, '/signup'),
                child: const Text('Kreiraj nalog'),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => _markSeenWelcomeAndNavigate(context, '/login'),
                child: const Text('Prijavi se'),
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  '© 2025 VibeNews',
                  style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kOrange,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Center(
        child: Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.55,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kOrange, size: 18),
        ),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 15)),
      ],
    );
  }
}