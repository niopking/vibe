import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

const _categories = [
  {'emoji': '🎭', 'label': 'Showbizz'},
  {'emoji': '❤️‍🔥', 'label': 'Lifestyle'},
  {'emoji': '✈️', 'label': 'Travel'},
  {'emoji': '💻', 'label': 'Tech'},
  {'emoji': '🍽️', 'label': 'Gastro'},
  {'emoji': '🎵', 'label': 'Muzika'},
  {'emoji': '⚽', 'label': 'Sport'},
  {'emoji': '📅', 'label': 'Event'},
  {'emoji': '📢', 'label': 'Promo'},
];

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final _selected = <String>{};
  String? _userId;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userId ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  Future<void> _saveInterests() async {
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ne mogu pronaći korisnički nalog.')),
        );
      }
      return;
    }

    final indexes = _selected
        .map((label) => _categories.indexWhere((cat) => cat['label'] == label))
        .where((index) => index >= 0)
        .toList();

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('korisnici').doc(_userId).update({
        'interests': indexes,
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri spremanju interesa: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selected.length >= 3;

    return Theme(
      data: buildDarkTheme(),
      child: Builder(builder: (context) => Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const _Logo(size: 91),
              const SizedBox(height: 4),
              Text('Izaberi interese', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Odaberi najmanje 3 teme.\nFeed će biti prilagođen tebi.',
                style: TextStyle(color: context.textMuted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 8),

              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: canContinue ? kOrange.withValues(alpha: 0.15) : context.ghostBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: canContinue ? kOrange : context.border, width: 1),
                    ),
                    child: Text(
                      '${_selected.length} odabrano${canContinue ? ' ✓' : ''}',
                      style: TextStyle(
                        color: canContinue ? kOrange : context.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              Expanded(
                child: GridView.builder(
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final label = cat['label']!;
                    final isSelected = _selected.contains(label);
                    return GestureDetector(
                      onTap: () => _toggle(label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected ? kOrange.withValues(alpha: 0.15) : context.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? kOrange : context.border,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cat['emoji']!, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? kOrange : context.textPrimary,
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: canContinue && !_saving ? _saveInterests : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canContinue ? kOrange : context.surface,
                  foregroundColor: canContinue ? Colors.white : context.textMuted,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Počni s čitanjem'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      )),
    ));
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({this.size = 84});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/logobeztr.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
