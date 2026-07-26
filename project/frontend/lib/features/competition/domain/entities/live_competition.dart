import 'package:equatable/equatable.dart';

/// Pure domain entity — no JSON, no Dio, nothing that ties it to the API.
/// Backs `LiveCompetitionCard`'s data (category, entry fee, question
/// count, time limit, how many players are already waiting, and whether
/// it's still joinable), which previously only took plain constructor
/// values with no entity/data layer behind them.
class LiveCompetition extends Equatable {
  final String id;
  final String category;
  final num entryFee;
  final int questionCount;
  final String timeLabel;
  final int playersWaiting;
  final bool isLive;

  const LiveCompetition({
    required this.id,
    required this.category,
    required this.entryFee,
    required this.questionCount,
    required this.timeLabel,
    required this.playersWaiting,
    required this.isLive,
  });

  @override
  List<Object?> get props => [
        id,
        category,
        entryFee,
        questionCount,
        timeLabel,
        playersWaiting,
        isLive,
      ];
}
