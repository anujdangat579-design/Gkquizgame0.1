import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/note_category_model.dart';

/// Talks directly to `ApiConstants.noteCategories`. Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures.
abstract class NoteCategoryRemoteDataSource {
  Future<List<NoteCategoryModel>> getNoteCategories();
}

class NoteCategoryRemoteDataSourceImpl implements NoteCategoryRemoteDataSource {
  final DioClient client;

  NoteCategoryRemoteDataSourceImpl(this.client);

  @override
  Future<List<NoteCategoryModel>> getNoteCategories() async {
    final response = await client.get(ApiConstants.noteCategories);
    return NoteCategoryModel.listFromJson(response.data);
  }
}
