import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kOrange = Color(0xFFFF8200);
const kDark   = Color(0xFF161616);
const kGrey   = Color(0xFF2A2A2A);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _rememberMe = false;
  bool _obscure    = true;
  bool _loading    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final emailLower = email.toLowerCase();
    final password = _passCtrl.text;

    setState(() => _loading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('korisnici')
          .where('emailLower', isEqualTo: emailLower)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF323232),
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Color(0xFFFFB74D)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Pogrešan email ili lozinka.', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          );
        }
        return;
      }

      final userDoc = query.docs.first;
      final storedPassword = userDoc.data()['password'] as String?;
      if (storedPassword != password) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF323232),
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Color(0xFFFFB74D)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Pogrešan email ili lozinka.', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('rememberMe', true);
        await prefs.setString('loggedInEmail', emailLower);
      } else {
        await prefs.setBool('rememberMe', false);
        await prefs.remove('loggedInEmail');
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF323232),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFFB74D)),
                const SizedBox(width: 12),
                Expanded(child: Text('Greška pri prijavi: $e', style: const TextStyle(color: Colors.white))),
              ],
            ),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const SizedBox(height: 56),

                const _Logo(size: 48),
                const SizedBox(height: 22),
                Text('Dobrodošao nazad', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                  'Prijavi se na svoj nalog',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 15),
                ),

                const SizedBox(height: 38),
                const _FieldLabel('EMAIL ADRESA'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'tvoj@email.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF666666), size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Unesi email adresu';
                    if (!v.contains('@')) return 'Nevažeći format emaila';
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const _FieldLabel('LOZINKA'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF666666), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF666666),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Unesi lozinku';
                    if (v.length < 6) return 'Lozinka mora imati najmanje 6 znakova';
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    _Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      label: 'Zapamti me',
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Zaboravljena lozinka?',
                        style: TextStyle(color: kOrange, fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Prijavi se'),
                ),

                const SizedBox(height: 28),
                const _OrDivider(),
                const SizedBox(height: 22),

                OutlinedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isGuest', true);
                    if (mounted) Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text('Nastavi kao gost'),
                ),

                const SizedBox(height: 28),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Nemaš nalog?  ", style: TextStyle(color: Color(0xFF888888))),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text(
                          'Registruj se',
                          style: TextStyle(color: kOrange, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
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
          style: TextStyle(color: Colors.white, fontSize: size * 0.55, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white12, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('ili', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
        ),
        Expanded(child: Divider(color: Colors.white12, thickness: 1)),
      ],
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  const _Checkbox({required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: value ? kOrange : Colors.transparent,
              border: Border.all(color: value ? kOrange : const Color(0xFF555555), width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: value ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
        ],
      ),
    );
  }
}