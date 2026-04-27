import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/route_names.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/animated_touch_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/diagnostic/data/diagnostic_repository.dart';
import '../../../features/progress/providers/progress_providers.dart';
import '../../../services/firebase/firebase_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final diagnosticCompleted =
        ref.watch(diagnosticCompletedProvider).value == true;

    return BaseScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            _TopBar(user: user, ref: ref),

            // ── Streak + XP row ──────────────────────────────────────────
            const _StreakXpRow(),
            const SizedBox(height: 24),

            // ── Band score / hero card ────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _BandScoreBanner(),
            ),
            const SizedBox(height: 24),

            // ── Diagnostic CTA (if needed) ───────────────────────────────
            if (!diagnosticCompleted)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _DiagnosticBanner(),
              ),

            // ── Module grid ───────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _ModuleGrid(),
            ),
            const SizedBox(height: 28),

            // ── Recent activity ───────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _RecentActivity(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final dynamic user;
  final WidgetRef ref;

  const _TopBar({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'Learner';
    final hour = TimeOfDay.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bg0, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Avatar
          _UserAvatar(
            photoUrl: user?.photoURL as String?,
            displayName: user?.displayName as String?,
            size: 44,
          ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  (user?.displayName as String? ?? 'Learner').split(' ').first,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Settings + logout
          _IconBtn(
            icon: LucideIcons.settings,
            onTap: () => context.pushNamed(RouteNames.settings),
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: LucideIcons.logOut,
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak / XP row
// ─────────────────────────────────────────────────────────────────────────────
class _StreakXpRow extends ConsumerWidget {
  const _StreakXpRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(progressStatsStreamProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatPill(
            icon: LucideIcons.flame,
            iconColor: AppColors.gold,
            label: statsAsync.maybeWhen(
              data: (s) => '${s.currentStreak} day streak',
              orElse: () => '0 day streak',
            ),
          ),
          const SizedBox(width: 10),
          _StatPill(
            icon: LucideIcons.zap,
            iconColor: AppColors.primary,
            label: statsAsync.maybeWhen(
              data: (s) => '${s.xp} XP',
              orElse: () => '0 XP',
            ),
          ),
          const Spacer(),
          AnimatedTouchResponse(
            onTap: () => context.pushNamed(RouteNames.progress),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'View Progress',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Band Score Hero Banner
// ─────────────────────────────────────────────────────────────────────────────
class _BandScoreBanner extends ConsumerWidget {
  const _BandScoreBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(progressStatsStreamProvider);

    return statsAsync.when(
      loading: () => const _BandBannerSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.totalSessions == 0) return const _BandBannerEmpty();

        final color = AppColors.bandColor(stats.currentBand);
        final progress = (stats.currentBand / 9.0).clamp(0.0, 1.0);

        return AnimatedTouchResponse(
          onTap: () => context.pushNamed(RouteNames.progress),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1337EC), Color(0xFF5B21B6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Radial arc score
                _BandArc(band: stats.currentBand, color: color, progress: progress),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IELTS Band Score',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white60,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.bandLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${stats.totalSessions} sessions  •  Avg ${stats.averageBand.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BandArc extends StatelessWidget {
  final double band;
  final Color color;
  final double progress;

  const _BandArc({
    required this.band,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _ArcPainter(progress: progress, color: color),
          ),
          Text(
            band.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

class _BandBannerSkeleton extends StatelessWidget {
  const _BandBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _BandBannerEmpty extends StatelessWidget {
  const _BandBannerEmpty();

  @override
  Widget build(BuildContext context) {
    return AnimatedTouchResponse(
      onTap: () => context.pushNamed(RouteNames.diagnosticIntro),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1337EC), Color(0xFF5B21B6)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.target, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Band Score Yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete a practice session to track your progress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diagnostic Banner
// ─────────────────────────────────────────────────────────────────────────────
class _DiagnosticBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedTouchResponse(
      onTap: () => context.pushNamed(RouteNames.diagnosticIntro),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        accentColor: AppColors.gold,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.clipboardCheck,
                  color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Take Diagnostic Test',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 2),
                  Text('Assess your current band score',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                ],
              ),
            ),
            const Icon(LucideIcons.arrowRight,
                size: 18, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Module Grid (2×2)
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice Modules',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ModuleCard(
                title: 'Reading',
                subtitle: 'IELTS passages',
                icon: LucideIcons.bookOpen,
                gradient: AppColors.readingGradient,
                onTap: () => context.pushNamed(RouteNames.library),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModuleCard(
                title: 'Writing',
                subtitle: 'Essay tasks',
                icon: LucideIcons.edit3,
                gradient: AppColors.writingGradient,
                onTap: () => context.pushNamed(RouteNames.writingLibrary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ModuleCard(
                title: 'Vocabulary',
                subtitle: 'Learn words',
                icon: LucideIcons.languages,
                gradient: AppColors.vocabularyGradient,
                onTap: () => context.pushNamed(RouteNames.vocabulary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModuleCard(
                title: 'Progress',
                subtitle: 'Track growth',
                icon: LucideIcons.barChart2,
                gradient: AppColors.progressGradient,
                onTap: () => context.pushNamed(RouteNames.progress),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTouchResponse(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity
// ─────────────────────────────────────────────────────────────────────────────
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(progressStatsStreamProvider);

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.totalSessions == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.pushNamed(RouteNames.progress),
                  child: Text(
                    'See All',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ActivityRow(
                    icon: LucideIcons.bookOpen,
                    iconColor: AppColors.sky,
                    label: 'Reading Practice',
                    value: '${stats.totalSessions} sessions',
                    band: stats.currentBand,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppColors.borderDark),
                  ),
                  _ActivityRow(
                    icon: LucideIcons.edit3,
                    iconColor: AppColors.gold,
                    label: 'Writing Practice',
                    value: 'Band ${stats.currentBand.toStringAsFixed(1)}',
                    band: stats.currentBand,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final double band;

  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.band,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.bandColor(band),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Avatar
// ─────────────────────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final double size;

  const _UserAvatar({this.photoUrl, this.displayName, this.size = 44});

  String get _initials {
    final name = displayName ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _FallbackAvatar(initials: _initials, size: size),
          errorWidget: (_, __, ___) => _FallbackAvatar(initials: _initials, size: size),
        ),
      );
    }
    return _FallbackAvatar(initials: _initials, size: size);
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const _FallbackAvatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
