import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'models.dart';
import 'saved_service.dart';

const _kAdImages = [
  'https://pbs.twimg.com/profile_images/876774392092659712/kE_hR2ng_400x400.jpg',
  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT5AR3vQqp23VQVmscIaWrt7DTOtCQJdQSBjw&s',
];

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
  bool _showAllComments = false;

  static const _imageHeight = 320.0;
  static const _overlap = 32.0;

  @override
  void initState() {
    super.initState();
    _comments = [];
    _scrollController = ScrollController()
      ..addListener(() {
        final s = _scrollController.offset.clamp(0.0, 300.0);
        if ((s - _scroll).abs() > 0.5) setState(() => _scroll = s);
      });
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('wp_komentari')
          .doc(widget.article.id)
          .get();
      if (doc.exists && mounted) {
        final raw = doc.data()?['komentari'];
        final komentari = raw is List
            ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : <Map<String, dynamic>>[];
        setState(() => _comments = komentari);
      }
    } catch (_) {}
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
        .collection('wp_komentari')
        .doc(widget.article.id)
        .set({
      'komentari': FieldValue.arrayUnion([noviKomentar]),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  double get _imageScale =>
      1.12 - (0.12 * (_scroll / 200).clamp(0.0, 1.0));
  double get _topBarOpacity => (1.0 - _scroll / 90).clamp(0.0, 1.0);
  double get _backOpacity => (_scroll / 90).clamp(0.0, 1.0);
  String get _tekst => widget.article.tekst;

  int get _readingMinutes {
    final words = _tekst.split(RegExp(r'\s+')).length;
    return (words / 200).ceil().clamp(1, 60);
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.bg,
      extendBody: true,
      bottomNavigationBar: _ArticleBottomNav(onBack: () => Navigator.pop(context)),
      body: Stack(
        children: [
          // ── 1. Fixed hero image ────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: _imageHeight,
            child: ClipRect(
              child: Transform.scale(
                scale: _imageScale,
                alignment: Alignment.center,
                child: Image.network(
                  widget.article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: context.surface),
                ),
              ),
            ),
          ),

          // ── 2. Scrollable content ──────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: _imageHeight - _overlap),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.bg,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _CategoryBadge(label: widget.article.category),
                            const SizedBox(width: 12),
                            Icon(Icons.schedule_rounded,
                                color: context.textMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '$_readingMinutes min čitanja',
                              style: TextStyle(
                                  color: context.textMuted, fontSize: 12),
                            ),
                            const Spacer(),
                            Icon(Icons.chat_bubble_outline_rounded,
                                color: context.textMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${_comments.length}',
                              style: TextStyle(
                                  color: context.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          widget.article.title,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              style: TextStyle(
                                  color: context.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),
                      _Divider(),
                      const SizedBox(height: 26),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildRichBody(_tekst),
                      ),

                      // ── Comments ────────────────────────────────────────
                      const SizedBox(height: 40),
                      _Divider(),
                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              'Komentari',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_comments.length}',
                                style: TextStyle(
                                  color: context.textMuted,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Text(
                            'Budi prvi koji će komentarisati.',
                            style: TextStyle(
                                color: context.textMuted, fontSize: 13),
                          ),
                        ),

                      ...(_showAllComments
                              ? _comments
                              : _comments.take(3).toList())
                          .map((k) => _KomentarItem(
                                osoba: k['osoba'] as String? ?? '',
                                tekst: k['tekst'] as String? ?? '',
                              )),

                      if (_comments.length > 3 && !_showAllComments)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _showAllComments = true),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.border),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.expand_more_rounded,
                                      color: kOrange, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Vidi još komentara',
                                    style: TextStyle(
                                      color: kOrange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.border),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 14),
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    hintText: 'Napiši komentar...',
                                    hintStyle: TextStyle(
                                        color: context.textMuted,
                                        fontSize: 14),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
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

                      // ── Preporučujemo ──────────────────────────────────
                      const SizedBox(height: 40),
                      _Divider(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(Icons.recommend_rounded,
                                color: kOrange, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Preporučujemo',
                              style: TextStyle(
                                color: context.textPrimary,
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

          // ── 3. Fading top bar ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showShareSheet(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(Icons.ios_share_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _BookmarkButton(article: widget.article, glass: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Persistent back + actions ──────────────────────────────
          Positioned(
            top: safeTop + 8, left: 12,
            child: Opacity(
              opacity: _backOpacity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.border),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: context.textPrimary, size: 20),
                ),
              ),
            ),
          ),
          Positioned(
            top: safeTop + 8, right: 12,
            child: Opacity(
              opacity: _backOpacity,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showShareSheet(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.border),
                      ),
                      child: Icon(Icons.ios_share_rounded,
                          color: context.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _BookmarkButton(article: widget.article, glass: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichBody(String text) {
    final blocks = widget.article.contentBlocks;
    final rng = Random(widget.article.id.hashCode);
    final maxAds = 1 + rng.nextInt(2); // 1 ili 2
    int textSinceAd = 0;
    int adsShown = 0;
    int nextAdAfter = 2 + rng.nextInt(3); // 2, 3 ili 4

    final widgets = <Widget>[];

    void appendAdIfDue({required bool hasMore}) {
      if (!hasMore) return;
      if (adsShown >= maxAds) return;
      if (textSinceAd < nextAdAfter) return;
      widgets.add(const SizedBox(height: 24));
      widgets.add(_AdBanner(imageUrl: _kAdImages[rng.nextInt(_kAdImages.length)]));
      adsShown++;
      textSinceAd = 0;
      nextAdAfter = 2 + rng.nextInt(3);
    }

    if (blocks.isEmpty) {
      final paragraphs = text.split('\n\n');
      for (int i = 0; i < paragraphs.length; i++) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 20));
        widgets.add(_buildParagraph(paragraphs[i], isLead: i == 0));
        textSinceAd++;
        appendAdIfDue(hasMore: i < paragraphs.length - 1);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
    }

    bool firstText = true;
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 20));
      switch (block) {
        case TextBlock(:final text):
          widgets.add(_buildParagraph(text, isLead: firstText));
          firstText = false;
          textSinceAd++;
          appendAdIfDue(hasMore: i < blocks.length - 1);
        case YouTubeBlock(:final videoId):
          widgets.add(_YouTubeCard(videoId: videoId));
          firstText = false;
        case InstagramBlock(:final postUrl):
          widgets.add(_InstagramCard(postUrl: postUrl));
          firstText = false;
        case ImageBlock(:final imageUrl, :final caption):
          widgets.add(_ArticleImage(imageUrl: imageUrl, caption: caption));
          firstText = false;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildParagraph(String para, {bool isLead = false}) {
    if (isLead) {
      return Text(
        para,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.7,
        ),
      );
    }
    return Text(
      para,
      style: TextStyle(
        color: context.textBody,
        fontSize: 16,
        height: 1.75,
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ShareSheet(article: widget.article),
    );
  }
}

