import 'package:flutter/material.dart';
import 'home.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kTextMuted = Color(0xFF888888);

class ArtikalScreen extends StatelessWidget {
  final Article article;
  const ArtikalScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: kDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
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
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(label: article.category),
                      const SizedBox(width: 10),
                      Text(
                        article.date,
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 12),
                      ),
                      const Spacer(),
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: kTextMuted, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${article.comments.length}',
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (article.tekst.isNotEmpty)
                    Text(
                      article.tekst,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.65,
                      ),
                    ),
                  if (article.comments.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Komentari',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...article.comments.map((k) => _KomentarItem(tekst: k)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KomentarItem extends StatelessWidget {
  final String tekst;
  const _KomentarItem({required this.tekst});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tekst,
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: kOrange, borderRadius: BorderRadius.circular(5)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}
