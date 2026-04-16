import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = darkModeNotifier.value;
  bool _autoplay = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Podešavanja',
              style: TextStyle(
                color: context.textPrimary,
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
            onChanged: (v) async {
              setState(() => _darkMode = v);
              darkModeNotifier.value = v;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('darkMode', v);
            },
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
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        secondary: Icon(icon, color: kOrange, size: 22),
        title: Text(title, style: TextStyle(color: context.textPrimary, fontSize: 14)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: kOrange,
        inactiveTrackColor: context.ghostBg,
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
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Icon(icon, color: kOrange, size: 22),
        title: Text(title, style: TextStyle(color: context.textPrimary, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(trailing!, style: TextStyle(color: context.textMuted, fontSize: 13)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 18),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
