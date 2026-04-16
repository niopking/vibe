import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
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

  // ── Učitaj sačuvane artikle (IDs iz Firestorea, sadržaj iz WordPress API) ──

  Future<void> loadFromFirebase() async {
    _loaded = false;
    _saved.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) {
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
        final include = savedIds.join(',');
        final uri = Uri.parse(
          'https://vibeadria.com/wp-json/wp/v2/posts?include=$include&_embed&per_page=100',
        );
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final List<dynamic> posts = jsonDecode(response.body);
          final articles = posts
              .map((p) => wpPostToArticle(p as Map<String, dynamic>))
              .toList();

          // Sačuvaj redosljed (najnovije prvo = reversed savedIds)
          for (final id in savedIds.reversed) {
            final matches = articles.where((a) => a.id == id);
            if (matches.isNotEmpty) _saved.add(matches.first);
          }
        }
      }
    } catch (_) {
      // Nastavi sa praznom listom
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

    // Sync IDs u Firestore (preskoci za goste)
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
}
