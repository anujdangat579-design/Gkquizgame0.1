import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/note.dart';
import '../../routes/study_notes_routes.dart';
import '../providers/buy_note_notifier.dart';
import '../providers/buy_note_state.dart';
import '../providers/note_details_notifier.dart';
import '../providers/note_details_state.dart';

/// Note details + "Buy Notes" screen. Loads `Note` via
/// `noteDetailsNotifierProvider(noteId)`, then drives the Cashfree
/// Web Checkout purchase flow via `buyNoteNotifierProvider(noteId)` -
/// same two-notifier split `CompetitionDetailsPage` uses for join/pay.
///
/// Wired into the router at `StudyNotesRoutes.detailsPath(id)`.
class NoteDetailsPage extends ConsumerStatefulWidget {
  final String noteId;

  const NoteDetailsPage({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailsPage> createState() => _NoteDetailsPageState();
}

class _NoteDetailsPageState extends ConsumerState<NoteDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noteDetailsNotifierProvider(widget.noteId).notifier).loadDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteDetailsNotifierProvider(widget.noteId));
    final notifier = ref.read(noteDetailsNotifierProvider(widget.noteId).notifier);
    final buyState = ref.watch(buyNoteNotifierProvider(widget.noteId));

    return Scaffold(
      appBar: AppBar(title: Text(state.note?.title ?? 'Note details')),
      body: Builder(
        builder: (context) {
          if (state.viewState == NoteDetailsViewState.loading && state.note == null) {
            return const LoadingIndicator();
          }

          if (state.viewState == NoteDetailsViewState.error && state.note == null) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadDetails(),
            );
          }

          final note = state.note;
          if (note == null) {
            return const EmptyState(
              message: 'This note is no longer available.',
              icon: Icons.menu_book_outlined,
            );
          }

          return _NoteDetailsBody(
            note: note,
            isBuying: buyState.isInProgress,
            onBuy: () => _handleBuy(note),
            onOpenLibrary: () => context.push(StudyNotesRoutes.libraryPath),
          );
        },
      ),
    );
  }

  /// Runs the purchase (Cashfree Web Checkout) via
  /// `buyNoteNotifierProvider`. Only after the backend confirms the
  /// purchase does the button flip to "Open in My Library" -
  /// `NoteDetailsNotifier.markPurchased()` updates the already-loaded
  /// note locally so the flip is instant, without a refetch.
  Future<void> _handleBuy(Note note) async {
    final purchased = await ref.read(buyNoteNotifierProvider(widget.noteId).notifier).buy();

    if (!mounted) return;

    if (purchased) {
      ref.read(noteDetailsNotifierProvider(widget.noteId).notifier).markPurchased();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note purchased! Find it in My Library.')),
      );
      return;
    }

    final message = ref.read(buyNoteNotifierProvider(widget.noteId)).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Payment failed. Please try again.')),
    );
  }
}

class _NoteDetailsBody extends StatelessWidget {
  final Note note;
  final bool isBuying;
  final VoidCallback onBuy;
  final VoidCallback onOpenLibrary;

  const _NoteDetailsBody({
    required this.note,
    required this.isBuying,
    required this.onBuy,
    required this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              color: colorScheme.surfaceContainerHighest,
              child: note.thumbnailUrl != null
                  ? Image.network(
                      note.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Icon(Icons.description_outlined, size: 48, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(note.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        if (note.subject != null || note.authorName != null)
          Text(
            [note.subject, if (note.authorName != null) 'by ${note.authorName}']
                .whereType<String>()
                .join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        const SizedBox(height: AppSpacing.lg),

        Row(
          children: [
            if (note.pageCount != null)
              Expanded(
                child: _InfoTile(icon: Icons.menu_book_outlined, label: 'Pages', value: '${note.pageCount}'),
              ),
            if (note.pageCount != null) const SizedBox(width: AppSpacing.md),
            if (note.rating != null)
              Expanded(
                child: _InfoTile(icon: Icons.star_outline, label: 'Rating', value: note.rating!.toStringAsFixed(1)),
              ),
            if (note.rating != null) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _InfoTile(
                icon: Icons.currency_rupee,
                label: 'Price',
                value: currencyFormat.format(note.price),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        if (note.description != null) ...[
          Text('About this note', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(note.description!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxl),
        ],

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: note.isPurchased ? onOpenLibrary : (isBuying ? null : onBuy),
            child: isBuying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    note.isPurchased
                        ? 'Open in My Library'
                        : 'Buy note — ${currencyFormat.format(note.price)}',
                  ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
