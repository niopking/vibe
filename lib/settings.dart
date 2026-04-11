import 'package:flutter/material.dart';

const kOrange = Color(0xFFFF8200);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);
const kTextMuted = Color(0xFF888888);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = true;
  bool _autoplay = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Podešavanja',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _SectionLabel(label: 'Obavještenja'),
          _ToggleTile(
            icon: Icons.notifications_none_rounded,
            title: 'Push notifikacije',
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'Izgled'),
          _ToggleTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tamni način',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          _ToggleTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'Auto-play videa',
            value: _autoplay,
            onChanged: (v) => setState(() => _autoplay = v),
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'Opšte'),
          _ActionTile(
            icon: Icons.language_rounded,
            title: 'Jezik',
            trailing: 'Bosanski',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.info_outline_rounded,
            title: 'O aplikaciji',
            trailing: 'v1.0.0',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politika privatnosti',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: kOrange,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        secondary: Icon(icon, color: kOrange, size: 22),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: kOrange,
        inactiveTrackColor: Colors.white12,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Icon(icon, color: kOrange, size: 22),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(trailing!,
                  style: const TextStyle(color: kTextMuted, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: kTextMuted, size: 18),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}