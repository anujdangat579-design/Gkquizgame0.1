import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';

/// Circular icon indicating an on/off (enabled/disabled) status, colored
/// via the app's semantic "success" token when active and neutral when
/// inactive. Used as list-item leading widgets across any feature with a
/// toggleable status.
class StatusAvatar extends StatelessWidget {
  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const StatusAvatar({
    super.key,
    required this.isActive,
    this.activeIcon = Icons.check,
    this.inactiveIcon = Icons.pause,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    final activeBg = semantic.successContainer;
    final activeFg = semantic.onSuccessContainer;
    final inactiveBg = semantic.neutralContainer;
    final inactiveFg = Theme.of(context).colorScheme.onSurfaceVariant;

    return CircleAvatar(
      backgroundColor: isActive ? activeBg : inactiveBg,
      child: Icon(
        isActive ? activeIcon : inactiveIcon,
        color: isActive ? activeFg : inactiveFg,
      ),
    );
  }
}
