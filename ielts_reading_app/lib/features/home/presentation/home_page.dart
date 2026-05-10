import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../features/progress/domain/progress_stats.dart';
import '../../../features/progress/providers/progress_providers.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(progressStatsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(progressStatsStreamProvider),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                sliver: SliverList.list(
                  children: [
                    _Header(
                      name: user?.displayName ?? 'Learner',
                      photoUrl: user?.photoURL,
                      onProfile: () => context.pushNamed(RouteNames.progress),
                      onSettings: () => context.pushNamed(RouteNames.settings),
                      onSignOut: () => ref.read(authServiceProvider).signOut(),
                    ),
                    const SizedBox(height: 24),
                    stats.when(
                      loading: () => const _DashboardSkeleton(),
                      error: (_, __) => _ErrorCard(
                        onRetry: () =>
                            ref.invalidate(progressStatsStreamProvider),
                      ),
                      data: (value) => _Dashboard(stats: value),
                    ),
                    const SizedBox(height: 16),
                    _ContinueCard(
                      onTap: () => context.pushNamed(RouteNames.library),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Practice'),
                    const SizedBox(height: 12),
                    const _ModuleGrid(),
                    const SizedBox(height: 24),
                    _BadgeRow(
                      stats: stats.maybeWhen(
                        data: (value) => value,
                        orElse: () => ProgressStats.empty,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.onProfile,
    required this.onSettings,
    required this.onSignOut,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
  final VoidCallback onProfile;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firstName = name.trim().split(RegExp(r'\s+')).first;

    return Row(
      children: [
        _Avatar(name: name, photoUrl: photoUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted(context),
                ),
              ),
              Text(
                firstName.isEmpty ? 'Learner' : firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        _HeaderAction(
          icon: LucideIcons.barChart3,
          onTap: onProfile,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _HeaderAction(
          icon: LucideIcons.settings,
          onTap: onSettings,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _HeaderAction(
          icon: LucideIcons.logOut,
          onTap: onSignOut,
          isDark: isDark,
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.zinc900 : AppColors.zinc100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.zinc800 : AppColors.zinc200,
          ),
        ),
        child: Icon(icon, size: 18, color: AppColors.textMuted(context)),
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Card ────────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final level = (stats.xp ~/ 100) + 1;
    final levelProgress = (stats.xp % 100) / 100;

    return AppCard(
      padding: const EdgeInsets.all(20),
      gradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(text: '🔥 ${stats.currentStreak}'),
              const SizedBox(width: 8),
              _Pill(text: '${stats.xp} XP'),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            stats.totalSessions == 0
                ? 'Start today with one focused session.'
                : 'Daily goal complete. Keep the momentum.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          AppProgressBar(
            value: levelProgress,
            height: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Level $level',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${(levelProgress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ─── Continue Card ─────────────────────────────────────────────────────────────

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.play,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue learning',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Resume reading, writing, or review words.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: AppColors.textMuted(context),
          ),
        ],
      ),
    );
  }
}

// ─── Module Grid ───────────────────────────────────────────────────────────────

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _ModuleTile(
          title: 'Reading',
          subtitle: 'Practice tests',
          icon: LucideIcons.bookOpen,
          color: AppColors.reading,
          onTap: () => context.pushNamed(RouteNames.library),
        ),
        _ModuleTile(
          title: 'Writing',
          subtitle: 'Task editor',
          icon: LucideIcons.penTool,
          color: AppColors.writing,
          onTap: () => context.pushNamed(RouteNames.writingLibrary),
        ),
        _ModuleTile(
          title: 'Vocabulary',
          subtitle: 'Flashcards',
          icon: LucideIcons.languages,
          color: AppColors.vocabulary,
          onTap: () => context.pushNamed(RouteNames.vocabulary),
        ),
        _ModuleTile(
          title: 'Synonyms',
          subtitle: 'Quick quiz',
          icon: LucideIcons.shuffle,
          color: AppColors.synonyms,
          onTap: () => context.pushNamed(RouteNames.synonyms),
        ),
        _ModuleTile(
          title: 'Essay AI',
          subtitle: 'Get evaluated',
          icon: LucideIcons.sparkles,
          color: AppColors.essayAi,
          onTap: () => context.pushNamed(RouteNames.freeWriteEssay),
        ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted(context),
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge Row ─────────────────────────────────────────────────────────────────

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BadgeCard(
            icon: LucideIcons.trophy,
            title: 'Best Band',
            value: stats.bestBand > 0 ? stats.bestBand.toStringAsFixed(1) : '-',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BadgeCard(
            icon: LucideIcons.badgeCheck,
            title: 'Completed',
            value: '${stats.totalSessions}',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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

// ─── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

// ─── States ────────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: SizedBox(height: 140),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            LucideIcons.cloudOff,
            size: 18,
            color: AppColors.textMuted(context),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Progress will sync when available.')),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
