import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Globalni cache — isti Future dijele loading screen i home ─────────────────
Future<List<Article>>? _articlesFuture;

// ── Content block types ───────────────────────────────────────────────────────
sealed class ContentBlock {}

class TextBlock extends ContentBlock {
  final String text;
  TextBlock(this.text);
}

class YouTubeBlock extends ContentBlock {
  final String videoId;
  YouTubeBlock(this.videoId);
}

class InstagramBlock extends ContentBlock {
  final String postUrl;
  InstagramBlock(this.postUrl);
}

class ImageBlock extends ContentBlock {
  final String imageUrl;
  final String? caption;
  ImageBlock(this.imageUrl, {this.caption});
}

class Article {
  final String id;
  final String title;
  final String category;
  final String date;
  final String imageUrl;
  final List<Map<String, dynamic>> comments;
  final String tekst;
  final int timestamp;
  final List<ContentBlock> contentBlocks;
  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.imageUrl,
    this.comments = const [],
    this.tekst = '',
    required this.timestamp,
    this.contentBlocks = const [],
  });
}

// ── HTML → lista ContentBlock-ova (tekst + YouTube + Instagram) ───────────────
List<ContentBlock> _parseHtmlContent(String html) {
  final blocks = <ContentBlock>[];

  // YouTube iframe: <iframe src="...youtube.com/embed/ID...">
  final ytIframeRe = RegExp(
    r'<iframe[^>]+src="[^"]*youtube\.com/embed/([A-Za-z0-9_\-]+)[^"]*"[^>]*>(?:.*?</iframe>)?',
    caseSensitive: false,
    dotAll: true,
  );

  // WordPress YouTube figure (no iframe, just URL in wrapper)
  final ytFigureRe = RegExp(
    r'<figure[^>]*class="[^"]*is-provider-youtube[^"]*"[^>]*>.*?</figure>',
    caseSensitive: false,
    dotAll: true,
  );

  // Instagram blockquote with instagram-media class
  final igBlockquoteRe = RegExp(
    r'<blockquote[^>]*class="[^"]*instagram-media[^"]*"[^>]*>.*?</blockquote>',
    caseSensitive: false,
    dotAll: true,
  );

  // WordPress Instagram figure
  final igFigureRe = RegExp(
    r'<figure[^>]*class="[^"]*is-provider-instagram[^"]*"[^>]*>.*?</figure>',
    caseSensitive: false,
    dotAll: true,
  );

  // WordPress image block: <figure class="wp-block-image..."><img src="..."/></figure>
  final imgFigureRe = RegExp(
    r'<figure[^>]*class="[^"]*wp-block-image[^"]*"[^>]*>.*?</figure>',
    caseSensitive: false,
    dotAll: true,
  );

  // Standalone <img> tags (fallback for images outside figure)
  final imgTagRe = RegExp(
    r'<img\b[^>]+>',
    caseSensitive: false,
    dotAll: true,
  );

  // Helpers for extracting URLs
  final ytUrlRe = RegExp(
    r'https?://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([A-Za-z0-9_\-]+)',
  );
  final igPermalinkRe = RegExp(
    r'data-instgrm-permalink="([^"]+)"',
    caseSensitive: false,
  );
  final igUrlRe = RegExp(
    r'https?://(?:www\.)?instagram\.com/p/[A-Za-z0-9_\-]+/?',
  );
  final imgSrcRe = RegExp(
    r'\bsrc="([^"]+)"',
    caseSensitive: false,
  );
  final imgCaptionRe = RegExp(
    r'<figcaption[^>]*>(.*?)</figcaption>',
    caseSensitive: false,
    dotAll: true,
  );

  // Combined regex that matches any embed or image type
  final combinedRe = RegExp(
    '(?:${ytIframeRe.pattern})|(?:${ytFigureRe.pattern})|(?:${igBlockquoteRe.pattern})|(?:${igFigureRe.pattern})|(?:${imgFigureRe.pattern})|(?:${imgTagRe.pattern})',
    caseSensitive: false,
    dotAll: true,
  );

  final textBuf = StringBuffer();

  void flushText() {
    final raw = textBuf.toString().trim();
    textBuf.clear();
    if (raw.isEmpty) return;
    final text = _htmlToText(raw);
    for (final para in text.split('\n\n')) {
      final p = para.trim();
      if (p.isNotEmpty) blocks.add(TextBlock(p));
    }
  }

  var pos = 0;
  for (final match in combinedRe.allMatches(html)) {
    // Text before this embed
    if (match.start > pos) {
      textBuf.write(html.substring(pos, match.start));
    }
    flushText();

    final chunk = match.group(0)!;

    // Determine type by checking which sub-pattern matched
    if (ytIframeRe.hasMatch(chunk) || ytFigureRe.hasMatch(chunk)) {
      final iframeMatch = ytIframeRe.firstMatch(chunk);
      if (iframeMatch != null) {
        blocks.add(YouTubeBlock(iframeMatch.group(1)!));
      } else {
        final urlMatch = ytUrlRe.firstMatch(chunk);
        if (urlMatch != null) blocks.add(YouTubeBlock(urlMatch.group(1)!));
      }
    } else if (igBlockquoteRe.hasMatch(chunk) || igFigureRe.hasMatch(chunk)) {
      String? url;
      final permalinkMatch = igPermalinkRe.firstMatch(chunk);
      if (permalinkMatch != null) {
        url = permalinkMatch.group(1)!.split('?').first;
      } else {
        url = igUrlRe.firstMatch(chunk)?.group(0);
      }
      if (url != null) blocks.add(InstagramBlock(url));
    } else {
      // Image (wp-block-image figure or standalone img tag)
      final src = imgSrcRe.firstMatch(chunk)?.group(1);
      if (src != null && !src.startsWith('data:')) {
        final captionHtml = imgCaptionRe.firstMatch(chunk)?.group(1);
        final caption = captionHtml != null ? _htmlToText(captionHtml).trim() : null;
        blocks.add(ImageBlock(src, caption: caption?.isEmpty == true ? null : caption));
      }
    }

    pos = match.end;
  }

  // Remaining text after last embed
  if (pos < html.length) textBuf.write(html.substring(pos));
  flushText();

  // Fallback: if nothing found, treat whole thing as text
  if (blocks.isEmpty) {
    final text = _htmlToText(html);
    for (final para in text.split('\n\n')) {
      final p = para.trim();
      if (p.isNotEmpty) blocks.add(TextBlock(p));
    }
  }

  return blocks;
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

  // Sadržaj: HTML → čisti paragrafi + content blokovi (YT, IG)
  final rawHtml = post['content']['rendered'] as String? ?? '';
  final tekst = _htmlToText(rawHtml);
  final contentBlocks = _parseHtmlContent(rawHtml);

  return Article(
    id: id,
    title: title,
    category: category,
    date: formatDate(timestamp),
    imageUrl: imageUrl,
    tekst: tekst,
    timestamp: timestamp,
    contentBlocks: contentBlocks,
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
