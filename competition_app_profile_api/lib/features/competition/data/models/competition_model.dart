import '../../domain/entities/competition.dart';

/// Data-layer model. Knows how to (de)serialize JSON; the domain layer
/// never sees this class, only the [Competition] entity it extends.
class CompetitionModel extends Competition {
  const CompetitionModel({
    required super.id,
    required super.name,
    super.description,
    super.startDate,
    super.endDate,
    required super.status,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      status: (json['status'] as String?) == 'disabled'
          ? CompetitionStatus.disabled
          : CompetitionStatus.enabled,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };
  }

  static Map<String, dynamic> toUpdateJson({
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };
  }
}
