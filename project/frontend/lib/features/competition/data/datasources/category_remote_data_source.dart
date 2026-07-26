import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/category_model.dart';

/// Talks directly to `/api/admin/categories`. Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures.
abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final DioClient client;

  CategoryRemoteDataSourceImpl(this.client);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await client.get(ApiConstants.categories);
    return CategoryModel.listFromJson(response.data);
  }
}
