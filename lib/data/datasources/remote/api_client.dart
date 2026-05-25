import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:hava/core/constants/api_constants.dart';

/// Creates and configures a [Dio] instance for OpenWeatherMap.
Dio createOpenWeatherDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.openWeatherBaseUrl,
      connectTimeout: ApiConstants.requestTimeout,
      receiveTimeout: ApiConstants.requestTimeout,
      queryParameters: {
        'appid': ApiConstants.openWeatherApiKey,
        'units': ApiConstants.defaultUnits,
      },
    ),
  );
  dio.interceptors.add(_LoggingInterceptor('OpenWeather'));
  return dio;
}

/// Creates and configures a [Dio] instance for IQAir.
Dio createIqAirDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.iqAirBaseUrl,
      connectTimeout: ApiConstants.requestTimeout,
      receiveTimeout: ApiConstants.requestTimeout,
      queryParameters: {'key': ApiConstants.iqAirApiKey},
    ),
  );
  dio.interceptors.add(_LoggingInterceptor('IQAir'));
  return dio;
}

/// Lightweight interceptor that logs requests and errors in debug mode.
class _LoggingInterceptor extends Interceptor {
  _LoggingInterceptor(this._tag);
  final String _tag;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[$_tag] --> ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[$_tag] <-- ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[$_tag] ERROR [${err.type}] ${err.requestOptions.uri}: ${err.message}',
      );
    }
    handler.next(err);
  }
}
