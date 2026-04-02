import '../../../../core/dio_client/dio_client.dart';
import '../../../../core/dio_client/endpoints.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../models/get_categories_model.dart';

abstract class GetCategoriesBaseRemoteDataSource {
  Future<GetCategoriesResponseModel> GetCategories({
    required GetCategoriesParameters parameters,
  });
}


class GetCategoriesRemoteDataSource
    extends GetCategoriesBaseRemoteDataSource {

  final DioClient dio;
GetCategoriesRemoteDataSource(this.dio);
  @override
  Future<GetCategoriesResponseModel> GetCategories({
    required GetCategoriesParameters parameters,
  }) async {
  
       final response = await dio.get(
      Endpoint.getCategoriesEndpoint,
      //      "${Endpoint.getCategoriesEndpoint}/${parameters.productId}",



    );
     return GetCategoriesResponseModel.fromJson(response.data);  
   

 
  }
}

