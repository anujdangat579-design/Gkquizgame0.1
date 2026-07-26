import 'package:equatable/equatable.dart';

/// Pure domain entity for a quiz category — no JSON, no Dio, and (unlike
/// an earlier draft of this file) no Flutter import either: `icon` stays
/// a plain string key here, matching the "domain has zero knowledge of
/// Dio, JSON, or Flutter" rule the README lays out for every other
/// entity. `CategoryGrid` (its only consumer, under
/// `competition/presentation/widgets/`) is what resolves `iconKey` to a
/// real `IconData`, since that mapping is a presentation concern.
class Category extends Equatable {
  final String id;
  final String name;
  final String? subtitle;

  /// Backend-provided icon identifier (e.g. `"science"`, `"history"`).
  /// See `CategoryGrid._iconFor` for the lookup table and fallback icon.
  final String iconKey;

  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    this.subtitle,
  });

  @override
  List<Object?> get props => [id, name, subtitle, iconKey];
}
