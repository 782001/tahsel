import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tahsel/core/services/translation_helper.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class ServerException implements Exception {
  ServerException({this.message, this.statusCode});

  ServerException.fromDioException(Object exception, {BuildContext? context}) {
    if (exception is DioException) {
      message = switch (exception.type) {
        DioExceptionType.cancel => "",
        DioExceptionType.connectionTimeout => Loc.tr(
          context!,
          "connectionTimeout",
        ),
        DioExceptionType.sendTimeout => Loc.tr(context!, "sendTimeout"),
        DioExceptionType.receiveTimeout => Loc.tr(context!, "receiveTimeout"),
        DioExceptionType.badResponse => _handleError(
          exception.response,
          context,
        ),
        _ => exception.message.toString(),
      };

      if (exception.type == DioExceptionType.unknown) {
        statusCode = 522;
        message = Loc.tr(context!, "noInternetConnection");
      }
      if (statusCode == 301 || statusCode == 302) {
        showfailureToast(Loc.tr(context!, "pleaseCheckYourUrl"));
      }
    } else {
      message = Loc.tr(context!, "unexpectedError");
    }
  }

  String? message = "unexpectedError";
  int? statusCode;

  String _handleError(Response<dynamic>? response, BuildContext? context) {
    statusCode = response?.statusCode;

    final responseData = response?.data;
    final bodyCode = (responseData is Map<String, dynamic>)
        ? responseData['code']
        : null;

    if (statusCode == 401 || bodyCode == 401 || statusCode == 404) {
      if (context != null) {
        showfailureToast(Loc.tr(context, "sessionExpired"));
      }
      return Loc.tr(context!, "sessionExpired");
    }

    if (statusCode == 400 &&
        responseData is Map<String, dynamic> &&
        responseData.containsKey('message')) {
      if (context != null) {
        showfailureToast(responseData['message']);
      }
      return responseData['message'];
    }

    if (statusCode == 422 &&
        responseData is Map<String, dynamic> &&
        responseData.containsKey('message')) {
      showfailureToast(responseData['message']);
      return responseData['message'];
    }

    return switch (statusCode) {
      404 => Loc.tr(context!, "resourceNotFound"),
      500 => Loc.tr(context!, "internalServerError"),
      _ => Loc.tr(context!, "unexpectedError"),
    };
  }

  @override
  String toString() => message!;
}
