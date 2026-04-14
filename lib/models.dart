import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Globalni cache — isti Future dijele loading screen i home ─────────────────
Future<List<Article>>? _articlesFuture;

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

// ── HTML → čisti tekst u paragrafima odvojenim sa \n\n ────────────────────────
String _htmlToText(String html) {
  // Svaki blok-element → novi red
  var text = html
      .replaceAll(RegExp(r'<br\s*/?>',        caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>',              caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h[1-6]>',        caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</li>',            caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</blockquote>',    caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</div>',           caseSensitive: false), '\n');

  // Ukloni sve preostale HTML tagove
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode HTML entiteta
  text = text
      .replaceAll('&amp;',  '&')
      .replaceAll('&lt;',   '<')
      .replaceAll('&gt;',   '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#8211;', '–')
      .replaceAll('&#8212;', '—')
      .replaceAll('&#8216;', '\u2018')
      .replaceAll('&#8217;', '\u2019')
      .replaceAll('&#8220;', '\u201C')
      .replaceAll('&#8221;', '\u201D')
      .replaceAll('&nbsp;',  ' ');

  // Splituj po novim redovima, trimuj, filtriraj prazne
  final paragraphs = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  return paragraphs.join('\n\n');
}

String _stripHtml(String html) => _htmlToText(html);

String formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final months = [
    'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Jun',
    'Jul', 'Avgust', 'Septembar', 'Oktobar', 'Novembar', 'Decembar'
  ];
  return '${date.day}. ${months[date.month - 1]} ${date.year}.';
}

Article wpPostToArticle(Map<String, dynamic> post) {
  final id = post['id'].toString();
  final title = _stripHtml(post['title']['rendered'] as String? ?? '');

  // Kategorija iz embedded terms
  String category = 'Vijesti';
  final embedded = post['_embedded'] as Map<String, dynamic>?;
  if (embedded != null) {
    final terms = embedded['wp:term'] as List?;
    if (terms != null && terms.isNotEmpty) {
      final cats = terms[0] as List?;
      if (cats != null && cats.isNotEmpty) {
        category =
            (cats[0] as Map<String, dynamic>)['name'] as String? ?? 'Vijesti';
      }
    }
  }

  // Naslovna slika
  String imageUrl = '';
  if (embedded != null) {
    final media = embedded['wp:featuredmedia'] as List?;
    if (media != null && media.isNotEmpty) {
      imageUrl =
          (media[0] as Map<String, dynamic>)['source_url'] as String? ?? '';
    }
  }

  // Datum
  final dateStr = post['date'] as String? ?? DateTime.now().toIso8601String();
  final dateTime = DateTime.parse(dateStr);
  final timestamp = dateTime.millisecondsSinceEpoch ~/ 1000;

  // Sadržaj: HTML → čisti paragrafi
  final rawHtml = post['content']['rendered'] as String? ?? '';
  final tekst = _htmlToText(rawHtml);

  return Article(
    id: id,
    title: title,
    category: category,
    date: formatDate(timestamp),
    imageUrl: imageUrl,
    tekst: tekst,
    timestamp: timestamp,
  );
}

Future<List<Article>> fetchArticles() {
  _articlesFuture ??= _doFetch();
  return _articlesFuture!;
}

Future<List<Article>> _doFetch() async {
  final uri = Uri.parse(
    'https://vibeadria.com/wp-json/wp/v2/posts?_embed&per_page=100',
  );
  try {
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];
    final List<dynamic> posts = jsonDecode(response.body);
    return posts
        .map((post) => wpPostToArticle(post as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}
