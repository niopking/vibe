import 'package:cloud_firestore/cloud_firestore.dart';

const Map<int, String> categoryMap = {
  1: 'Tech',
  2: 'Lifestyle',
  3: 'Auto',
  4: 'Travel',
};

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

String formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final months = [
    'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Jun',
    'Jul', 'Avgust', 'Septembar', 'Oktobar', 'Novembar', 'Decembar'
  ];
  return '${date.day}. ${months[date.month - 1]} ${date.year}.';
}

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
