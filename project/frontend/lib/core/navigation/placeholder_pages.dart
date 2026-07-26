import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Placeholder for the shell's "Account" tab.
///
/// Mirrors `CompleteProfilePage`'s fields conceptually (name, avatar) but
/// as a *read* view for an already-onboarded user, once auth/user data
/// exists to read from. Also the natural home for a future "log out".
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const _ComingSoon(
        icon: Icons.account_circle_outlined,
        message: "Account details aren't wired up yet.",
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ComingSoon({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
