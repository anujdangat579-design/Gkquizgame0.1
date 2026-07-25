import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../routes/study_notes_routes.dart';
import '../providers/notes_notifier.dart';
import '../providers/notes_state.dart';
import '../widgets/note_card.dart';

/// Notes list, optionally filtered to one category. Reached either from
/// `NoteCategoriesPage` (category picked -> `categoryId` set,
/// `categoryLabel` used as the app-bar title while notes load) or via
/// "Browse all notes" (`categoryId == null`).
class NotesListPage extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? categoryLabel;

  const NotesListPage({super.key, this.categoryId, this.categoryLabel});

  @override
  ConsumerState<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends ConsumerState<NotesListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesNotifierProvider(widget.categoryId).notifier).loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesNotifierProvider(widget.categoryId));
    final notifier = ref.read(notesNotifierProvider(widget.categoryId).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryLabel ?? 'All notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search notes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                isDense: true,
              ),
              onSubmitted: (value) => notifier.loadNotes(search: value.trim().isEmpty ? null : value.trim()),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.viewState == NotesViewState.loading && state.notes.isEmpty) {
                  return const LoadingIndicator();
                }

                if (state.viewState == NotesViewState.error && state.notes.isEmpty) {
                  return ErrorState(
                    message: state.errorMessage ?? 'Something went wrong',
                    onRetry: () => notifier.loadNotes(),
                  );
                }

                if (state.notes.isEmpty) {
                  return const EmptyState(
                    message: 'No notes found.',
                    icon: Icons.menu_book_outlined,
                  );
                }

                final columns = context.responsive(mobile: 2, tablet: 3, desktop: 4);

                return RefreshIndicator(
                  onRefresh: () => notifier.loadNotes(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: state.notes.length,
                    itemBuilder: (context, index) {
                      final note = state.notes[index];
                      return NoteCard(
                        note: note,
                        onTap: () => context.push(StudyNotesRoutes.detailsPath(note.id)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