// ── Bookmark button ────────────────────────────────────────────────────────────

class _BookmarkButton extends StatefulWidget {
  final Article article;
  final bool glass;
  const _BookmarkButton({required this.article, required this.glass});

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  @override
  void initState() {
    super.initState();
    SavedArticlesService.instance.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    SavedArticlesService.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = SavedArticlesService.instance.isSaved(widget.article.id);
    return GestureDetector(
      onTap: () => SavedArticlesService.instance.toggle(widget.article),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: widget.glass
              ? Colors.black.withValues(alpha: 0.35)
              : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSaved
                ? kOrange.withValues(alpha: 0.6)
                : widget.glass
                    ? Colors.white.withValues(alpha: 0.18)
                    : context.border,
            width: widget.glass ? 0.8 : 1,
          ),
        ),
        child: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
          color: isSaved ? kOrange : (widget.glass ? Colors.white : context.textPrimary),
          size: 20,
        ),
      ),
    );
  }
}

// ── Share sheet ────────────────────────────────────────────────────────────────

class _ShareSheet extends StatelessWidget {
  final Article article;
  const _ShareSheet({required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: context.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56, height: 56,
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: context.surfaceLight),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  article.title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SheetOption(
            icon: Icons.bookmark_outline_rounded,
            label: SavedArticlesService.instance.isSaved(article.id)
                ? 'Ukloni iz sačuvanih'
                : 'Sačuvaj vijest',
            onTap: () {
              SavedArticlesService.instance.toggle(article);
              Navigator.pop(context);
            },
          ),
          _SheetOption(
            icon: Icons.copy_rounded,
            label: 'Kopiraj naslov',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Naslov kopiran'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _SheetOption(
            icon: Icons.share_rounded,
            label: 'Podijeli',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: kOrange, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(color: context.textPrimary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Article bottom nav ─────────────────────────────────────────────────────────

class _ArticleBottomNav extends StatelessWidget {
  final VoidCallback onBack;
  const _ArticleBottomNav({required this.onBack});

  void _goToSaved(BuildContext context) {
    homeTabIndex.value = 2;
    Navigator.of(context).popUntil(ModalRoute.withName('/home'));
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.home_rounded, label: 'Početna', idx: 0),
      (icon: Icons.grid_view_rounded, label: 'Kategorije', idx: 1),
      (icon: Icons.bookmark_outline_rounded, label: 'Sačuvano', idx: 2),
      (icon: Icons.person_outline_rounded, label: 'Profil', idx: 3),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        border: Border.all(color: context.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            children: items.map((item) {
              final isHome = item.idx == 0;
              return Expanded(
                child: InkWell(
                  onTap: item.idx == 2 ? () => _goToSaved(context) : onBack,
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon,
                          size: 23,
                          color: isHome ? kOrange : context.textMuted),
                      const SizedBox(height: 3),
                      Text(item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isHome ? kOrange : context.textMuted,
                            fontWeight: isHome
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Comment card ───────────────────────────────────────────────────────────────

const _kAvatarColors = [
  Color(0xFF6B8CFF), Color(0xFF8B5CF6), Color(0xFF10B981),
  Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF3B82F6),
  Color(0xFF14B8A6), Color(0xFFEC4899),
];

Color _avatarColor(String name) {
  if (name.isEmpty) return const Color(0xFF888888);
  final idx = name.codeUnits.fold(0, (a, b) => a + b) % _kAvatarColors.length;
  return _kAvatarColors[idx];
}

class _KomentarItem extends StatelessWidget {
  final String osoba;
  final String tekst;
  const _KomentarItem({required this.osoba, required this.tekst});

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(osoba);
    final initial = osoba.isNotEmpty ? osoba.trim()[0].toUpperCase() : '?';
    final displayName = osoba.isEmpty || osoba == 'TODO' ? 'Korisnik' : osoba;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'nedavno',
                      style:
                          TextStyle(color: context.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tekst,
                  style: TextStyle(
                      color: context.textBody, fontSize: 14, height: 1.6),
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
      color: context.divider,
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
                  MaterialPageRoute(builder: (_) => ArtikalScreen(article: a)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                        child: SizedBox(
                          width: 100, height: 88,
                          child: Image.network(
                            a.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: context.surfaceLight),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CategoryBadge(label: a.category),
                              const SizedBox(height: 6),
                              Text(
                                a.title,
                                style: TextStyle(
                                  color: context.textPrimary,
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
                                  Text(a.date,
                                      style: TextStyle(
                                          color: context.textMuted,
                                          fontSize: 10)),
                                  const Spacer(),
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      color: context.textMuted, size: 11),
                                  const SizedBox(width: 3),
                                  Text('${a.comments.length}',
                                      style: TextStyle(
                                          color: context.textMuted,
                                          fontSize: 10)),
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

// ── Ad banner ──────────────────────────────────────────────────────────────────

class _AdBanner extends StatelessWidget {
  final String imageUrl;
  const _AdBanner({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.border),
          ),
          child: Text(
            'REKLAMA',
            style: TextStyle(
              color: context.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// ── Inline article image ───────────────────────────────────────────────────────

class _ArticleImage extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  const _ArticleImage({required this.imageUrl, this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 8),
          Text(
            caption!,
            style: TextStyle(
              color: context.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ── YouTube card ───────────────────────────────────────────────────────────────

class _YouTubeCard extends StatelessWidget {
  final String videoId;
  const _YouTubeCard({required this.videoId});

  @override
  Widget build(BuildContext context) {
    final thumbUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    final watchUrl = 'https://www.youtube.com/watch?v=$videoId';
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(watchUrl), mode: LaunchMode.externalApplication),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: context.surface,
                  child: Icon(Icons.play_circle_outline_rounded,
                      color: context.textMuted, size: 48),
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instagram card ─────────────────────────────────────────────────────────────

class _InstagramCard extends StatelessWidget {
  final String postUrl;
  const _InstagramCard({required this.postUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(postUrl), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.border),
          color: context.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF58529),
                    Color(0xFFDD2A7B),
                    Color(0xFF8134AF),
                    Color(0xFF515BD4),
                  ],
                ),
              ),
              child: const Icon(Icons.photo_camera_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instagram objava',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pogledaj na Instagramu',
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: context.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Category badge ─────────────────────────────────────────────────────────────

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
