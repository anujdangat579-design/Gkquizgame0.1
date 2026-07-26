import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/purchased_note.dart';
import '../providers/purchased_notes_notifier.dart';
import '../providers/purchased_notes_state.dart';

class PurchasedNotesPage extends ConsumerStatefulWidget {
  const PurchasedNotesPage({super.key});

  @override
  ConsumerState<PurchasedNotesPage> createState() => _PurchasedNotesPageState();
}

class _PurchasedNotesPageState extends ConsumerState<PurchasedNotesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchasedNotesNotifierProvider.notifier).loadPurchasedNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasedNotesNotifierProvider);
    final notifier = ref.read(purchasedNotesNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchased Notes')),
      body: Builder(
        builder: (context) {
          if (state.viewState == PurchasedNotesViewState.loading && state.notes.isEmpty) {
            return const LoadingIndicator();
          }
          if (state.viewState == PurchasedNotesViewState.error && state.notes.isEmpty) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadPurchasedNotes(),
            );
          }
          if (state.notes.isEmpty) {
            return const EmptyState(
              message: "You haven't purchased any notes yet.",
              icon: Icons.menu_book_outlined,
            );
          }

          final columns = context.responsive(mobile: 1, tablet: 2, desktop: 3);

          return RefreshIndicator(
            onRefresh: () => notifier.loadPurchasedNotes(),
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: 108,
              ),
              itemCount: state.notes.length,
              itemBuilder: (context, index) => _PurchasedNoteTile(note: state.notes[index]),
            ),
          );
        },
      ),
    );
  }
}

class _PurchasedNoteTile extends StatelessWidget {
  final PurchasedNote note;

  const _PurchasedNoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat(AppConstants.dateDisplayFormat);

    return Card(
      child: ListTile(
        onTap: () => _showDetails(context),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: note.thumbnailUrl != null ? NetworkImage(note.thumbnailUrl!) : null,
          child: note.thumbnailUrl == null
              ? Icon(Icons.description_outlined, color: colorScheme.onPrimaryContainer)
              : null,
        ),
        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${note.subject ?? 'General'} · Purchased ${dateFormat.format(note.purchasedAt)}',
        ),
        trailing: Text('${note.price.toStringAsFixed(0)} ${note.currency}'),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.subject != null) Text('Subject: ${note.subject}'),
            if (note.pageCount != null) Text('${note.pageCount} pages'),
            Text('Price paid: ${note.price.toStringAsFixed(2)} ${note.currency}'),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Opening notes in-app is not wired up yet — this just shows what you bought.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
