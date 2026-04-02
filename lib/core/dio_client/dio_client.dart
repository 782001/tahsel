import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:tahsel/core/dio_client/api_keys.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/cashhelper.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_strings.dart';

import 'endpoints.dart';
import 'server_exception.dart';

class DioClient {
  DioClient(this._dio) {
    _dio
      ..options.baseUrl = Endpoint.apiBaseUrl
      ..options.connectTimeout = Endpoint.connectionTimeout
      ..options.receiveTimeout = Endpoint.receiveTimeout
      ..options.responseType = ResponseType.json;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers[ApiKeys.contentType] = 'application/json';
          options.headers[ApiKeys.accept] = 'application/json';
          final lang =
              sl<CashHelper>().getData(key: AppStrings.locale) ??
              AppStrings.currentLang;
          options.headers[ApiKeys.acceptLanguage] = lang;

          // Fetch token securely
          final token = await sl<SecureStorageHelper>().getData(key: 'token');
          if (token != null) {
            options.headers[ApiKeys.authorization] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
    // 🐛 Logger
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  final Dio _dio;

  String? language;

  void update(String newLanguage) {
    language = newLanguage;
    _dio.options.headers[ApiKeys.acceptLanguage] = newLanguage;
  }

  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {}),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      throw ServerException.fromDioException(e);
    }
  }

  Future<dynamic> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        url,
        data: data,
        queryParameters: queryParameters,
        options:
            options ??
            Options(
              headers: {
                ApiKeys.contentType: 'application/json',
                ApiKeys.accept: 'application/json',
              },
            ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      throw ServerException.fromDioException(e);
    }
  }

  Future<dynamic> put(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {}),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      throw ServerException.fromDioException(e);
    }
  }

  Future<dynamic> delete(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {}),
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      throw ServerException.fromDioException(e);
    }
  }
}
