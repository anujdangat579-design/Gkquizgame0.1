import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/routes/auth_routes.dart';
import '../../../profile/presentation/pages/badges_page.dart';
import '../../../profile/presentation/pages/match_history_page.dart';
import '../../../profile/presentation/pages/purchased_notes_page.dart';
import '../../../profile/presentation/pages/statistics_page.dart';
import '../../../profile/presentation/pages/transactions_page.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/account_notifier.dart';
import '../providers/account_state.dart';
import 'edit_profile_page.dart';

/// The shell's "Account" tab — shows the logged-in admin's profile (see
/// `MainShellPage`'s doc comment), with an edit action and sign-out.
/// Loads via `accountNotifierProvider`, which calls the `GetProfile` use
/// case (account/domain) -> `AccountRepositoryImpl` (account/data),
/// mirroring how `competition/` and `auth/` are wired. The edit action
/// pushes `EditProfilePage`, which wires the same feature's
/// `UpdateProfile` use case — previously registered but never called
/// from any screen (see `AccountRepository.updateProfile`'s old doc
/// comment).
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  @override
  void initState() {
    super.initState();
    // Fires after the first frame so it doesn't run during build; this
    // tab can be revisited via bottom-nav without reloading each time
    // (mirrors CompetitionListPage's initState-triggered load).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(accountNotifierProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          if (state.viewState == AccountViewState.loaded)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit profile',
              onPressed: () => _handleEditProfile(context, state.profile!),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AccountState state) {
    switch (state.viewState) {
      case AccountViewState.initial:
      case AccountViewState.loading:
        return const LoadingIndicator();
      case AccountViewState.error:
        return ErrorState(
          message: state.errorMessage ?? 'Something went wrong',
          onRetry: () => ref.read(accountNotifierProvider.notifier).loadProfile(),
        );
      case AccountViewState.loaded:
        return _ProfileView(profile: state.profile!);
    }
  }

  Future<void> _handleEditProfile(BuildContext context, UserProfile profile) async {
    // Not yet added to go_router (mirrors ScoreReportPage/
    // WinnerFeedbackPage's same not-yet-routed state) — push directly.
    // `accountNotifierProvider`'s state already reflects any successful
    // save by the time this returns (see `EditProfilePage._handleSubmit`
    // -> `AccountNotifier.editProfile`), so `_buildBody` picks up the
    // change automatically without an explicit reload here.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: "You'll need to sign in again to manage ${AppConstants.appName}.",
      confirmLabel: 'Log out',
    );
    if (!confirmed) return;

    await ref.read(authNotifierProvider.notifier).logOut();
    if (!context.mounted) return;
    context.go(AuthRoutes.login);
  }
}

class _ProfileView extends StatelessWidget {
  final UserProfile profile;

  const _ProfileView({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null
                ? Icon(Icons.person_outline, size: 48, color: colorScheme.onPrimaryContainer)
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(profile.name, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        if (profile.username != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '@${profile.username}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        _ProfileField(icon: Icons.mail_outline, label: 'Email', value: profile.email),
        if (profile.dateOfBirth != null)
          _ProfileField(
            icon: Icons.cake_outlined,
            label: 'Date of birth',
            value: DateFormat(AppConstants.dateDisplayFormat).format(profile.dateOfBirth!),
          ),
        if (profile.gender != null)
          _ProfileField(icon: Icons.wc_outlined, label: 'Gender', value: profile.gender!),
        const SizedBox(height: AppSpacing.xxl),
        Text('Your Profile', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _ProfileSectionTile(
          icon: Icons.sports_esports_outlined,
          label: 'Match History',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MatchHistoryPage()),
          ),
        ),
        _ProfileSectionTile(
          icon: Icons.bar_chart_outlined,
          label: 'Statistics',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatisticsPage()),
          ),
        ),
        _ProfileSectionTile(
          icon: Icons.military_tech_outlined,
          label: 'Badges',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BadgesPage()),
          ),
        ),
        _ProfileSectionTile(
          icon: Icons.receipt_long_outlined,
          label: 'Transactions',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionsPage()),
          ),
        ),
        _ProfileSectionTile(
          icon: Icons.menu_book_outlined,
          label: 'Purchased Notes',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PurchasedNotesPage()),
          ),
        ),
      ],
    );
  }
}

/// One row in the "Your Profile" section — same `Navigator.push` pattern
/// as `_handleEditProfile` (these five pages aren't in go_router yet
/// either). Kept local to this file since it's only ever used here.
class _ProfileSectionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileSectionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
