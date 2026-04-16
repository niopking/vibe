import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'categories.dart';
import 'game.dart';
import 'profile.dart';
import 'artikal.dart';
import 'jedna_kategorija.dart';
import 'models.dart';
import 'saved_service.dart';

// ── Main screen shell ──────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _HomePage(),
    CategoriesScreen(),
    GameScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    homeTabIndex.addListener(_onTabChange);
    SavedArticlesService.instance.loadFromFirebase();
  }

  void _onTabChange() => setState(() => _selectedIndex = homeTabIndex.value);

  @override
  void dispose() {
    homeTabIndex.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) {
          homeTabIndex.value = i;
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Početna'),
      _NavItem(icon: Icons.grid_view_rounded, label: 'Kategorije'),
      _NavItem(icon: Icons.sports_esports_outlined, selectedIcon: Icons.sports_esports_rounded, label: 'Igre'),
      _NavItem(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profil'),
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
            color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.10),
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
              final selected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(20),
                  child: Icon(
                      selected && items[i].selectedIcon != null
                          ? items[i].selectedIcon!
                          : items[i].icon,
                      size: 30,
                      color: selected ? kOrange : context.textMuted),
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
  final IconData? selectedIcon;
  final String label;
  const _NavItem({required this.icon, this.selectedIcon, required this.label});
}

