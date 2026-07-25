import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/note_category.dart';
import '../../routes/study_notes_routes.dart';
import '../widgets/note_category_grid.dart';

/// Study Notes entry point - browse by category, jump into the full
/// catalog, or open "My Library" (notes already bought). Wired into the
/// router at `StudyNotesRoutes.home`.
class NoteCategoriesPage extends StatelessWidget {
  const NoteCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: 'My Library',
            onPressed: () => context.push(StudyNotesRoutes.libraryPath),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(StudyNotesRoutes.listPath()),
                    icon: const Icon(Icons.grid_view_outlined),
                    label: const Text('Browse all notes'),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            child: NoteCategoryGrid(
              onCategoryTap: (category) => _openCategory(context, category),
            ),
          ),
        ],
      ),
    );
  }

  void _openCategory(BuildContext context, NoteCategory category) {
    context.push(
      StudyNotesRoutes.listPath(categoryId: category.id),
      extra: category.name,
    );
  }
}
