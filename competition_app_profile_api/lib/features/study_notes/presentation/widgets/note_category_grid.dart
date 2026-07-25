import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/note_category.dart';
import '../providers/note_category_notifier.dart';
import '../providers/note_category_state.dart';

/// Grid of note-category cards, loaded from `ApiConstants.noteCategories`
/// via `noteCategoryNotifierProvider`. Mirrors `CategoryGrid`
/// (competition feature) exactly, including its icon-lookup approach.
class NoteCategoryGrid extends ConsumerStatefulWidget {
  final ValueChanged<NoteCategory> onCategoryTap;

  const NoteCategoryGrid({super.key, required this.onCategoryTap});

  @override
  ConsumerState<NoteCategoryGrid> createState() => _NoteCategoryGridState();
}

class _NoteCategoryGridState extends ConsumerState<NoteCategoryGrid> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(noteCategoryNotifierProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteCategoryNotifierProvider);

    switch (state.viewState) {
      case NoteCategoryViewState.initial:
      case NoteCategoryViewState.loading:
        return const LoadingIndicator();
      case NoteCategoryViewState.error:
        return ErrorState(
          message: state.errorMessage ?? 'Something went wrong',
          onRetry: () => ref.read(noteCategoryNotifierProvider.notifier).loadCategories(),
        );
      case NoteCategoryViewState.loaded:
        if (state.categories.isEmpty) {
          return const EmptyState(
            message: 'No note categories yet.',
            icon: Icons.category_outlined,
          );
        }
        return _NoteCategoryGridView(categories: state.categories, onCategoryTap: widget.onCategoryTap);
    }
  }
}

class _NoteCategoryGridView extends StatelessWidget {
  final List<NoteCategory> categories;
  final ValueChanged<NoteCategory> onCategoryTap;

  const _NoteCategoryGridView({required this.categories, required this.onCategoryTap});

  // Backend `icon` string -> Material icon, same convention as
  // `CategoryGrid._iconLookup`; falls back to a generic icon for any
  // key not listed here.
  static const Map<String, IconData> _iconLookup = {
    'science': Icons.science_outlined,
    'mathematics': Icons.calculate_outlined,
    'history': Icons.history_edu_outlined,
    'geography': Icons.terrain_outlined,
    'polity': Icons.account_balance_outlined,
    'economy': Icons.trending_up_outlined,
    'reasoning': Icons.psychology_outlined,
    'english': Icons.abc_outlined,
    'computer': Icons.memory_outlined,
    'current_affairs': Icons.newspaper_outlined,
    'general_knowledge': Icons.public_outlined,
  };

  static const IconData _fallbackIcon = Icons.menu_book_outlined;

  IconData _iconFor(String iconKey) => _iconLookup[iconKey.toLowerCase().trim()] ?? _fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(mobile: 2, tablet: 3, desktop: 4);

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.95,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _NoteCategoryCard(
          category: category,
          icon: _iconFor(category.iconKey),
          color: _colorFor(context, index),
          onTap: () => onCategoryTap(category),
        );
      },
    );
  }

  _CategoryColor _colorFor(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = [
      _CategoryColor(colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      _CategoryColor(colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
      _CategoryColor(colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
    ];
    return palette[index % palette.length];
  }
}

class _CategoryColor {
  final Color background;
  final Color foreground;

  const _CategoryColor(this.background, this.foreground);
}

class _NoteCategoryCard extends StatelessWidget {
  final NoteCategory category;
  final IconData icon;
  final _CategoryColor color;
  final VoidCallback onTap;

  const _NoteCategoryCard({
    required this.category,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color.foreground, size: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (category.noteCount != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${category.noteCount} notes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
