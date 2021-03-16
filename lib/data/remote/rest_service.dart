import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_base_architecture/exception/base_error.dart';

class RESTService {
  static const int GET = 1;
  static const int POST = 2;
  static const int PUT = 3;
  static const int DELETE = 4;
  static const int FORM_DATA = 5;
  static const int URI = 6;
  static const int PATCH = 7;
  static const int PATCH_URI = 8;
  static const int PATCH_FORM_DATA = 9;
  static const int POST_QUERY = 10;
  static const int DELETE_URI = 11;
  static const String DATA = "DATA";
  static const String API_URL = "API_URL";
  static const String EXTRA_FORCE_REFRESH = "EXTRA_FORCE_REFRESH";
  static const String EXTRA_HTTP_VERB = "EXTRA_HTTP_VERB";
  static const String REST_API_CALL_IDENTIFIER = "REST_API_CALL_IDENTIFIER";
  static const String EXTRA_PARAMS = "EXTRA_PARAMS";
  DioCacheManager _dioCacheManager;

  Future<Response> onHandleIntent(Map<String, dynamic> params) async {
    dynamic action = params.putIfAbsent(DATA, () {});

    int verb = params.putIfAbsent(EXTRA_HTTP_VERB, () {
      return GET;
    });

    String apiUrl = params.putIfAbsent(API_URL, () {
      return "";
    });

    bool forceRefresh = params.putIfAbsent(EXTRA_FORCE_REFRESH, () {
      return false;
    });

    int apiCallIdentifier = params.putIfAbsent(REST_API_CALL_IDENTIFIER, () {
      return -1;
    });

    Map<String, dynamic> parameters = params.putIfAbsent(EXTRA_PARAMS, () {
      return null;
    });

    try {
      Dio request = Dio();
      _dioCacheManager ??= DioCacheManager(CacheConfig(baseUrl: apiUrl));
      request.interceptors
        ..add(_dioCacheManager.interceptor)
        ..add(InterceptorsWrapper(onError: (DioError e) async {
          if (e.response != null) {
            print(e.response.data);
            print(e.response.headers);
            print(e.response.request);

            return parseErrorResponse(e, apiCallIdentifier);
          } else {
            // Something happened in setting up or sending the request that triggered an Error
            print(e.request);
            print(e.message);
            return parseErrorResponse(e, apiCallIdentifier);
          }
        }, onResponse: (response) {
          response.headers
              .add("apiCallIdentifier", apiCallIdentifier.toString());
          response.extra.update("apiCallIdentifier", (value) => value,
              ifAbsent: () => apiCallIdentifier);
          response.extra
              .update("cached", (value) => false, ifAbsent: () => false);
        }));
      request.options.headers['apiCallIdentifier'] = apiCallIdentifier;
      request.options.extra.update("apiCallIdentifier", (value) => value,
          ifAbsent: () => apiCallIdentifier);
      if (getHeaders() != null) {
        getHeaders().forEach((key, value) {
          request.options.headers[key] = value;
        });
      }
      if (!kIsWeb) {
        if (forceRefresh) {
          request.options.extra
              .update("cached", (value) => value, ifAbsent: () => false);
        } else {
          request.options.extra.addAll(
              buildCacheOptions(Duration(days: 1), forceRefresh: forceRefresh)
                  .extra);
          request.options.extra
              .update("cached", (value) => value, ifAbsent: () => true);
        }
      } else {
        request.options.extra
            .update("cached", (value) => value, ifAbsent: () => false);
      }
      request.interceptors.add(LogInterceptor(responseBody: false));

      print("REQUEST PARAMETERS:::\n ${jsonEncode(parameters)}");

      switch (verb) {
        case RESTService.GET:
          Future<Response> response = request.get(action,
              queryParameters: attachUriWithQuery(parameters));
          return parseResponse(response, apiCallIdentifier);

        case RESTService.URI:
          Uri uri = action as Uri;
          Future<Response> response = request.getUri(Uri(
              scheme: uri.scheme,
              host: uri.host,
              path: uri.path,
              queryParameters: attachUriWithQuery(parameters)));
          return parseResponse(response, apiCallIdentifier);

        case RESTService.POST:
          Future<Response> response = request.post(action, data: parameters);
          return parseResponse(response, apiCallIdentifier);

        case RESTService.FORM_DATA:
          FormData formData = FormData.fromMap(parameters);
          Future<Response> response = request.post(action, data: formData);
          return parseResponse(response, apiCallIdentifier);

        case RESTService.PUT:
          Future<Response> response =
              request.put(action, data: paramsToJson(parameters));
          return parseResponse(response, apiCallIdentifier);
          break;

        case RESTService.DELETE:
          Future<Response> response =
              request.delete(action, data: paramsToJson(parameters));
          return parseResponse(response, apiCallIdentifier);
          break;

        case RESTService.PATCH:
          Future<Response> response = request.patch(action, data: parameters);
          return parseResponse(response, apiCallIdentifier);
          break;

        case RESTService.PATCH_URI:
          Uri uri = Uri.parse(action);
          Future<Response> response = request.patchUri(Uri(
              scheme: uri.scheme,
              port: uri.port,
              host: uri.host,
              path: uri.path,
              queryParameters: attachUriWithQuery(parameters)));
          return parseResponse(response, apiCallIdentifier);
          break;

        case RESTService.DELETE_URI:
          Uri uri = Uri.parse(action);
          Future<Response> response = request.deleteUri(Uri(
              scheme: uri.scheme,
              port: uri.port,
              host: uri.host,
              path: uri.path,
              queryParameters: attachUriWithQuery(parameters)));
          return parseResponse(response, apiCallIdentifier);
          break;

        case RESTService.PATCH_FORM_DATA:
          FormData formData = FormData.fromMap(parameters);
          Future<Response> response = request.patch(action, data: formData);
          return parseResponse(response, apiCallIdentifier);
          break;

        case RESTService.POST_QUERY:
          Future<Response> response = request.post(action,
              queryParameters: attachUriWithQuery(parameters));
          return parseResponse(response, apiCallIdentifier);

        default:
          throw DioError(
            response: Response(headers: Headers()),
          );
      }
    } catch (error, stacktrace) {
      print("Exception occurred: $error stackTrace: $stacktrace");
      return parseErrorResponse(error, apiCallIdentifier);
    }
  }

