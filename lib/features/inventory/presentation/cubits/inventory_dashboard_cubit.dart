import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/usecases/inventory_product_usecases.dart';

abstract class InventoryDashboardState extends Equatable {
  const InventoryDashboardState();
  @override
  List<Object?> get props => [];
}

class InventoryDashboardInitial extends InventoryDashboardState {}

class InventoryDashboardLoading extends InventoryDashboardState {}

class InventoryDashboardLoaded extends InventoryDashboardState {
  final int totalProductsCount;
  final int lowStockCount;
  final double totalInventoryValue;
  final List<InventoryProductEntity> lowStockProducts;

  const InventoryDashboardLoaded({
    required this.totalProductsCount,
    required this.lowStockCount,
    required this.totalInventoryValue,
    required this.lowStockProducts,
  });

  @override
  List<Object?> get props => [
        totalProductsCount,
        lowStockCount,
        totalInventoryValue,
        lowStockProducts,
      ];
}

class InventoryDashboardError extends InventoryDashboardState {
  final String message;
  const InventoryDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class InventoryDashboardCubit extends Cubit<InventoryDashboardState> {
  final GetInventoryProductsUseCase getProductsUseCase;
  final GetLowStockProductsUseCase getLowStockProductsUseCase;

  InventoryDashboardCubit({
    required this.getProductsUseCase,
    required this.getLowStockProductsUseCase,
  }) : super(InventoryDashboardInitial());

  Future<void> loadDashboardMetrics() async {
    emit(InventoryDashboardLoading());
    final productsResult = await getProductsUseCase();
    final lowStockResult = await getLowStockProductsUseCase();

    productsResult.fold(
      (failure) => emit(InventoryDashboardError(failure.message)),
      (products) {
        lowStockResult.fold(
          (failure) => emit(InventoryDashboardError(failure.message)),
          (lowStockProducts) {
            double value = 0;
            for (final p in products) {
              value += (p.purchasePrice * p.currentQuantity);
            }
            emit(InventoryDashboardLoaded(
              totalProductsCount: products.length,
              lowStockCount: lowStockProducts.length,
              totalInventoryValue: value,
              lowStockProducts: lowStockProducts,
            ));
          },
        );
      },
    );
  }

  Future<void> loadDashboard() => loadDashboardMetrics();
}
