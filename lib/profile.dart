import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    _marketing = prefs.getBool('marketing') ?? false;
    _darkMode = prefs.getBool('darkMode') ?? true;

    if (userId.isEmpty) {
      setState(() {
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

  void _submitArticle() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    String selectedCategory = 'Vijesti';
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    const categories = [
      'Vijesti',
      'Sport',
      'Tehnologija',
      'Kultura',
      'Ekonomija',
      'Zdravlje',
      'Zabava',
      'Ostalo',
    ];

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_note_rounded,
                                color: kOrange, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('Pošalji prijedlog članka',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Imaš priču? Pošalji nam prijedlog i naša redakcija će ga razmotriti.',
                        style: TextStyle(color: kTextMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      const _ModalLabel('NASLOV ČLANKA'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            const InputDecoration(hintText: 'O čemu se radi?'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Unesi naslov'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const _ModalLabel('KATEGORIJA'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: kGrey,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            dropdownColor: kGrey,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: kTextMuted),
                            items: categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => selectedCategory = v);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _ModalLabel('OPIS / SADRŽAJ'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: contentCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Ukratko opiši o čemu se radi, gdje si dobio info...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Unesi opis'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const _ModalLabel('KONTAKT (opcionalno)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: contactCtrl,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email ili broj telefona',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => loading = true);
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('prijedlozi')
                                        .add({
                                      'naslov': titleCtrl.text.trim(),
                                      'kategorija': selectedCategory,
                                      'sadrzaj': contentCtrl.text.trim(),
                                      'kontakt': contactCtrl.text.trim(),
                                      'userId': _userId,
                                      'email': _email,
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                    if (mounted) {
                                      _showSnack(
                                        context,
                                        'Prijedlog uspješno poslan! Hvala ti.',
                                        success: true,
                                      );
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
                              : const Text('Pošalji prijedlog'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutUs() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: kOrange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('O nama',
                style: TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Vibe je moderna news platforma koja donosi najsvježije vijesti iz Bosne i Hercegovine i regiona.\n\n'
          'Naš tim posvećen je istinitom, brzom i relevantnom izvještavanju. Vjerujemo u moć informisanosti i slobodu govora.\n\n'
          'Verzija: 1.0.0\n'
          '© 2025 Vibe. Sva prava zadržana.',
          style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Zatvori', style: TextStyle(color: kOrange)),
          ),
        ],
      ),
    );
  }

  void _showMarketing() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_outlined,
                  color: kOrange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Marketing',
                style: TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Primaj obavještenja o posebnim ponudama, novostima i promotivnom sadržaju od Vibe News platforme.',
                  style: TextStyle(
                      color: Color(0xFFCCCCCC), fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Marketing obavještenja',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    Switch(
                      value: _marketing,
                      onChanged: (v) async {
                        setDialogState(() => _marketing = v);
                        setState(() => _marketing = v);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('marketing', v);
                      },
                      activeThumbColor: kOrange,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zatvori', style: TextStyle(color: kOrange)),
          ),
        ],
      ),
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
          ? const Center(
              child: CircularProgressIndicator(color: kOrange),
            )
          : Column(
              children: [
                // ── Scrollable content ───────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                const SizedBox(height: 8),

                // ── Avatar + info ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: kOrange,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kOrange.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _email.isNotEmpty ? _email : 'Gost',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_age.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$_age godina',
                          style: const TextStyle(
                              color: kTextMuted, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Moj nalog ────────────────────────────────────────────
                const _SectionLabel('MOJ NALOG'),
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
                _ProfileTile(
                  icon: Icons.interests_outlined,
                  title: 'Moji interesi',
                  subtitle: 'Uredi kategorije koje pratiš',
                  onTap: () => Navigator.pushNamed(context, '/interests'),
                ),

                const SizedBox(height: 16),

                // ── Izgled ───────────────────────────────────────────────
                const _SectionLabel('IZGLED'),
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

                const SizedBox(height: 16),

                // ── Moj Vibe ─────────────────────────────────────────────
                const _SectionLabel('MOJ VIBE'),
                _ProfileTile(
                  icon: Icons.edit_note_rounded,
                  title: 'Moj Vibe',
                  subtitle: 'Imaš priču? Pošalji prijedlog članka!',
                  onTap: _submitArticle,
                  badge: 'NOVO',
                ),

                const SizedBox(height: 16),

                // ── O nama ───────────────────────────────────────────────
                const _SectionLabel('O NAMA'),
                _ProfileTile(
                  icon: Icons.info_outline_rounded,
                  title: 'O nama',
                  subtitle: 'Ko smo i šta radimo',
                  onTap: _showAboutUs,
                ),

                const SizedBox(height: 16),

                // ── Marketing ────────────────────────────────────────────
                const _SectionLabel('MARKETING'),
                _ProfileTile(
                  icon: Icons.campaign_outlined,
                  title: 'Marketing obavještenja',
                  subtitle: 'Ponude, novosti i promotivni sadržaj',
                  onTap: _showMarketing,
                ),

                const SizedBox(height: 16),

                // ── Društvene mreže ──────────────────────────────────────
                const _SectionLabel('DRUŠTVENE MREŽE'),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: kGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SocialIcon(
                        icon: Icons.photo_camera_outlined,
                        color: const Color(0xFFE1306C),
                        tooltip: 'Instagram',
                        onTap: () => _copySocialLink(
                            'Instagram', 'https://instagram.com/vibenews.ba'),
                      ),
                      _SocialIcon(
                        icon: Icons.facebook_outlined,
                        color: const Color(0xFF1877F2),
                        tooltip: 'Facebook',
                        onTap: () => _copySocialLink(
                            'Facebook', 'https://facebook.com/vibenews'),
                      ),
                      _SocialIcon(
                        icon: Icons.alternate_email_rounded,
                        color: Colors.white,
                        tooltip: 'X (Twitter)',
                        onTap: () =>
                            _copySocialLink('X', 'https://x.com/vibenews'),
                      ),
                      _SocialIcon(
                        icon: Icons.play_circle_outline_rounded,
                        color: const Color(0xFF69C9D0),
                        tooltip: 'TikTok',
                        onTap: () => _copySocialLink(
                            'TikTok', 'https://tiktok.com/@vibenews.ba'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Odjavi se ────────────────────────────────────────────
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.25)),
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

                const SizedBox(height: 10),

                // ── Obriši nalog ─────────────────────────────────────────
                GestureDetector(
                  onTap: _deleteAccount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFE57373), size: 18),
                        SizedBox(width: 8),
                        Text('Obriši nalog',
                            style: TextStyle(
                              color: Color(0xFFE57373),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16 + bottomPad + 80),
                    ],
                  ),
                ),
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
      padding: const EdgeInsets.only(bottom: 8, top: 4),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kOrange, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kOrange, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
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
  final String tooltip;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

class _ModalLabel extends StatelessWidget {
  final String text;
  const _ModalLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: kOrange,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
