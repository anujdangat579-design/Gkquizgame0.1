import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Shown in the dashboard's app bar so an admin can tell a quiet screen
/// apart from a dropped socket. TODO(backend): once
/// `CompetitionControlSocketService` is confirmed working against a
/// real server, consider also surfacing "reconnecting…" as a third
/// state instead of just connected/disconnected.
class LiveConnectionIndicator extends StatefulWidget {
  final bool isConnected;

  const LiveConnectionIndicator({super.key, required this.isConnected});

  @override
  State<LiveConnectionIndicator> createState() => _LiveConnectionIndicatorState();
}

class _LiveConnectionIndicatorState extends State<LiveConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final color = widget.isConnected ? semantic.success : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: widget.isConnected
                ? Tween(begin: 0.35, end: 1.0).animate(_controller)
                : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            widget.isConnected ? 'Live' : 'Reconnecting…',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
