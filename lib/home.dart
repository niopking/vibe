import 'package:flutter/material.dart';
import 'categories.dart';
import 'settings.dart';
import 'profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'artikal.dart';
import 'jedna_kategorija.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kGreyLight = Color(0xFF3A3A3A);
const kTextMuted = Color(0xFF888888);

// Category mapping
const Map<int, String> categoryMap = {
  1: 'Tech',
  2: 'Lifestyle',
  3: 'Auto',
  4: 'Travel',
};

// ── Data model ─────────────────────────────────────────────────────────────────

class Article {
  final String id;
  final String title;
  final String category;
  final String date;
  final String imageUrl;
  final List<Map<String, dynamic>> comments;
  final String tekst;
  final int timestamp;
  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.imageUrl,
    this.comments = const [],
    this.tekst = '',
    required this.timestamp,
  });
}

// Function to format date
String formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final months = [
    'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Jun',
    'Jul', 'Avgust', 'Septembar', 'Oktobar', 'Novembar', 'Decembar'
  ];
  return '${date.day}. ${months[date.month - 1]} ${date.year}.';
}

// Function to fetch articles from Firestore
Future<List<Article>> fetchArticles() async {
  final snapshot = await FirebaseFirestore.instance.collection('vjesti').get();
  return snapshot.docs.map((doc) {
    final data = doc.data();
    final datum = data['datum'] as int;
    final kategorija = data['kategorija'] as int;
    final naslov = data['naslov'] as String;
    final slika = data['slika'] as String;
    final tekst = data['tekst'] as String? ?? '';
    final rawKomentari = data['komentari'];
    final komentari = rawKomentari is List
        ? rawKomentari.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return Article(
      id: doc.id,
      title: naslov,
      category: categoryMap[kategorija] ?? 'Unknown',
      date: formatDate(datum),
      imageUrl: slika,
      comments: komentari,
      tekst: tekst,
      timestamp: datum,
    );
  }).toList();
}

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
    SettingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
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
              final selected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon,
                          size: 23,
                          color: selected ? kOrange : kTextMuted),
                      const SizedBox(height: 3),
                      Text(items[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected ? kOrange : kTextMuted,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
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

// ── Home page ──────────────────────────────────────────────────────────────────

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late Future<List<Article>> _articlesFuture;

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
                style: const TextStyle(color: Colors.white)),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Nema vijesti', style: TextStyle(color: Colors.white)),
          );
        }

        final articles = List<Article>.from(snapshot.data!)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Group by category (preserve insertion order = recency order)
        final Map<String, List<Article>> byCategory = {};
        for (final a in articles) {
          byCategory.putIfAbsent(a.category, () => []).add(a);
        }

        // Latest = top 5 most recent
        final latest = articles.take(5).toList();

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _TopBar(),
              Container(
                height: 0.6,
                margin: EdgeInsets.zero,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              Expanded(
                child: ListView(
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
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          );
                        }
                      }
                      return widgets;
                    }(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Image.asset(
            'images/logobeztr.png',
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: kGrey,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: kTextMuted, size: 18),
                    SizedBox(width: 8),
                    Text('Pretraži vijesti...',
                        style: TextStyle(color: kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kGrey,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white70, size: 22),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: kDark, width: 1.2),
                  ),
                ),
              ),
            ],
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
                const Text(
                  'NAJNOVIJE',
                  style: TextStyle(
                    color: Colors.white,
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
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 11,
                  ),
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
                errorBuilder: (_, __, ___) => Container(color: kGrey),
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
                  style: const TextStyle(
                    color: Colors.white,
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
              errorBuilder: (_, __, ___) => Container(color: kGrey)),
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
          color: kGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
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
                  errorBuilder: (_, __, ___) => Container(color: kGreyLight),
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
                      style: const TextStyle(
                        color: Colors.white,
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
                    style: const TextStyle(
                      color: kTextMuted,
                      fontSize: 10,
                    ),
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
      backgroundColor: kDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: kGrey,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: kTextMuted, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Pretraži vijesti...',
                                hintStyle:
                                    TextStyle(color: kTextMuted, fontSize: 13),
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
                              child: const Icon(Icons.close_rounded,
                                  color: kTextMuted, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 0.6,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            Expanded(
              child: FutureBuilder<List<Article>>(
                future: _articlesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: kOrange));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Nema vijesti',
                          style: TextStyle(color: kTextMuted)),
                    );
                  }

                  final all = snapshot.data!;

                  if (_query.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded,
                              color: kTextMuted, size: 48),
                          SizedBox(height: 12),
                          Text('Ukucaj pojam za pretragu',
                              style: TextStyle(
                                  color: kTextMuted, fontSize: 14)),
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
                          const Icon(Icons.search_off_rounded,
                              color: kTextMuted, size: 48),
                          const SizedBox(height: 12),
                          Text('Nema rezultata za "$_query"',
                              style: const TextStyle(
                                  color: kTextMuted, fontSize: 14)),
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
                            color: kGrey,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
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
                                        Container(color: kGreyLight),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _CategoryBadge(label: a.category),
                                      const SizedBox(height: 6),
                                      Text(
                                        a.title,
                                        style: const TextStyle(
                                          color: Colors.white,
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
                                        style: const TextStyle(
                                          color: kTextMuted,
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

