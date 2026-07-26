import 'package:equatable/equatable.dart';

enum CompetitionStatus { enabled, disabled }

/// Pure domain entity — no JSON, no Dio, nothing that ties it to the API.
/// Mirrors the `Competition` schema in WIRING.md / swagger.js.
class Competition extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final CompetitionStatus status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Competition({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEnabled => status == CompetitionStatus.enabled;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        startDate,
        endDate,
        status,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
