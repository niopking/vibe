import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about_us.dart';
import 'marketing.dart';
import 'moj_vibe.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kTextMuted = Color(0xFF888888);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _email = '';
  String _age = '';
  String _userId = '';
  bool _marketing = false;
  bool _darkMode = true;
  bool _loadingUser = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final isGuest = prefs.getBool('isGuest') ?? false;
    _marketing = prefs.getBool('marketing') ?? false;
    _darkMode = prefs.getBool('darkMode') ?? true;

    if (userId.isEmpty) {
      setState(() {
        _isGuest = isGuest;
        _loadingUser = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('korisnici')
        .doc(userId)
        .get();

    if (mounted) {
      setState(() {
        _userId = userId;
        _email = doc.data()?['email'] ?? '';
        _age = doc.data()?['age']?.toString() ?? '';
        _loadingUser = false;
      });
    }
  }

  Future<void> _saveField(String field, dynamic value) async {
    if (_userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('korisnici')
        .doc(_userId)
        .update({field: value});
  }

  void _editEmail() {
    final ctrl = TextEditingController(text: _email);
    _showEditDialog(
      title: 'Promijeni email',
      label: 'Nova email adresa',
      controller: ctrl,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Unesi email';
        if (!v.contains('@')) return 'Nevažeći email';
        return null;
      },
      onSave: (v) async {
        await _saveField('email', v);
        await _saveField('emailLower', v.toLowerCase());
        setState(() => _email = v);
      },
    );
  }

  void _editAge() {
    final ctrl = TextEditingController(text: _age);
    _showEditDialog(
      title: 'Promijeni godine',
      label: 'Vaše godine',
      controller: ctrl,
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Unesi godine';
        final n = int.tryParse(v);
        if (n == null || n < 1 || n > 120) return 'Nevažeće godine';
        return null;
      },
      onSave: (v) async {
        await _saveField('age', int.parse(v));
        setState(() => _age = v);
      },
    );
  }

  void _changePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure1 = true;
    bool obscure2 = true;
    bool obscure3 = true;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promijeni lozinku',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    _buildPassField(
                      ctrl: currentCtrl,
                      label: 'Trenutna lozinka',
                      obscure: obscure1,
                      onToggle: () => setModalState(() => obscure1 = !obscure1),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Unesi lozinku' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildPassField(
                      ctrl: newCtrl,
                      label: 'Nova lozinka',
                      obscure: obscure2,
                      onToggle: () => setModalState(() => obscure2 = !obscure2),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Unesi lozinku';
                        if (v.length < 6) return 'Min. 6 znakova';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPassField(
                      ctrl: confirmCtrl,
                      label: 'Potvrdi novu lozinku',
                      obscure: obscure3,
                      onToggle: () => setModalState(() => obscure3 = !obscure3),
                      validator: (v) {
                        if (v != newCtrl.text) return 'Lozinke se ne podudaraju';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => loading = true);
                                try {
                                  final doc = await FirebaseFirestore.instance
                                      .collection('korisnici')
                                      .doc(_userId)
                                      .get();
                                  final stored =
                                      doc.data()?['password'] as String?;
                                  if (stored != currentCtrl.text) {
                                    if (ctx.mounted) {
                                      _showSnack(
                                          ctx, 'Trenutna lozinka je pogrešna.');
                                    }
                                    return;
                                  }
                                  await FirebaseFirestore.instance
                                      .collection('korisnici')
                                      .doc(_userId)
                                      .update({'password': newCtrl.text});
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (mounted) {
                                    _showSnack(context,
                                        'Lozinka uspješno promijenjena!',
                                        success: true);
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setModalState(() => loading = false);
                                  }
                                }
                              },
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sačuvaj'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPassField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Color(0xFF666666), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF666666),
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  void _showEditDialog({
    required String title,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
    required Future<void> Function(String) onSave,
  }) {
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: label),
                      validator: validator,
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => loading = true);
                                try {
                                  await onSave(controller.text.trim());
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (mounted) {
                                    _showSnack(
                                        context, 'Uspješno sačuvano!',
                                        success: true);
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    _showSnack(ctx, 'Greška: $e');
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setModalState(() => loading = false);
                                  }
                                }
                              },
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sačuvaj'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutUsScreen()),
    );
  }

  void _showMarketing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketingScreen()),
    );
  }

  void _copySocialLink(String platform, String url) {
    Clipboard.setData(ClipboardData(text: url));
    _showSnack(context, '$platform link kopiran!', success: true);
  }

  void _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Obriši nalog',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: const Text(
          'Ova radnja je nepovratna. Svi tvoji podaci će biti trajno izbrisani.',
          style: TextStyle(color: kTextMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && _userId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('korisnici')
          .doc(_userId)
          .delete();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Odjava',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: const Text('Sigurno se želiš odjaviti?',
            style: TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Otkaži', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Odjavi se', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  void _showSnack(BuildContext ctx, String msg, {bool success = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF323232),
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline,
              color: success ? kOrange : const Color(0xFFFFB74D),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String get _initials {
    if (_email.isEmpty) return '?';
    return _email[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: _loadingUser
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 96),
              children: [
                // ── Profile header ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kOrange.withValues(alpha: 0.14),
                        kOrange.withValues(alpha: 0.04),
                        kGrey,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: kOrange.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: kOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kOrange.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _email.isNotEmpty ? _email : 'Gost',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_age.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$_age godina',
                          style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Moj nalog ───────────────────────────────────────
                const _SectionLabel('MOJ NALOG'),
                if (_isGuest) ...[
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kOrange.withValues(alpha: 0.18),
                            kOrange.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: kOrange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded,
                              color: kOrange, size: 20),
                          SizedBox(width: 10),
                          Text('Napravi nalog',
                              style: TextStyle(
                                color: kOrange,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  _ProfileTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Email adresa',
                    subtitle: _email.isNotEmpty ? _email : 'Nije postavljeno',
                    onTap: _editEmail,
                  ),
                  _ProfileTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Lozinka',
                    subtitle: '••••••••',
                    onTap: _changePassword,
                  ),
                  _ProfileTile(
                    icon: Icons.cake_outlined,
                    title: 'Godine',
                    subtitle: _age.isNotEmpty ? '$_age god.' : 'Nije postavljeno',
                    onTap: _editAge,
                  ),
                ],

                const SizedBox(height: 20),

                // ── Postavke ────────────────────────────────────────
                const _SectionLabel('POSTAVKE'),
                _ToggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tamni način',
                  value: _darkMode,
                  onChanged: (v) async {
                    setState(() => _darkMode = v);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('darkMode', v);
                  },
                ),
                if (!_isGuest)
                  _ProfileTile(
                    icon: Icons.campaign_outlined,
                    title: 'Marketing obavještenja',
                    subtitle: _marketing ? 'Uključeno' : 'Isključeno',
                    onTap: _showMarketing,
                  ),

                const SizedBox(height: 20),

                if (!_isGuest) ...[
                  // ── Moj Vibe ────────────────────────────────────────
                  const _SectionLabel('MOJ VIBE'),
                  _ProfileTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Moj Vibe',
                    subtitle: 'Imaš priču? Javi nam!',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MojVibeScreen(
                          userId: _userId,
                          email: _email,
                        ),
                      ),
                    ),
                    badge: 'NOVO',
                  ),
                ],

                const SizedBox(height: 20),

                // ── O nama + Društvene mreže ────────────────────────
                const _SectionLabel('O NAMA'),
                _ProfileTile(
                  icon: Icons.info_outline_rounded,
                  title: 'O nama',
                  subtitle: 'Ko smo i šta radimo',
                  onTap: _showAboutUs,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  decoration: BoxDecoration(
                    color: kGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'PRATITE NAS',
                        style: TextStyle(
                          color: kTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _SocialIcon(
                            icon: Icons.camera_alt_rounded,
                            color: const Color(0xFFE1306C),
                            label: 'Instagram',
                            onTap: () => _copySocialLink('Instagram',
                                'https://instagram.com/vibenews.ba'),
                          ),
                          _SocialIcon(
                            icon: Icons.facebook_rounded,
                            color: const Color(0xFF1877F2),
                            label: 'Facebook',
                            onTap: () => _copySocialLink('Facebook',
                                'https://facebook.com/vibenews'),
                          ),
                          _SocialIcon(
                            icon: Icons.close_rounded,
                            color: Colors.white,
                            label: 'X',
                            onTap: () => _copySocialLink(
                                'X', 'https://x.com/vibenews'),
                          ),
                          _SocialIcon(
                            icon: Icons.music_note_rounded,
                            color: const Color(0xFF69C9D0),
                            label: 'TikTok',
                            onTap: () => _copySocialLink('TikTok',
                                'https://tiktok.com/@vibenews.ba'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                if (!_isGuest) ...[
                  // ── Odjavi se ───────────────────────────────────────
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Odjavi se',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _deleteAccount,
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Obriši nalog',
                          style: TextStyle(
                            color: kTextMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: kTextMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: kOrange,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: kOrange.withValues(alpha: 0.2),
              width: 0.6,
            ),
          ),
          child: Icon(icon, color: kOrange, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: const TextStyle(color: kTextMuted, fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: kTextMuted, size: 18),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        secondary: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: kOrange.withValues(alpha: 0.2),
              width: 0.6,
            ),
          ),
          child: Icon(icon, color: kOrange, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: kOrange,
        inactiveTrackColor: Colors.white12,
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

