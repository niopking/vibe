import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kGreyLight = Color(0xFF3A3A3A);
const kTextMuted = Color(0xFF888888);


class ArtikalScreen extends StatefulWidget {
  final Article article;
  const ArtikalScreen({super.key, required this.article});

  @override
  State<ArtikalScreen> createState() => _ArtikalScreenState();
}

class _ArtikalScreenState extends State<ArtikalScreen> {
  final _commentController = TextEditingController();
  late final ScrollController _scrollController;
  double _scroll = 0;
  late List<Map<String, dynamic>> _comments;

  static const _imageHeight = 320.0;
  static const _overlap = 32.0;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.article.comments);
    _scrollController = ScrollController()
      ..addListener(() {
        final s = _scrollController.offset.clamp(0.0, 300.0);
        if ((s - _scroll).abs() > 0.5) setState(() => _scroll = s);
      });
  }

  Future<void> _sendComment() async {
    final tekst = _commentController.text.trim();
    if (tekst.isEmpty) return;

    final noviKomentar = {'osoba': 'TODO', 'tekst': tekst};

    setState(() {
      _comments.add(noviKomentar);
      _commentController.clear();
    });

    await FirebaseFirestore.instance
        .collection('vjesti')
        .doc(widget.article.id)
        .update({
      'komentari': FieldValue.arrayUnion([noviKomentar]),
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // 1.12× zoomed at top → 1.0× at scroll=200 (zoom out as you scroll)
  double get _imageScale =>
      1.12 - (0.12 * (_scroll / 200).clamp(0.0, 1.0));

  // Top bar (logo+search+bell) fades from 1→0 over first 90px
  double get _topBarOpacity =>
      (1.0 - _scroll / 90).clamp(0.0, 1.0);

  // Floating back button fades in as top bar fades out
  double get _backOpacity =>
      (_scroll / 90).clamp(0.0, 1.0);

  String get _tekst => widget.article.tekst;

  int get _readingMinutes {
    final words = _tekst.split(RegExp(r'\s+')).length;
    return (words / 200).ceil().clamp(1, 60);
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kDark,
      extendBody: true,
      bottomNavigationBar: _ArticleBottomNav(
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          // ── 1. Fixed hero image with zoom-out parallax ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _imageHeight,
            child: ClipRect(
              child: Transform.scale(
                scale: _imageScale,
                alignment: Alignment.center,
                child: Image.network(
                  widget.article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: kGrey),
                ),
              ),
            ),
          ),

          // ── 2. Scrollable content ───────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space for hero image (minus overlap)
                const SizedBox(height: _imageHeight - _overlap),

                // Content sheet
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: kDark,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),

                      // Meta row
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _CategoryBadge(label: widget.article.category),
                            const SizedBox(width: 12),
                            const Icon(Icons.schedule_rounded,
                                color: kTextMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '$_readingMinutes min čitanja',
                              style: const TextStyle(
                                  color: kTextMuted, fontSize: 12),
                            ),
                            const Spacer(),
                            const Icon(Icons.chat_bubble_outline_rounded,
                                color: kTextMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${_comments.length}',
                              style: const TextStyle(
                                  color: kTextMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          widget.article.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Date with accent bar
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: kOrange,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.article.date,
                              style: const TextStyle(
                                  color: kTextMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      _Divider(),

                      const SizedBox(height: 26),

                      // Body text (rich formatting)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildRichBody(_tekst),
                      ),

                      // ── Comments ────────────────────────────────────────
                      const SizedBox(height: 40),
                      _Divider(),
                      const SizedBox(height: 24),

                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Text(
                              'Komentari',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_comments.length}',
                                style: const TextStyle(
                                  color: kTextMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (_comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Text(
                            'Budi prvi koji će komentarisati.',
                            style:
                                TextStyle(color: kTextMuted, fontSize: 13),
                          ),
                        ),

                      ..._comments.map((k) => _KomentarItem(
                            osoba: k['osoba'] as String? ?? '',
                            tekst: k['tekst'] as String? ?? '',
                          )),

                      const SizedBox(height: 16),

                      // Add comment input
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kGrey,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 8, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    hintText: 'Napiši komentar...',
                                    hintStyle: TextStyle(
                                        color: kTextMuted, fontSize: 14),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _sendComment,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: kOrange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Preporučujemo ─────────────────────────────────────
                      const SizedBox(height: 40),
                      _Divider(),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.recommend_rounded,
                                color: kOrange, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Preporučujemo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _RecommendedSection(
                          currentTitle: widget.article.title),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Fading top bar: logo + search + bell ─────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: _topBarOpacity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Row(
                      children: [
                        // Back arrow replaces logo space
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.18),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Persistent back button (fades IN as top bar fades OUT) ───
          Positioned(
            top: safeTop + 8,
            left: 12,
            child: Opacity(
              opacity: _backOpacity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichBody(String text) {
    final paragraphs = text.split('\n\n');
    final widgets = <Widget>[];
    for (int i = 0; i < paragraphs.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 20));
      widgets.add(_buildParagraph(paragraphs[i], isLead: i == 0));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildParagraph(String para, {bool isLead = false}) {
    if (isLead) {
      // Lead paragraph: white, bold — journalistic intro
      return Text(
        para,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.7,
        ),
      );
    }

    // Other paragraphs: uniform muted style
    return Text(
      para,
      style: const TextStyle(
        color: Color(0xFFBBBBBB),
        fontSize: 16,
        height: 1.75,
      ),
    );
  }

}

// ── Article bottom nav ─────────────────────────────────────────────────────────

class _ArticleBottomNav extends StatelessWidget {
  final VoidCallback onBack;
  const _ArticleBottomNav({required this.onBack});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Početna'),
      _NavItem(icon: Icons.grid_view_rounded, label: 'Kategorije'),
      _NavItem(icon: Icons.settings_outlined, label: 'Podešavanja'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kGrey,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == 0; // Home is always "selected" in articles
              return Expanded(
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon,
                          size: 23,
                          color: selected ? kOrange : kTextMuted),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? kOrange : kTextMuted,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Comment card ───────────────────────────────────────────────────────────────

class _KomentarItem extends StatelessWidget {
  final String osoba;
  final String tekst;
  const _KomentarItem({required this.osoba, required this.tekst});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: kGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            margin: const EdgeInsets.only(top: 3, right: 12),
            height: 16,
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  osoba,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tekst,
                  style: const TextStyle(
                    color: Color(0xFFBBBBBB),
                    fontSize: 14,
                    height: 1.55,
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

// ── Helpers ────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

// ── Recommended section ────────────────────────────────────────────────────────

class _RecommendedSection extends StatelessWidget {
  final String currentTitle;
  const _RecommendedSection({required this.currentTitle});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: fetchArticles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final recs = (snapshot.data!
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
            .where((a) => a.title != currentTitle)
            .take(3)
            .toList();

        return Column(
          children: recs.map((a) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtikalScreen(article: a),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: kGrey,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                        child: SizedBox(
                          width: 100,
                          height: 88,
                          child: Image.network(
                            a.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: kGreyLight),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CategoryBadge(label: a.category),
                              const SizedBox(height: 6),
                              Text(
                                a.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    a.date,
                                    style: const TextStyle(
                                      color: kTextMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: kTextMuted,
                                      size: 11),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${a.comments.length}',
                                    style: const TextStyle(
                                      color: kTextMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kOrange,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: kOrange.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
