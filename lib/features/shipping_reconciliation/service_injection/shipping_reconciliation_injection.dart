import 'package:get_it/get_it.dart';
import '../data/repositories/shipping_reconciliation_repository_impl.dart';
import '../domain/repositories/shipping_reconciliation_repository.dart';
import '../presentation/cubit/shipping_reconciliation_cubit.dart';

class ShippingReconciliationInjection {
  ShippingReconciliationInjection._();

  static void init(GetIt sl) {
    // Repository
    if (!sl.isRegistered<ShippingReconciliationRepository>()) {
      sl.registerLazySingleton<ShippingReconciliationRepository>(
        () => ShippingReconciliationRepositoryImpl(),
      );
    }

    // Cubit
    if (!sl.isRegistered<ShippingReconciliationCubit>()) {
      sl.registerFactory<ShippingReconciliationCubit>(
        () => ShippingReconciliationCubit(repository: sl()),
      );
    }
  }
}
