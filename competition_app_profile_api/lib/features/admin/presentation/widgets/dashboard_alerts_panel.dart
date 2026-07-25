import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/competition_control_snapshot.dart';

class DashboardAlertsPanel extends StatelessWidget {
  final List<DashboardAlert> alerts;
  final ValueChanged<String> onDismiss;

  const DashboardAlertsPanel({super.key, required this.alerts, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text('Alerts', style: theme.textTheme.titleMedium),
                  if (alerts.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _CountBadge(count: alerts.length),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: context.semanticColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Text('No active alerts', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              )
            else
              ...alerts.map((alert) => _AlertTile(alert: alert, onDismiss: () => onDismiss(alert.id))),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onErrorContainer, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final DashboardAlert alert;
  final VoidCallback onDismiss;

  const _AlertTile({required this.alert, required this.onDismiss});

  (IconData, Color, Color) _visuals(BuildContext context) {
    final semantic = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;
    return switch (alert.type) {
      DashboardAlertType.paymentFailed => (Icons.payment, colorScheme.errorContainer, colorScheme.onErrorContainer),
      DashboardAlertType.disconnectedPlayer => (Icons.wifi_off, semantic.warningContainer, semantic.onWarningContainer),
      DashboardAlertType.playerReport => (Icons.flag_outlined, semantic.infoContainer, semantic.onInfoContainer),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, bg, fg) = _visuals(context);

    return Dismissible(
      key: ValueKey(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.close, color: theme.colorScheme.onErrorContainer),
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: bg, child: Icon(icon, color: fg, size: 20)),
        title: Text(alert.message, style: theme.textTheme.bodyMedium),
        subtitle: Text(DateFormat.jm().format(alert.occurredAt)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          tooltip: 'Dismiss',
          onPressed: onDismiss,
        ),
      ),
    );
  }
}
