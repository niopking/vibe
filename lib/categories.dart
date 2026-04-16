import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'jedna_kategorija.dart';

// Shared state — which categories the user has muted.
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
                        Expanded(
                          child: Text(
                            'Kategorije',
                            style: TextStyle(
                              color: context.textPrimary,
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
                                  : context.ghostBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isLocked
                                    ? kOrange.withValues(alpha: 0.45)
                                    : context.border,
                                width: 0.9,
                              ),
                            ),
                            child: Icon(
                              isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                              size: 18,
                              color: isLocked ? kOrange : context.textMuted,
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
                        Icon(Icons.info_outline_rounded,
                            color: context.textMuted, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isLocked
                                ? 'Kategorije su zaključane'
                                : disabled.isEmpty
                                    ? 'Klikni ikonicu da sakriješ kategoriju'
                                    : '${disabled.length} sakrivenih kategorija',
                            style: TextStyle(
                              color: context.textMuted,
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
                              builder: (_) => CategoryNewsScreen(category: label),
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
        ? context.ghostBg
        : kOrange.withValues(alpha: 0.15);
    final iconColor = isDisabled ? context.textMuted : (isLocked ? context.textMuted : kOrange);
    final labelColor = isDisabled ? context.textMuted : context.textPrimary;

    return GestureDetector(
      onTap: onBoxTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isDisabled
              ? context.surface.withValues(alpha: 0.55)
              : context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border),
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
                  color: isLocked ? context.ghostBg : iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDisabled
                        ? context.border
                        : isLocked
                            ? context.border
                            : kOrange.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
                      decorationColor: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDisabled ? 'Sakriveno' : 'Aktivno',
                    style: TextStyle(
                      color: isDisabled ? context.textMuted : kOrange,
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
