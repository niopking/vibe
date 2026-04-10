import 'package:flutter/material.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kTextMuted = Color(0xFF888888);

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Tech', 'icon': Icons.computer_rounded},
    {'label': 'Sport', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Lifestyle', 'icon': Icons.self_improvement_rounded},
    {'label': 'Auto', 'icon': Icons.directions_car_rounded},
    {'label': 'Travel', 'icon': Icons.flight_rounded},
    {'label': 'Health', 'icon': Icons.favorite_rounded},
    {'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'label': 'Business', 'icon': Icons.business_center_rounded},
    {'label': 'Entertainment', 'icon': Icons.movie_rounded},
    {'label': 'Science', 'icon': Icons.science_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Kategorije',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      color: kGrey,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _categories[i]['icon'] as IconData,
                            color: kOrange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _categories[i]['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}