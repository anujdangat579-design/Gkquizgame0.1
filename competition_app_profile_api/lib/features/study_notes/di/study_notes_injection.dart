import 'package:get_it/get_it.dart';

import '../data/datasources/note_category_remote_data_source.dart';
import '../data/datasources/note_payment_remote_data_source.dart';
import '../data/datasources/note_remote_data_source.dart';
import '../data/repositories/note_category_repository_impl.dart';
import '../data/repositories/note_payment_repository_impl.dart';
import '../data/repositories/note_repository_impl.dart';
import '../domain/repositories/note_category_repository.dart';
import '../domain/repositories/note_payment_repository.dart';
import '../domain/repositories/note_repository.dart';
import '../domain/usecases/create_note_order.dart';
import '../domain/usecases/get_note_categories.dart';
import '../domain/usecases/get_note_details.dart';
import '../domain/usecases/get_notes.dart';
import '../domain/usecases/verify_note_payment.dart';

/// Everything the `study_notes` feature needs, registered in one place.
/// Assumes core dependencies (DioClient, NetworkInfo) *and*
/// `registerPaymentDependencies` are already registered - this feature's
/// buy flow reuses `CashfreeCheckoutService` from the payment feature
/// rather than registering a second instance (see `BuyNoteNotifier`'s
/// doc comment). Same shape as `registerCompetitionDependencies`.
void registerStudyNotesDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<NoteCategoryRemoteDataSource>(
    () => NoteCategoryRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NoteRemoteDataSource>(
    () => NoteRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NotePaymentRemoteDataSource>(
    () => NotePaymentRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<NoteCategoryRepository>(
    () => NoteCategoryRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<NotePaymentRepository>(
    () => NotePaymentRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNoteCategories(sl()));
  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => GetNoteDetails(sl()));
  sl.registerLazySingleton(() => CreateNoteOrder(sl()));
  sl.registerLazySingleton(() => VerifyNotePayment(sl()));
}
