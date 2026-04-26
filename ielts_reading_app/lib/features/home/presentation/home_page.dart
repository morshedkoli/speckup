import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/route_names.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/animated_touch_response.dart';
import '../../../features/diagnostic/data/diagnostic_repository.dart';
import '../../../features/progress/providers/progress_providers.dart';
import '../../../services/firebase/firebase_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final diagnosticCompleted =
        ref.watch(diagnosticCompletedProvider).value == true;
    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _UserAvatar(
                  photoUrl: user?.photoURL,
                  displayName: user?.displayName,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        user?.displayName ?? 'Learner',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _BandScoreBanner(),
            const SizedBox(height: 24),
            if (!diagnosticCompleted) ...[
              _buildActionCard(
                context,
                title: 'Take Diagnostic Test',
                subtitle: 'Assess your current band score',
                icon: LucideIcons.target,
                color: theme.colorScheme.primary,
                onTap: () => context.pushNamed(RouteNames.diagnosticIntro),
              ),
              const SizedBox(height: 16),
            ],
            _buildActionCard(
              context,
              title: 'Reading Practice',
              subtitle: 'Browse IELTS reading materials',
              icon: LucideIcons.bookOpen,
              color: Colors.blueAccent,
              onTap: () => context.pushNamed(RouteNames.library),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Writing Practice',
              subtitle: 'Generate IELTS writing tasks and get band feedback',
              icon: LucideIcons.edit2,
              color: Colors.orangeAccent,
              onTap: () => context.pushNamed(RouteNames.writingLibrary),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Vocabulary Builder',
              subtitle: 'Learn advanced English words in batches of five',
              icon: LucideIcons.languages,
              color: Colors.purpleAccent,
              onTap: () => context.pushNamed(RouteNames.vocabulary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return AnimatedTouchResponse(
      onTap: onTap ?? () {},
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;

  const _UserAvatar({this.photoUrl, this.displayName});

  String get _initials {
    final name = displayName ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 56.0;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _FallbackAvatar(
            initials: _initials,
            size: size,
            theme: theme,
          ),
          errorWidget: (_, __, ___) => _FallbackAvatar(
            initials: _initials,
            size: size,
            theme: theme,
          ),
        ),
      );
    }

    return _FallbackAvatar(initials: _initials, size: size, theme: theme);
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final ThemeData theme;

  const _FallbackAvatar({
    required this.initials,
    required this.size,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withOpacity(0.15),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BandScoreBanner extends ConsumerWidget {
  const _BandScoreBanner();

  Color _bandColor(double band) {
    if (band >= 7.5) return Colors.green;
    if (band >= 6.0) return Colors.blue;
    if (band >= 4.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(progressStatsStreamProvider);

    return statsAsync.when(
      loading: () => const _BandBannerSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.totalSessions == 0) return const _BandBannerEmpty();

        final color = _bandColor(stats.currentBand);
        final trend = stats.trend;
        final trendIcon = trend > 0
            ? LucideIcons.trendingUp
            : trend < 0
                ? LucideIcons.trendingDown
                : LucideIcons.minus;
        final trendColor = trend > 0
            ? Colors.green
            : trend < 0
                ? Colors.red
                : theme.colorScheme.onSurface.withOpacity(0.4);

        return AnimatedTouchResponse(
          onTap: () => context.pushNamed(RouteNames.progress),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Big band score circle
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.12),
                    border: Border.all(color: color.withOpacity(0.4), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    stats.currentBand.toStringAsFixed(1),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Band Score',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stats.bandLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.totalSessions} session${stats.totalSessions == 1 ? '' : 's'} • Avg ${stats.averageBand.toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(trendIcon, color: trendColor, size: 22),
                    const SizedBox(height: 4),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.25),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BandBannerSkeleton extends StatelessWidget {
  const _BandBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurface.withOpacity(0.06),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    )),
                const SizedBox(height: 8),
                Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BandBannerEmpty extends StatelessWidget {
  const _BandBannerEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedTouchResponse(
      onTap: () => context.pushNamed(RouteNames.library),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.08),
              ),
              alignment: Alignment.center,
              child: Text(
                '—',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Band Score Yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete a practice to see your score',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: theme.colorScheme.onSurface.withOpacity(0.25)),
          ],
        ),
      ),
    );
  }
}
