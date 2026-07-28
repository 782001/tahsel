import 'package:dartz/dartz.dart';
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
  final FetchAllProductsFromRemoteUseCase fetchAllProductsFromRemoteUseCase;

  InventoryDashboardCubit({
    required this.getProductsUseCase,
    required this.getLowStockProductsUseCase,
    required this.fetchAllProductsFromRemoteUseCase,
  }) : super(InventoryDashboardInitial());

  Future<void> loadDashboardMetrics() async {
    emit(InventoryDashboardLoading());
    var productsResult = await getProductsUseCase();

    // If products list is empty during loadDashboard, automatically fetch all products from Firebase without limit
    await productsResult.fold(
      (failure) async {},
      (products) async {
        if (products.isEmpty) {
          final remoteAllResult = await fetchAllProductsFromRemoteUseCase();
          remoteAllResult.fold(
            (_) {},
            (allProducts) {
              productsResult = Right(allProducts);
            },
          );
        }
      },
    );

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
