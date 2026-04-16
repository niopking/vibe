import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

const _heroImage =
    'https://vibeadria.com/wp-content/uploads/2025/08/Vibe-Adria-Wallpaper-1-1044x587.png';

const _categories = [
  'Vijesti',
  'Sport',
  'Tehnologija',
  'Kultura',
  'Ekonomija',
  'Zdravlje',
  'Zabava',
  'Ostalo',
];

// ── Status helpers ────────────────────────────────────────────────────────────

_StatusStyle _statusStyle(String status) {
  switch (status) {
    case 'prihvacen':
      return _StatusStyle(
        label: 'Prihvaćen',
        bg: const Color(0xFF1A3A1A),
        border: const Color(0xFF2E7D32),
        text: const Color(0xFF66BB6A),
        icon: Icons.check_circle_outline_rounded,
      );
    case 'odbijen':
      return _StatusStyle(
        label: 'Odbijen',
        bg: const Color(0xFF3A1A1A),
        border: const Color(0xFFC62828),
        text: const Color(0xFFEF9A9A),
        icon: Icons.cancel_outlined,
      );
    default:
      return _StatusStyle(
        label: 'U obradi',
        bg: const Color(0xFF2A2510),
        border: const Color(0xFF7B6A00),
        text: const Color(0xFFFFCA28),
        icon: Icons.hourglass_empty_rounded,
      );
  }
}

class _StatusStyle {
  final String label;
  final Color bg, border, text;
  final IconData icon;
  const _StatusStyle({
    required this.label,
    required this.bg,
    required this.border,
    required this.text,
    required this.icon,
  });
}

String _fmtTimestamp(Timestamp? ts) {
  if (ts == null) return '';
  final dt = ts.toDate().toLocal();
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Maj', 'Jun',
    'Jul', 'Avg', 'Sep', 'Okt', 'Nov', 'Dec',
  ];
  return '${dt.day}. ${months[dt.month - 1]} ${dt.year}.';
}

// ─────────────────────────────────────────────────────────────────────────────

class MojVibeScreen extends StatefulWidget {
  final String userId;
  final String email;

  const MojVibeScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<MojVibeScreen> createState() => _MojVibeScreenState();
}

