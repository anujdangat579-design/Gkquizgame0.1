import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../config/env_config.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../storage/token_storage.dart';
import 'app_logging_interceptor.dart';
import 'server_clock.dart';

/// Parses the HTTP `Date` response header (RFC 7231 format, e.g. `Wed,
/// 21 Oct 2026 07:28:00 GMT`) into a UTC [DateTime]. Every HTTP server
/// sends this by default, so it doubles as a free time-sync signal (see
/// [ServerClock]) without needing a dedicated backend endpoint.
DateTime? _parseHttpDate(String? value) {
  if (value == null) return null;
  try {
    return DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parseUtc(value.replaceAll(' GMT', ''));
  } catch (_) {
    return null; // malformed/missing header — caller just skips this sync sample
  }
}

/// Thin wrapper around Dio so data sources never touch Dio directly.
/// Centralizes base URL, timeouts, auth header injection, and
/// translation of DioExceptions into our own exception types.
class DioClient {
  final Dio dio;

  DioClient._(this.dio);

  factory DioClient.create(TokenStorage tokenStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (EnvConfig.enableNetworkLogging) {
      dio.interceptors.add(AppLoggingInterceptor());
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Stamped here (rather than measured some other way) so the
          // round-trip duration ServerClock uses to correct for network
          // latency covers the exact same request/response pair the
          // `Date` header below came from.
          options.extra['requestSentAt'] = DateTime.now();
          final token = await tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _syncServerClock(response.headers.value('date'), response.requestOptions);
          handler.next(response);
        },
        onError: (error, handler) {
          // Even a failed request (4xx/5xx) still carries a `Date`
          // header from whatever server produced the error response, so
          // there's no reason to waste that sync signal just because
          // the call itself failed.
          final headers = error.response?.headers.value('date');
          if (headers != null) _syncServerClock(headers, error.requestOptions);
          handler.next(error);
        },
      ),
    );

    return DioClient._(dio);
  }

  static void _syncServerClock(String? dateHeader, RequestOptions requestOptions) {
    final serverDate = _parseHttpDate(dateHeader);
    final requestSentAt = requestOptions.extra['requestSentAt'] as DateTime?;
    if (serverDate == null || requestSentAt == null) return;
    ServerClock.instance.recordServerDate(
      serverDate,
      requestSentAt: requestSentAt,
      responseReceivedAt: DateTime.now(),
    );
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _handle(() => dio.get(path, queryParameters: queryParameters));
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) async {
    return _handle(() => dio.post(path, data: data));
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) async {
    return _handle(() => dio.patch(path, data: data));
  }

  Future<Response<dynamic>> delete(String path) async {
    return _handle(() => dio.delete(path));
  }

  Future<Response<dynamic>> _handle(Future<Response<dynamic>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      }
      final statusCode = e.response?.statusCode;
      final message = _extractMessage(e.response?.data) ?? e.message ?? 'Server error';
      if (statusCode == 401 || statusCode == 403) {
        throw UnauthorizedException(message);
      }
      if (statusCode == 422 || statusCode == 400) {
        throw ValidationException(message);
      }
      throw ServerException(message: message, statusCode: statusCode);
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return null;
  }
}
