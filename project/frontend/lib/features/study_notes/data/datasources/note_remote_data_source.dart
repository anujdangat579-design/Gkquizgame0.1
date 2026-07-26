import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/note_model.dart';

abstract class NoteRemoteDataSource {
  Future<NotePageModel> getNotes({
    String? categoryId,
    String? search,
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
  });

  Future<NoteModel> getNoteDetails(String id);
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final DioClient client;

  NoteRemoteDataSourceImpl(this.client);

  @override
  Future<NotePageModel> getNotes({
    String? categoryId,
    String? search,
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
  }) async {
    final response = await client.get(
      ApiConstants.notes,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return NotePageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<NoteModel> getNoteDetails(String id) async {
    final response = await client.get(ApiConstants.noteDetails(id));
    return NoteModel.fromJson(response.data as Map<String, dynamic>);
  }
}