// ── Home page ──────────────────────────────────────────────────────────────────

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late Future<List<Article>> _articlesFuture;
  bool _searchOpen = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _articlesFuture = fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _articlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kOrange));
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: TextStyle(color: context.textPrimary)),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Nema vijesti', style: TextStyle(color: context.textMuted)),
          );
        }

        final allArticles = List<Article>.from(snapshot.data!)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ValueListenableBuilder<Set<String>>(
          valueListenable: disabledCategoriesNotifier,
          builder: (context, disabled, _) {
            final articles = allArticles
                .where((a) => !disabled.contains(a.category))
                .toList();

            final Map<String, List<Article>> byCategory = {};
            for (final a in articles) {
              byCategory.putIfAbsent(a.category, () => []).add(a);
            }

            final latest = articles.take(5).toList();

            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    onOpen: () => setState(() { _searchOpen = true; _searchQuery = ''; }),
                    onClose: () => setState(() { _searchOpen = false; _searchQuery = ''; }),
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                  Container(
                    height: 0.6,
                    margin: const EdgeInsets.only(top: 7),
                    color: context.divider,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.only(bottom: 110),
                          children: [
                            const SizedBox(height: 18),
                            _LatestSection(articles: latest),
                            const SizedBox(height: 26),
                            ...() {
                              final entries = byCategory.entries.toList();
                              final widgets = <Widget>[];
                              for (int i = 0; i < entries.length; i++) {
                                widgets.add(
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: _CategorySection(
                                      category: entries[i].key,
                                      articles: entries[i].value,
                                    ),
                                  ),
                                );
                                if (i < entries.length - 1) {
                                  widgets.add(
                                    Container(
                                      height: 0.6,
                                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                      color: context.divider,
                                    ),
                                  );
                                }
                              }
                              return widgets;
                            }(),
                          ],
                        ),
                        AnimatedSlide(
                          offset: _searchOpen ? Offset.zero : const Offset(0, 1),
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: _searchOpen ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: _SearchPanel(
                              query: _searchQuery,
                              articles: allArticles,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Search panel ──────────────────────────────────────────────────────────────

class _SearchPanel extends StatelessWidget {
  final String query;
  final List<Article> articles;
  const _SearchPanel({required this.query, required this.articles});

  @override
  Widget build(BuildContext context) {
    final results = query.isEmpty
        ? <Article>[]
        : articles
            .where((a) =>
                a.title.toLowerCase().contains(query.toLowerCase()) ||
                a.category.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return Container(
      color: context.bg,
      child: results.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, color: context.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    query.isEmpty
                        ? 'Počni kucati za pretragu...'
                        : 'Nema rezultata za "$query"',
                    style: TextStyle(color: context.textMuted, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = results[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ArtikalScreen(article: a)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: SizedBox(
                            width: 100,
                            height: 88,
                            child: Image.network(a.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: context.surfaceLight)),
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
                                Text(a.title,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(a.date,
                                    style: TextStyle(
                                        color: context.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;
  const _TopBar({
    required this.onOpen,
    required this.onClose,
    required this.onChanged,
  });

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _expanded = false;
  final _controller = TextEditingController();
  final _focus = FocusNode();

  void _open() {
    setState(() => _expanded = true);
    widget.onOpen();
    Future.delayed(const Duration(milliseconds: 180),
        () { if (mounted) _focus.requestFocus(); });
  }

  void _close() {
    setState(() => _expanded = false);
    _controller.clear();
    _focus.unfocus();
    widget.onChanged('');
    widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            width: _expanded ? 0 : 78,
            child: ClipRect(
              child: AnimatedOpacity(
                opacity: _expanded ? 0 : 1,
                duration: const Duration(milliseconds: 160),
                child: Image.asset('images/logobeztr.png',
                    height: 30, fit: BoxFit.contain),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            width: _expanded ? 0 : 12,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _expanded ? null : _open,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                height: 40,
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: context.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _expanded
                          ? TextField(
                              controller: _controller,
                              focusNode: _focus,
                              cursorColor: kOrange,
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              onChanged: widget.onChanged,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: true,
                                fillColor: Colors.transparent,
                                hintText: 'Pretraži vijesti...',
                                hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          : Text('Pretraži vijesti...',
                              style: TextStyle(color: context.textMuted, fontSize: 13)),
                    ),
                    if (_expanded)
                      GestureDetector(
                        onTap: _close,
                        child: Icon(Icons.close_rounded, color: context.textMuted, size: 18),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Latest (najnovije) section ─────────────────────────────────────────────────

class _LatestSection extends StatelessWidget {
  final List<Article> articles;
  const _LatestSection({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kOrange.withValues(alpha: 0.16),
            kOrange.withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: kOrange.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: kOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'NAJNOVIJE',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.bolt_rounded, color: kOrange, size: 18),
                const Spacer(),
                Text(
                  '${articles.length} vijesti',
                  style: TextStyle(color: context.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: articles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _LatestCard(article: articles[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  final Article article;
  const _LatestCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtikalScreen(article: article),
        ),
      ),
      child: SizedBox(
        width: 230,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: context.surfaceLight),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _CategoryBadge(label: article.category),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.date,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category section ───────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final String category;
  final List<Article> articles;
  const _CategorySection({required this.category, required this.articles});

  @override
  Widget build(BuildContext context) {
    final featured = articles.first;
    final related = articles.skip(1).take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryNewsScreen(category: category),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: kOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Vidi sve',
                  style: TextStyle(
                    color: kOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: kOrange, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtikalScreen(article: featured),
              ),
            ),
            child: SizedBox(
              height: 230,
              child: _FeaturedCard(article: featured),
            ),
          ),
        ),
        if (related.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (int i = 0; i < related.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _SmallCard(article: related[i])),
                ],
                if (related.length == 1) ...[
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Featured card ──────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final Article article;
  const _FeaturedCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(article.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: context.surfaceLight)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.88),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(article.date,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const Spacer(),
                    const Icon(Icons.chat_bubble_outline_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text('${article.comments.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small card (2 below featured) ──────────────────────────────────────────────

class _SmallCard extends StatelessWidget {
  final Article article;
  const _SmallCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtikalScreen(article: article),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: context.surfaceLight),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 34,
                    child: Text(
                      article.title,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.date,
                    style: TextStyle(color: context.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: kOrange,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: kOrange.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Search screen ──────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  late Future<List<Article>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = fetchArticles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: context.textMuted, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              cursorColor: kOrange,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Pretraži vijesti...',
                                hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                              child: Icon(Icons.close_rounded, color: context.textMuted, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 0.6, color: context.divider),
            Expanded(
              child: FutureBuilder<List<Article>>(
                future: _articlesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: kOrange));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text('Nema vijesti',
                          style: TextStyle(color: context.textMuted)),
                    );
                  }

                  final all = snapshot.data!;

                  if (_query.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded, color: context.textMuted, size: 48),
                          const SizedBox(height: 12),
                          Text('Ukucaj pojam za pretragu',
                              style: TextStyle(color: context.textMuted, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  final q = _query.toLowerCase();
                  final filtered = all
                      .where((a) =>
                          a.title.toLowerCase().contains(q) ||
                          a.category.toLowerCase().contains(q))
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, color: context.textMuted, size: 48),
                          const SizedBox(height: 12),
                          Text('Nema rezultata za "$_query"',
                              style: TextStyle(color: context.textMuted, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final a = filtered[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ArtikalScreen(article: a)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.border),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: SizedBox(
                                  width: 110,
                                  height: 100,
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
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        a.date,
                                        style: TextStyle(
                                          color: context.textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
