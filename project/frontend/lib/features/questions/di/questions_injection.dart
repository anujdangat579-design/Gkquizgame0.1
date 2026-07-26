import 'package:get_it/get_it.dart';

import '../data/datasources/question_remote_data_source.dart';
import '../data/repositories/question_repository_impl.dart';
import '../domain/repositories/question_repository.dart';
import '../domain/usecases/create_question.dart';
import '../domain/usecases/delete_question.dart';
import '../domain/usecases/get_question_by_id.dart';
import '../domain/usecases/get_questions.dart';
import '../domain/usecases/update_question.dart';

/// Everything the `questions` feature (the admin question bank) needs,
/// registered in one place. Assumes core dependencies (DioClient,
/// NetworkInfo) are already registered — call `registerCoreDependencies(sl)`
/// first. Same shape as `registerCompetitionDependencies`.
void registerQuestionsDependencies(GetIt sl) {
  // Data source
  sl.registerLazySingleton<QuestionRemoteDataSource>(
    () => QuestionRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<QuestionRepository>(
    () => QuestionRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetQuestions(sl()));
  sl.registerLazySingleton(() => GetQuestionById(sl()));
  sl.registerLazySingleton(() => CreateQuestion(sl()));
  sl.registerLazySingleton(() => UpdateQuestion(sl()));
  sl.registerLazySingleton(() => DeleteQuestion(sl()));
}
