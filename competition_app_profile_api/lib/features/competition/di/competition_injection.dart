import 'package:get_it/get_it.dart';

import '../data/datasources/category_remote_data_source.dart';
import '../data/datasources/competition_details_remote_data_source.dart';
import '../data/datasources/competition_remote_data_source.dart';
import '../data/datasources/feedback_remote_data_source.dart';
import '../data/datasources/leaderboard_remote_data_source.dart';
import '../data/datasources/live_competition_remote_data_source.dart';
import '../data/datasources/quiz_remote_data_source.dart';
import '../data/repositories/category_repository_impl.dart';
import '../data/repositories/competition_details_repository_impl.dart';
import '../data/repositories/competition_repository_impl.dart';
import '../data/repositories/feedback_repository_impl.dart';
import '../data/repositories/leaderboard_repository_impl.dart';
import '../data/repositories/live_competition_repository_impl.dart';
import '../data/repositories/quiz_repository_impl.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/competition_details_repository.dart';
import '../domain/repositories/competition_repository.dart';
import '../domain/repositories/feedback_repository.dart';
import '../domain/repositories/leaderboard_repository.dart';
import '../domain/repositories/live_competition_repository.dart';
import '../domain/repositories/quiz_repository.dart';
import '../domain/usecases/create_competition.dart';
import '../domain/usecases/delete_competition.dart';
import '../domain/usecases/get_categories.dart';
import '../domain/usecases/get_competition_details.dart';
import '../domain/usecases/get_competitions.dart';
import '../domain/usecases/get_leaderboard.dart';
import '../domain/usecases/get_live_competitions.dart';
import '../domain/usecases/get_match_result.dart';
import '../domain/usecases/get_quiz_questions.dart';
import '../domain/usecases/set_competition_status.dart';
import '../domain/usecases/submit_answer.dart';
import '../domain/usecases/submit_winner_feedback.dart';
import '../domain/usecases/update_competition.dart';

/// Everything the `competition` feature needs, registered in one place.
/// Assumes core dependencies (DioClient, NetworkInfo) are already
/// registered — call `registerCoreDependencies(sl)` first.
///
/// get_it still owns data/domain wiring (data sources, repository, use
/// cases) since those are singletons with no widget-tree lifecycle.
/// Presentation-layer state lives in Riverpod instead (see
/// `presentation/providers/competition_notifier.dart`), which reads its
/// use cases straight out of `sl` — nothing here needs to change for that.
///
/// `category` rides along in this same feature (see `Category`'s doc
/// comment for why) rather than getting its own `<feature>/di/` file.
///
/// Adding a new feature means adding a sibling `<feature>/di/<feature>_injection.dart`
/// with the same shape; nothing here needs to change.
void registerCompetitionDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<CompetitionRemoteDataSource>(
    () => CompetitionRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<LiveCompetitionRemoteDataSource>(
    () => LiveCompetitionRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CompetitionDetailsRemoteDataSource>(
    () => CompetitionDetailsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<QuizRemoteDataSource>(
    () => QuizRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<FeedbackRemoteDataSource>(
    () => FeedbackRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<LeaderboardRemoteDataSource>(
    () => LeaderboardRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<CompetitionRepository>(
    () => CompetitionRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<LiveCompetitionRepository>(
    () => LiveCompetitionRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<CompetitionDetailsRepository>(
    () => CompetitionDetailsRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<FeedbackRepository>(
    () => FeedbackRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCompetitions(sl()));
  sl.registerLazySingleton(() => CreateCompetition(sl()));
  sl.registerLazySingleton(() => UpdateCompetition(sl()));
  sl.registerLazySingleton(() => SetCompetitionStatus(sl()));
  sl.registerLazySingleton(() => DeleteCompetition(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetLiveCompetitions(sl()));
  sl.registerLazySingleton(() => GetCompetitionDetails(sl()));
  sl.registerLazySingleton(() => GetQuizQuestions(sl()));
  sl.registerLazySingleton(() => SubmitAnswer(sl()));
  sl.registerLazySingleton(() => GetMatchResult(sl()));
  sl.registerLazySingleton(() => SubmitWinnerFeedback(sl()));
  sl.registerLazySingleton(() => GetLeaderboard(sl()));
}
