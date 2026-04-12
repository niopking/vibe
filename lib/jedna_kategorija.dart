import 'package:flutter/material.dart';
import 'models.dart';
import 'artikal.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kGreyLight = Color(0xFF3A3A3A);
const kTextMuted = Color(0xFF888888);

class CategoryNewsScreen extends StatefulWidget {
  final String category;
  const CategoryNewsScreen({super.key, required this.category});

  @override
  State<CategoryNewsScreen> createState() => _CategoryNewsScreenState();
}

class _CategoryNewsScreenState extends State<CategoryNewsScreen> {
  late Future<List<Article>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchArticles().then(
      (all) => all
          .where((a) =>
              a.category.toLowerCase() == widget.category.toLowerCase())
          .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: FutureBuilder<List<Article>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: kOrange));
            }
            final articles = snapshot.data ?? [];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _CategoryHeader(
                    category: widget.category,
                    count: articles.length,
                  ),
                ),
                if (articles.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  ..._buildContentSlivers(articles),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers(List<Article> articles) {
    final slivers = <Widget>[];

    // 1. HERO — biggest article
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: _HeroCard(article: articles.first),
        ),
      ),
    );

    // 2. Section label: "U FOKUSU" above the duo grid (if we have 2+ more)
    final duo = articles.skip(1).take(2).toList();
    if (duo.length == 2) {
      slivers.add(
        SliverToBoxAdapter(
          child: _SectionLabel(text: 'U FOKUSU'),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Expanded(child: _DuoCard(article: duo[0])),
                const SizedBox(width: 12),
                Expanded(child: _DuoCard(article: duo[1])),
              ],
            ),
          ),
        ),
      );
    } else if (duo.length == 1) {
      slivers.add(
        SliverToBoxAdapter(
          child: _SectionLabel(text: 'U FOKUSU'),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Expanded(child: _DuoCard(article: duo[0])),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Remaining — alternating compact list rows (image left/right)
    final rest = articles.skip(1 + duo.length).toList();
    if (rest.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: _SectionLabel(text: 'OSTALE VIJESTI'),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          sliver: SliverList.separated(
            itemCount: rest.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ListRowCard(
              article: rest[i],
              imageOnLeft: i.isEven,
            ),
          ),
        ),
      );
    }

    return slivers;
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final String category;
  final int count;
  const _CategoryHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white),
          ),
          Container(
            width: 4,
            height: 22,
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: kOrange.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              '$count vijesti',
              style: const TextStyle(
                color: kOrange,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: kOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 0.6,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero card ──────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Article article;
  const _HeroCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArtikalScreen(article: article)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 11,
              child: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: kGreyLight),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.25, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'NAJNOVIJE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        article.date,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${article.comments.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
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

// ── Duo card (2 side-by-side under hero) ──────────────────────────────────────

class _DuoCard extends StatelessWidget {
  final Article article;
  const _DuoCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArtikalScreen(article: article)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kGrey,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: kGreyLight),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        article.date,
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 10),
                      ),
                      const Spacer(),
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: kTextMuted, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        '${article.comments.length}',
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 10),
                      ),
                    ],
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

// ── Wide card (fallback when only 1 article under hero) ──────────────────────

// ── List row card (alternates image left/right) ──────────────────────────────

class _ListRowCard extends StatelessWidget {
  final Article article;
  final bool imageOnLeft;
  const _ListRowCard({required this.article, required this.imageOnLeft});

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(imageOnLeft ? 16 : 0),
        bottomLeft: Radius.circular(imageOnLeft ? 16 : 0),
        topRight: Radius.circular(imageOnLeft ? 0 : 16),
        bottomRight: Radius.circular(imageOnLeft ? 0 : 16),
      ),
      child: SizedBox(
        width: 118,
        height: 108,
        child: Image.network(
          article.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: kGreyLight),
        ),
      ),
    );

    final text = Expanded(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          imageOnLeft ? 12 : 14,
          12,
          imageOnLeft ? 14 : 12,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              article.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: kTextMuted, size: 11),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    article.date,
                    style: const TextStyle(
                        color: kTextMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: kTextMuted, size: 11),
                const SizedBox(width: 3),
                Text(
                  '${article.comments.length}',
                  style: const TextStyle(
                      color: kTextMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArtikalScreen(article: article)),
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
          children: imageOnLeft ? [image, text] : [text, image],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.article_outlined,
              color: kTextMuted, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Nema vijesti u ovoj kategoriji',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