  Future<bool> clearNetworkCache() {
    if (_dioCacheManager != null) return _dioCacheManager.clearAll();
    return Future.value(false);
  }

  BaseError _handleError(Exception error) {
    BaseError amerError = BaseError();

    if (error is DioError) {
      switch (error.type) {
        case DioErrorType.CANCEL:
          amerError.type = BaseErrorType.DEFAULT;
          amerError.message = "Request to API server was cancelled";
          break;
        case DioErrorType.CONNECT_TIMEOUT:
          amerError.type = BaseErrorType.SERVER_TIMEOUT;
          amerError.message = "Connection timeout with API server";
          break;
        case DioErrorType.DEFAULT:
          amerError.type = BaseErrorType.DEFAULT;
          amerError.message =
              "Connection to API server failed due to internet connection";
          break;
        case DioErrorType.RECEIVE_TIMEOUT:
          amerError.type = BaseErrorType.SERVER_TIMEOUT;
          amerError.message = "Receive timeout in connection with API server";
          break;
        case DioErrorType.RESPONSE:
          amerError.type = BaseErrorType.INVALID_RESPONSE;
          amerError.message =
              "Received invalid status code: ${error.response.statusCode}";
          break;
        case DioErrorType.SEND_TIMEOUT:
          amerError.type = BaseErrorType.SERVER_TIMEOUT;
          amerError.message = "Receive timeout exception";
          break;
      }
    } else {
      amerError.type = BaseErrorType.UNEXPECTED;
      amerError.message = "Unexpected error occurred";
    }
    return amerError;
  }

  paramsToJson(Map<String, dynamic> params) {
    return json.encode(params);
  }

  Future<Response> parseErrorResponse(
      Exception exception, apiCallIdentifier) async {
    return await Future<Response>(() {
      Response response;

      if (exception is DioError) {
        if (exception.response != null) {
          response = exception.response;
        } else {
          response = Response(headers: Headers());
        }
      } else {
        response = Response(headers: Headers());
      }
      //response.data = null;
      response.headers.set("apiCallIdentifier", apiCallIdentifier.toString());

      //response.statusMessage = _handleError(exception);
      response.extra = Map();
      response.extra.putIfAbsent("exception", () => _handleError(exception));
      response.extra.update("apiCallIdentifier", (value) => value,
          ifAbsent: () => apiCallIdentifier);
      response.extra.update("cached", (value) => false, ifAbsent: () => false);
      return response;
    });
  }

  Future<Response> parseResponse(
      Future<Response> response, apiCallIdentifier) async {
    return await response;
  }

  Map<String, dynamic> attachUriWithQuery(Map<String, dynamic> parameters) {
    return parameters;
  }

  Map<String, dynamic> getHeaders() {
    return null;
  }
}
