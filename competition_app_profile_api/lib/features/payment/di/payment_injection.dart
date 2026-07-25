import 'package:get_it/get_it.dart';

import '../data/datasources/payment_remote_data_source.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../data/services/cashfree_checkout_service.dart';
import '../domain/repositories/payment_repository.dart';
import '../domain/usecases/create_payment_order.dart';
import '../domain/usecases/verify_payment.dart';

/// Everything the `payment` feature needs, registered in one place.
/// Assumes core dependencies (DioClient, NetworkInfo) are already
/// registered — call `registerCoreDependencies(sl)` first. Same shape
/// as `registerCompetitionDependencies`.
///
/// `CashfreeCheckoutService` rides along here too, even though it wraps
/// a platform SDK rather than an HTTP data source — it plays the same
/// "infrastructure the presentation layer shouldn't construct itself"
/// role as `DioClient`, so it gets a lazy singleton like everything
/// else here instead of being instantiated ad hoc in the notifier.
void registerPaymentDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(sl()),
  );

  // Services
  sl.registerLazySingleton<CashfreeCheckoutService>(
    () => CashfreeCheckoutService(),
  );

  // Repositories
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CreatePaymentOrder(sl()));
  sl.registerLazySingleton(() => VerifyPayment(sl()));
}