class _MojVibeScreenState extends State<MojVibeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _selectedCategory = 'Vijesti';
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('clanci_korisnika').add({
        'naslov': _titleCtrl.text.trim(),
        'kategorija': _selectedCategory,
        'sadrzaj': _contentCtrl.text.trim(),
        'kontakt': _contactCtrl.text.trim(),
        'userId': widget.userId,
        'email': widget.email,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'u_obradi',
        'feedback': '',
      });
      if (mounted) setState(() => _sent = true);
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
                Expanded(
                  child: Text('Greška: $e',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _imageHeight = 260.0;
  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    if (_sent) {
      return Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(
          child: _SuccessView(onBack: () => Navigator.pop(context)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: Stack(
        children: [
          // ── Fixed hero image ────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: _imageHeight,
            child: Image.network(
              _heroImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: context.surfaceLight,
                child: Center(
                  child: Icon(Icons.image_outlined,
                      color: context.textMuted, size: 48),
                ),
              ),
            ),
          ),

          // ── Form scrolls over image ─────────────────────────────
          _FormView(
            formKey: _formKey,
            titleCtrl: _titleCtrl,
            contentCtrl: _contentCtrl,
            contactCtrl: _contactCtrl,
            selectedCategory: _selectedCategory,
            loading: _loading,
            imageOffset: _imageHeight - _overlap,
            userId: widget.userId,
            onCategoryChanged: (v) => setState(() => _selectedCategory = v),
            onSubmit: _submit,
          ),

          // ── Floating app bar ────────────────────────────────────
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, color: kOrange, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Vibe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Moji prijedlozi section ───────────────────────────────────────────────────

class _MojiPrijedloziSection extends StatelessWidget {
  final String userId;
  const _MojiPrijedloziSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clanci_korisnika')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();

        final docs = snap.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('MOJI PRIJEDLOZI'),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'u_obradi';
              final feedback = (data['feedback'] as String? ?? '').trim();
              final style = _statusStyle(status);
              final ts = data['timestamp'] as Timestamp?;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: style.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['naslov'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: style.border.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: style.border.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(style.icon, color: style.text, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                style.label,
                                style: TextStyle(
                                  color: style.text,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: kOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data['kategorija'] as String? ?? '',
                            style: const TextStyle(
                                color: kOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (ts != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _fmtTimestamp(ts),
                            style: TextStyle(
                                color: context.textMuted, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    if (feedback.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Divider(color: context.divider, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.feedback_outlined,
                              color: style.text, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              feedback,
                              style: TextStyle(
                                color: style.text.withValues(alpha: 0.9),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Form view ─────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final TextEditingController contactCtrl;
  final String selectedCategory;
  final bool loading;
  final double imageOffset;
  final String userId;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.titleCtrl,
    required this.contentCtrl,
    required this.contactCtrl,
    required this.selectedCategory,
    required this.loading,
    required this.imageOffset,
    required this.userId,
    required this.onCategoryChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: imageOffset),
          Container(
            decoration: BoxDecoration(
              color: context.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PageTitle('Moj Vibe'),
                const SizedBox(height: 8),

                _infoCard(context, [
                  Text(
                    'Vibe je više od sajta – to je osjećaj koji ostaje.',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vibe Adria je regionalni lifestyle portal koji spaja inspiraciju, putovanja, događaje, sport, muziku, ljude i priče s karakterom. Kroz svjež i pažljivo odabran sadržaj, u prepoznatljivom tonu koji ne podilazi, ali uvijek poziva – nudimo ti dnevnu dozu dobrog vibea.',
                    style: TextStyle(color: context.textBody, fontSize: 14, height: 1.65),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Vjerujemo u sadržaj koji ima glas, u teme koje ostavljaju trag, i u pristup koji ne robuje trendovima, već ih stvara.',
                    style: TextStyle(color: context.textBody, fontSize: 14, height: 1.65),
                  ),
                ]),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kOrange.withValues(alpha: 0.18),
                        kOrange.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_note_rounded,
                            color: kOrange, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Imaš priču koja vrijedi?',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ako imaš pogled na stvarnost koji pokreće, mjesto koje ti je promijenilo ritam dana, misao koja zaslužuje pažnju – podijeli je s nama. Tvoj vibe može postati dio našeg sadržaja.',
                              style: TextStyle(
                                color: context.textBody,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (userId.isNotEmpty) _MojiPrijedloziSection(userId: userId),

                const _FieldLabel('NOVI PRIJEDLOG'),
                const SizedBox(height: 16),

                const _FieldLabel('NASLOV ČLANKA'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: titleCtrl,
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'O čemu se radi?',
                    filled: true,
                    fillColor: context.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kOrange, width: 1.5),
                    ),
                    hintStyle: TextStyle(color: context.textMuted),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Unesi naslov' : null,
                ),

                const SizedBox(height: 20),

                const _FieldLabel('KATEGORIJA'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: context.surface,
                      style: TextStyle(color: context.textPrimary, fontSize: 15),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: context.textMuted),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) onCategoryChanged(v);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const _FieldLabel('OPIS / SADRŽAJ'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: contentCtrl,
                  style: TextStyle(color: context.textPrimary),
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Ukratko opiši o čemu se radi, gdje si dobio info...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: context.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kOrange, width: 1.5),
                    ),
                    hintStyle: TextStyle(color: context.textMuted),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Unesi opis' : null,
                ),

                const SizedBox(height: 20),

                const _FieldLabel('KONTAKT (opcionalno)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: contactCtrl,
                  style: TextStyle(color: context.textPrimary),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email ili broj telefona',
                    filled: true,
                    fillColor: context.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kOrange, width: 1.5),
                    ),
                    hintStyle: TextStyle(color: context.textMuted),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Pošalji prijedlog',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onBack;
  const _SuccessView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kOrange.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.check_rounded, color: kOrange, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Prijedlog poslan!',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hvala ti! Naša redakcija će pregledati tvoj prijedlog i javiti se ako bude odabran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textMuted,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textPrimary,
                  side: BorderSide(color: context.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Nazad na profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _infoCard(BuildContext context, List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _PageTitle extends StatelessWidget {
  final String title;
  const _PageTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: kOrange,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
