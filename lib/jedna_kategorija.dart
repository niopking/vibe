import 'package:flutter/material.dart';
import 'home.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
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
                    widget.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
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
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: kOrange));
                  }
                  final articles = snapshot.data ?? [];
                  if (articles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.article_outlined,
                              color: kTextMuted, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Nema vijesti u kategoriji\n${widget.category}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: kTextMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: articles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) =>
                        _FullWidthCard(article: articles[i]),
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

class _FullWidthCard extends StatelessWidget {
  final Article article;
  const _FullWidthCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArtikalScreen(article: article)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Full-width image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: kGreyLight),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),
            // Category badge top-right
            Positioned(
              top: 12,
              right: 12,
              child: _CategoryBadge(label: article.category),
            ),
            // Title + meta bottom
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        article.date,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                      const Spacer(),
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${article.comments.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
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