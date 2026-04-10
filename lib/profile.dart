import 'package:flutter/material.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kTextMuted = Color(0xFF888888);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          // Avatar + name
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: kOrange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kOrange.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: kOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Amir Hodžić',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'amir.hodzic@email.com',
                  style: TextStyle(color: kTextMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            children: const [
              _StatCard(value: '48', label: 'Sačuvano'),
              SizedBox(width: 12),
              _StatCard(value: '12', label: 'Komentari'),
              SizedBox(width: 12),
              _StatCard(value: '5', label: 'Kategorije'),
            ],
          ),
          const SizedBox(height: 24),
          // Menu items
          _ProfileTile(
            icon: Icons.bookmark_border_rounded,
            title: 'Sačuvani članci',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Moji komentari',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.tune_rounded,
            title: 'Moje kategorije',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.lock_outline_rounded,
            title: 'Promijeni lozinku',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          // Logout
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Odjavi se',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: kOrange,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: kTextMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Icon(icon, color: kOrange, size: 22),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: kTextMuted, size: 18),
        onTap: onTap,
      ),
    );
  }
}