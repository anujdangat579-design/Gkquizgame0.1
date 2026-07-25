import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/player_badge.dart';
import '../providers/badges_notifier.dart';
import '../providers/badges_state.dart';

class BadgesPage extends ConsumerStatefulWidget {
  const BadgesPage({super.key});

  @override
  ConsumerState<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends ConsumerState<BadgesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(badgesNotifierProvider.notifier).loadBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(badgesNotifierProvider);
    final notifier = ref.read(badgesNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: Builder(
        builder: (context) {
          if (state.viewState == BadgesViewState.loading && state.badges.isEmpty) {
            return const LoadingIndicator();
          }
          if (state.viewState == BadgesViewState.error && state.badges.isEmpty) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadBadges(),
            );
          }
          if (state.badges.isEmpty) {
            return const EmptyState(
              message: 'No badges available yet.',
              icon: Icons.military_tech_outlined,
            );
          }

          final columns = context.responsive(mobile: 2, tablet: 3, desktop: 4);

          return RefreshIndicator(
            onRefresh: () => notifier.loadBadges(),
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.85,
              ),
              itemCount: state.badges.length,
              itemBuilder: (context, index) => _BadgeTile(badge: state.badges[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final PlayerBadge badge;

  const _BadgeTile({required this.badge});

  Color _tierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFA8A9AD);
      case BadgeTier.gold:
        return const Color(0xFFD4AF37);
      case BadgeTier.platinum:
        return const Color(0xFF9BA4B4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tierColor = _tierColor(badge.tier);

    return Card(
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: badge.isEarned ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: tierColor.withOpacity(0.2),
                  backgroundImage: badge.iconUrl != null ? NetworkImage(badge.iconUrl!) : null,
                  child: badge.iconUrl == null
                      ? Icon(
                          badge.isEarned ? Icons.military_tech : Icons.lock_outline,
                          color: tierColor,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (!badge.isEarned &&
                    badge.progressCurrent != null &&
                    badge.progressTarget != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${badge.progressCurrent}/${badge.progressTarget}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            if (badge.isEarned && badge.earnedAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Earned on ${DateFormat(AppConstants.dateDisplayFormat).format(badge.earnedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
