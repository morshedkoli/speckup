import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingTile(context, LucideIcons.user, 'Account Profile'),
                Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                _buildSettingTile(context, LucideIcons.key, 'API Key Configuration'),
                Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                _buildSettingTile(context, LucideIcons.sliders, 'Preferences'),
                Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                _buildSettingTile(context, LucideIcons.moon, 'Dark Mode', isSwitch: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingTile(context, LucideIcons.helpCircle, 'Help & Support'),
                Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                _buildSettingTile(context, LucideIcons.info, 'About SpeakUp'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title, {bool isSwitch = false}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: isSwitch
          ? Switch.adaptive(value: false, onChanged: (v) {})
          : Icon(LucideIcons.chevronRight, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
      onTap: isSwitch ? null : () {},
    );
  }
}
