import 'package:flutter/material.dart';
import 'jedna_kategorija.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kTextMuted = Color(0xFF888888);

// Shared state — which categories the user has muted.
// Home feed listens to this so disabled categories disappear everywhere.
final ValueNotifier<Set<String>> disabledCategoriesNotifier =
    ValueNotifier<Set<String>>(<String>{});

// Global lock — when true, no category can be toggled; tapping navigates only.
final ValueNotifier<bool> categoriesLockedNotifier = ValueNotifier<bool>(false);

void toggleCategoryFilter(String label) {
  final current = Set<String>.from(disabledCategoriesNotifier.value);
  if (current.contains(label)) {
    current.remove(label);
  } else {
    current.add(label);
  }
  disabledCategoriesNotifier.value = current;
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Showbizz', 'icon': Icons.movie_rounded},
    {'label': 'Lifestyle', 'icon': Icons.self_improvement_rounded},
    {'label': 'Travel', 'icon': Icons.flight_rounded},
    {'label': 'Tech', 'icon': Icons.computer_rounded},
    {'label': 'Gastro', 'icon': Icons.restaurant_rounded},
    {'label': 'Muzika', 'icon': Icons.music_note_rounded},
    {'label': 'Sport', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Event', 'icon': Icons.event_rounded},
    {'label': 'Promo', 'icon': Icons.campaign_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<bool>(
        valueListenable: categoriesLockedNotifier,
        builder: (context, isLocked, _) {
          return ValueListenableBuilder<Set<String>>(
            valueListenable: disabledCategoriesNotifier,
            builder: (context, disabled, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Kategorije',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => categoriesLockedNotifier.value = !isLocked,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLocked
                                  ? kOrange.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isLocked
                                    ? kOrange.withValues(alpha: 0.45)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: 0.9,
                              ),
                            ),
                            child: Icon(
                              isLocked
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 18,
                              color: isLocked ? kOrange : kTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: kTextMuted, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isLocked
                                ? 'Kategorije su zaključane'
                                : disabled.isEmpty
                                    ? 'Klikni ikonicu da sakriješ kategoriju'
                                    : '${disabled.length} sakrivenih kategorija',
                            style: const TextStyle(
                              color: kTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (disabled.isNotEmpty && !isLocked)
                          GestureDetector(
                            onTap: () =>
                                disabledCategoriesNotifier.value = <String>{},
                            child: const Text(
                              'Vrati sve',
                              style: TextStyle(
                                color: kOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, i) {
                        final label = _categories[i]['label'] as String;
                        final icon = _categories[i]['icon'] as IconData;
                        final isDisabled = disabled.contains(label);

                        return _CategoryTile(
                          label: label,
                          icon: icon,
                          isDisabled: isDisabled,
                          isLocked: isLocked,
                          onIconTap: isLocked
                              ? null
                              : () => toggleCategoryFilter(label),
                          onBoxTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CategoryNewsScreen(category: label),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDisabled;
  final bool isLocked;
  final VoidCallback? onIconTap;
  final VoidCallback onBoxTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.isDisabled,
    required this.isLocked,
    required this.onIconTap,
    required this.onBoxTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isDisabled
        ? Colors.white.withValues(alpha: 0.06)
        : kOrange.withValues(alpha: 0.15);
    final iconColor = isDisabled ? kTextMuted : (isLocked ? kTextMuted : kOrange);
    final labelColor = isDisabled ? kTextMuted : Colors.white;

    return GestureDetector(
      onTap: onBoxTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isDisabled
              ? kGrey.withValues(alpha: 0.55)
              : kGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onIconTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.white.withValues(alpha: 0.05)
                      : iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.white.withValues(alpha: 0.08)
                        : isLocked
                            ? Colors.white.withValues(alpha: 0.06)
                            : kOrange.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: isDisabled
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDisabled ? 'Sakriveno' : 'Aktivno',
                    style: TextStyle(
                      color: isDisabled ? kTextMuted : kOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
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
