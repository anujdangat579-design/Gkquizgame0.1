import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Replaces Dio's built-in `LogInterceptor` (which just calls `print`) so
/// HTTP logs go through `AppLogger` like everything else — meaning they
/// respect `EnvConfig.logLevel` and show up with the same tag/format as
/// the rest of the app's logs in DevTools/Logcat.
///
/// Never logs headers, at any level — that's where the bearer token
/// lives — and only logs bodies at debug level, since request/response
/// payloads can contain user data that shouldn't sit in an info-level
/// log on a shared device.
class AppLoggingInterceptor extends Interceptor {
  static const _tag = 'HTTP';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('--> ${options.method} ${options.uri}', tag: _tag);
    if (options.data != null) {
      AppLogger.debug('--> body: ${options.data}', tag: _tag);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      '<-- ${response.statusCode} ${response.requestOptions.uri}',
      tag: _tag,
    );
    if (response.data != null) {
      AppLogger.debug('<-- body: ${response.data}', tag: _tag);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '${err.requestOptions.method} ${err.requestOptions.uri} failed: ${err.message}',
      tag: _tag,
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}
