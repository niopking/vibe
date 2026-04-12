import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

// Global notifier so article screen can switch the home tab to "Sačuvano"
final homeTabIndex = ValueNotifier<int>(0);

class SavedArticlesService extends ChangeNotifier {
  static final SavedArticlesService instance = SavedArticlesService._();
  SavedArticlesService._();

  final List<Article> _saved = [];
  bool _loaded = false;

  List<Article> get saved => List.unmodifiable(_saved);
  bool get isLoaded => _loaded;

  bool isSaved(String id) => _saved.any((a) => a.id == id);

  // ── Load saved articles from Firestore on login ────────────────────────────

  Future<void> loadFromFirebase() async {
    _loaded = false;
    _saved.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) {
      // Guest user — no Firebase sync
      _loaded = true;
      notifyListeners();
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('korisnici')
          .doc(userId)
          .get();

      final savedIds =
          List<String>.from(userDoc.data()?['sacuvano'] ?? []);

      if (savedIds.isNotEmpty) {
        // Firestore whereIn supports max 10 items per query
        final articles = <Article>[];
        for (var i = 0; i < savedIds.length; i += 10) {
          final batch = savedIds.sublist(
              i, (i + 10) > savedIds.length ? savedIds.length : i + 10);
          final snapshot = await FirebaseFirestore.instance
              .collection('vjesti')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          articles.addAll(snapshot.docs.map((doc) => _docToArticle(doc)));
        }

        // Preserve saved order (most recent first = reversed savedIds)
        for (final id in savedIds.reversed) {
          final matches = articles.where((a) => a.id == id);
          if (matches.isNotEmpty) _saved.add(matches.first);
        }
      }
    } catch (_) {
      // If Firebase fails, continue with empty list
    }

    _loaded = true;
    notifyListeners();
  }

  // ── Toggle save / unsave ───────────────────────────────────────────────────

  Future<void> toggle(Article article) async {
    final alreadySaved = isSaved(article.id);

    if (alreadySaved) {
      _saved.removeWhere((a) => a.id == article.id);
    } else {
      _saved.insert(0, article);
    }
    notifyListeners();

    // Sync to Firestore (skip for guests)
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('korisnici')
        .doc(userId)
        .update({
      'sacuvano': alreadySaved
          ? FieldValue.arrayRemove([article.id])
          : FieldValue.arrayUnion([article.id]),
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Article _docToArticle(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final datum = data['datum'] as int;
    final kategorija = data['kategorija'] as int;
    final rawKomentari = data['komentari'];
    final komentari = rawKomentari is List
        ? rawKomentari
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[];
    return Article(
      id: doc.id,
      title: data['naslov'] as String,
      category: categoryMap[kategorija] ?? 'Unknown',
      date: formatDate(datum),
      imageUrl: data['slika'] as String,
      comments: komentari,
      tekst: data['tekst'] as String? ?? '',
      timestamp: datum,
    );
  }
}
