import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/category.dart';
import '../providers/category_notifier.dart';
import '../providers/category_state.dart';

/// Grid of quiz category cards, loaded from `GET /api/admin/categories`
/// via `categoryNotifierProvider` (category/domain -> category/data,
/// same wiring shape as `CompetitionListPage`). Replaces the earlier
/// fixed local list this widget used to render.
///
/// Not placed on any page yet — same as before this change, nothing in
/// the app builds `CategoryGrid` today (see the doc comments on
/// `CompetitionDetailsPage` / `ResultPage` that reference it as a future
/// navigation source). Drop it into `DashboardPage` or wherever else
/// makes sense; its public API (`onCategoryTap`) hasn't changed.
class CategoryGrid extends ConsumerStatefulWidget {
  final ValueChanged<String>? onCategoryTap;

  const CategoryGrid({super.key, this.onCategoryTap});

  @override
  ConsumerState<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends ConsumerState<CategoryGrid> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(categoryNotifierProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryNotifierProvider);

    switch (state.viewState) {
      case CategoryViewState.initial:
      case CategoryViewState.loading:
        return const LoadingIndicator();
      case CategoryViewState.error:
        return ErrorState(
          message: state.errorMessage ?? 'Something went wrong',
          onRetry: () => ref.read(categoryNotifierProvider.notifier).loadCategories(),
        );
      case CategoryViewState.loaded:
        if (state.categories.isEmpty) {
          return const EmptyState(
            message: 'No categories yet.',
            icon: Icons.category_outlined,
          );
        }
        return _CategoryGridView(categories: state.categories, onCategoryTap: widget.onCategoryTap);
    }
  }
}

class _CategoryGridView extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<String>? onCategoryTap;

  const _CategoryGridView({required this.categories, this.onCategoryTap});

  // Backend `icon` string -> Material icon. Falls back to a generic icon
  // for any key not listed here (new backend categories don't need a
  // client release just to render *something* sensible) — add entries
  // as new category icon keys show up.
  static const Map<String, IconData> _iconLookup = {
    'general_knowledge': Icons.public_outlined,
    'history': Icons.history_edu_outlined,
    'geography': Icons.terrain_outlined,
    'science': Icons.science_outlined,
    'indian_polity': Icons.account_balance_outlined,
    'sports': Icons.sports_cricket_outlined,
    'technology': Icons.memory_outlined,
    'banking': Icons.account_balance_wallet_outlined,
    'ssc': Icons.assignment_outlined,
    'upsc': Icons.gavel_outlined,
    'mpsc': Icons.location_city_outlined,
    'mixed_gk': Icons.shuffle_outlined,
    'mahacet': Icons.school_outlined,
    'jee': Icons.engineering_outlined,
    'jee_main': Icons.functions_outlined,
    'computer_languages': Icons.code_outlined,
  };

  static const IconData _fallbackIcon = Icons.category_outlined;

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
        return _CategoryCard(
          category: category,
          icon: _iconFor(category.iconKey),
          color: _colorFor(context, index),
          onTap: () => (onCategoryTap ?? _defaultTap(context))(category.name),
        );
      },
    );
  }

  ValueChanged<String> _defaultTap(BuildContext context) {
    return (label) {
      // TODO(categories-feature): replace with real navigation (e.g. into
      // a competition list filtered by this category) once that feature
      // exists. Placeholder so the tap isn't a dead affordance.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label isn\'t wired up yet')),
      );
    };
  }

  /// Cycles through the theme's container colors so the grid reads as
  /// varied and "modern" rather than one flat repeated tile, without
  /// inventing colors outside the app's palette.
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

class _CategoryCard extends StatelessWidget {
  final Category category;
  final IconData icon;
  final _CategoryColor color;
  final VoidCallback onTap;

  const _CategoryCard({
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
              if (category.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  category.subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
