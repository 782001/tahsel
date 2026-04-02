import '../../../../core/dio_client/dio_client.dart';
import '../../../../core/dio_client/endpoints.dart';
import '../../domain/usecases/get_category_by_id_usecase.dart';
import '../models/get_category_by_id_model.dart';

abstract class GetCategoryByIdBaseRemoteDataSource {
  Future<GetCategoryByIdResponseModel> GetCategoryById({
    required GetCategoryByIdParameters parameters,
  });
}


class GetCategoryByIdRemoteDataSource
    extends GetCategoryByIdBaseRemoteDataSource {

  final DioClient dio;
GetCategoryByIdRemoteDataSource(this.dio);
  @override
  Future<GetCategoryByIdResponseModel> GetCategoryById({
    required GetCategoryByIdParameters parameters,
  }) async {
  
       final response = await dio.get(
      Endpoint.getCategoryByIdEndpoint,
      //      "${Endpoint.getCategoryByIdEndpoint}/${parameters.productId}",



    );
     return GetCategoryByIdResponseModel.fromJson(response.data);  
   

 
  }
}

