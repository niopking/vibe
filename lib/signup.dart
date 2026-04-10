import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kOrange = Color(0xFFFF8200);
const kDark   = Color(0xFF161616);
const kGrey   = Color(0xFF2A2A2A);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _ageCtrl   = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final emailLower = email.toLowerCase();

    setState(() => _loading = true);
    try {
      final existing = await FirebaseFirestore.instance
          .collection('korisnici')
          .where('emailLower', isEqualTo: emailLower)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
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
                  Expanded(child: Text('Email već postoji. Probaj drugi.', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          );
        }
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('korisnici').add({
        'email': email,
        'emailLower': emailLower,
        'age': int.parse(_ageCtrl.text),
        'password': _passCtrl.text, // Note: Storing plain password is insecure
        'interests': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/interests', arguments: doc.id);
      }
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
                Expanded(child: Text('Greška pri registraciji: $e', style: const TextStyle(color: Colors.white))),
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
                const SizedBox(height: 50),

                const _Logo(size: 48),
                const SizedBox(height: 22),
                Text('Kreiraj nalog', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                  'Brza registracija — samo par sekundi',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 15),
                ),

                const SizedBox(height: 36),

                // ── Email ──────────────────────────────────────────────────
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
                    final emailReg = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w]{2,4}$');
                    if (!emailReg.hasMatch(v)) return 'Nevažeći format emaila';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Godine ─────────────────────────────────────────────────
                const _FieldLabel('GODINE'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'npr. 25',
                    prefixIcon: Icon(Icons.cake_outlined, color: Color(0xFF666666), size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Unesi godine';
                    final age = int.tryParse(v);
                    if (age == null) return 'Unesi broj';
                    if (age < 13 || age > 120) return 'Unesi valjane godine (13–120)';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Lozinka ────────────────────────────────────────────────
                const _FieldLabel('LOZINKA'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure1,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Min. 8 znakova',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF666666), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF666666),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Unesi lozinku';
                    if (v.length < 8) return 'Lozinka mora imati najmanje 8 znakova';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Potvrdi lozinku ────────────────────────────────────────
                const _FieldLabel('POTVRDI LOZINKU'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pass2Ctrl,
                  obscureText: _obscure2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ponovi lozinku',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF666666), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF666666),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Potvrdi lozinku';
                    if (v != _passCtrl.text) return 'Lozinke se ne podudaraju';
                    return null;
                  },
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Nastavi'),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Već imaš nalog?  ", style: TextStyle(color: Color(0xFF888888))),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          'Prijavi se',
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