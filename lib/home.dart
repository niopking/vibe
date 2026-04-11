import 'package:flutter/material.dart';
import 'categories.dart';
import 'settings.dart';
import 'profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'artikal.dart';

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
  final String title;
  final String category;
  final String date;
  final String imageUrl;
  final List<String> comments;
  final String tekst;
  final int timestamp;
  const Article({
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
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000); // assuming seconds
  final months = [
    'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Jun',
    'Jul', 'Avgust', 'Septembar', 'Oktobar', 'Novembar', 'Decembar'
  ];
  return '${date.day}. ${months[date.month - 1]} ${date.year}.';
}

// Function to fetch articles from Firestore
Future<List<Article>> fetchArticles() async {
  final snapshot = await FirebaseFirestore.instance.collection('vijesti').get();
  return snapshot.docs.map((doc) {
    final data = doc.data();
    final datum = data['datum'] as int;
    final kategorija = data['kategorija'] as int;
    final naslov = data['naslov'] as String;
    final slika = data['slika'] as String;
    final tekst = data['tekst'] as String? ?? '';
    final rawKomentari = data['komentari'];
    final komentari = rawKomentari is List
        ? rawKomentari.cast<String>()
        : <String>[];
    return Article(
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
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon, size: 22,
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No articles found'));
        } else {
          final articles = snapshot.data!;
          // Sort by timestamp descending
          articles.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final featuredArticles = articles.take(5).toList();
          final latestArticles = articles.skip(5).toList();
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      const SizedBox(height: 8),
                      ...featuredArticles.map((a) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtikalScreen(article: a),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: SizedBox(
                            height: 260,
                            child: _FeaturedCard(article: a),
                          ),
                        ),
                      )),
                      const SizedBox(height: 14),
                      _SectionHeader(title: 'Najnovije', onMore: () {}),
                      const SizedBox(height: 8),
                      ...latestArticles.map((a) => _LatestArticleCard(article: a)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('V',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 6),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              children: [
                TextSpan(text: 'vibe', style: TextStyle(color: kOrange)),
                TextSpan(text: 'news', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: kGrey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: const [
                    Icon(Icons.search_rounded, color: kTextMuted, size: 18),
                    SizedBox(width: 8),
                    Text('Pretraži vijesti...',
                        style: TextStyle(color: kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  color: Colors.white70, size: 26),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: kOrange, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(16),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _CategoryBadge(label: article.category),
                      const SizedBox(width: 10),
                      Text(article.date,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                      const Spacer(),
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white60, size: 13),
                      const SizedBox(width: 4),
                      Text('${article.comments.length}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
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

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onMore;
  const _SectionHeader({required this.title, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: kOrange, size: 20),
          const Spacer(),
          GestureDetector(
            onTap: onMore,
            child: const Text('Sve vijesti',
                style: TextStyle(color: kOrange, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Latest article card ────────────────────────────────────────────────────────

class _LatestArticleCard extends StatelessWidget {
  final Article article;
  const _LatestArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtikalScreen(article: article),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
              color: kGrey, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 100,
                  height: 90,
                  child: Image.network(article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: kGreyLight)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryBadge(label: article.category),
                      const SizedBox(height: 6),
                      Text(article.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(article.date,
                              style: const TextStyle(
                                  color: kTextMuted, fontSize: 10)),
                          const Spacer(),
                          const Icon(Icons.chat_bubble_outline_rounded,
                              color: kTextMuted, size: 11),
                          const SizedBox(width: 3),
                          Text('${article.comments.length}',
                              style: const TextStyle(
                                  color: kTextMuted, fontSize: 10)),
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
  }
}

// ── Category badge ─────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}