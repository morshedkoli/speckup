import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final currentThemeMode = themeModeAsync.asData?.value ?? ThemeMode.system;
    final isDarkMode = currentThemeMode == ThemeMode.dark ||
        (currentThemeMode == ThemeMode.system && isDark);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Profile Card ────────────────────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _Avatar(
                  name: user?.displayName ?? 'User',
                  photoUrl: user?.photoURL,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Guest',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionLabel(label: 'Appearance'),
          const SizedBox(height: 8),

          // ── Appearance ──────────────────────────────────────────────────────
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingRow(
                  icon: LucideIcons.moon,
                  iconColor: AppColors.vocabulary,
                  title: 'Dark Mode',
                  trailing: Switch.adaptive(
                    value: isDarkMode,
                    onChanged: (_) =>
                        ref.read(themeModeProvider.notifier).toggle(),
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionLabel(label: 'Account'),
          const SizedBox(height: 8),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingRow(
                  icon: LucideIcons.logOut,
                  iconColor: AppColors.destructive,
                  title: 'Sign Out',
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Sign out?'),
                        content: const Text(
                          'Your progress is saved. You can sign back in anytime.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(authServiceProvider).signOut();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionLabel(label: 'About'),
          const SizedBox(height: 8),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingRow(
                  icon: LucideIcons.info,
                  iconColor: AppColors.reading,
                  title: 'About SpeakUp AI',
                  subtitle: 'Version 1.0.0',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'SpeakUp AI',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 SpeakUp AI',
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'An AI-powered IELTS preparation app with reading, '
                        'writing, vocabulary, and diagnostic features.',
                      ),
                    ],
                  ),
                ),
                _Divider(),
                _SettingRow(
                  icon: LucideIcons.helpCircle,
                  iconColor: AppColors.writing,
                  title: 'Help & Support',
                  subtitle: 'support@speakupai.app',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email us at support@speakupai.app'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── App badge ───────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'SpeakUp AI',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'IELTS preparation, powered by AI',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted(context),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.zinc800 : AppColors.zinc200,
      indent: 52,
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted(context),
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: isDark ? AppColors.zinc600 : AppColors.zinc400,
                )
              : null),
      onTap: onTap,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photoUrl});
  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          photoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(name: name),
        ),
      );
    }
    return _Initials(name: name);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
