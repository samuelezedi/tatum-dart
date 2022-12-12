import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:tatum/src/global/helpers/connectivity_helper.dart';
import 'package:tatum/src/global/helpers/constants.dart';
import 'package:tatum/src/global/helpers/get_device_info.dart';
import 'package:tatum/src/global/interceptor/combining_smart_interceptor.dart';
import 'package:tatum/src/global/interceptor/network_auth_interceptor.dart';
import 'package:tatum/src/global/interceptor/network_error_interceptor.dart';
import 'package:tatum/src/global/interceptor/network_log_interceptor.dart';
import 'package:tatum/src/global/interceptor/network_refresh_interceptor.dart';
import 'package:tatum/src/services/algorand/tatum_algorand_api.dart';
import 'package:tatum/src/services/bitcoin/tatum_bitcoin_api.dart';
import 'injectible.config.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
Future<void> configureDependencies() async {
  // ignore: avoid_print
  print('all ready');
  await $initGetIt(getIt, environment: 'dev');
  await getIt.allReady();
}

@module
abstract class RegisterModule {
  @singleton
  Future<Json> initDeviceInformation() async {
    final deviceInfo = await GetDeviceInfo.initPlatformState();
    return deviceInfo;
  }

  @singleton
  ConnectivityHelper connectivityHelper() => ConnectivityHelper();

  @singleton
  CombiningSmartInterceptor provideCombiningSmartInterceptor(
    NetworkLogInterceptor logInterceptor,
    NetworkAuthInterceptor authInterceptor,
    NetworkErrorInterceptor errorInterceptor,
    NetworkRefreshInterceptor refreshInterceptor,
  ) =>
      CombiningSmartInterceptor()
        ..addInterceptor(authInterceptor)
        ..addInterceptor(refreshInterceptor)
        ..addInterceptor(errorInterceptor)
        ..addInterceptor(logInterceptor);

  @singleton
  Dio provideDio(CombiningSmartInterceptor interceptor) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Constants.BASE_URL,
        followRedirects: false,
        validateStatus: (status) {
          return status! >= 200 && status < 300 ||
              status == 304 ||
              status == 422 ||
              status == 401;
        },
      ),
    );
    // ignore: avoid_as
    (dio.transformer as DefaultTransformer).jsonDecodeCallback = parseJson;
    dio.interceptors
      ..add(interceptor)
      ..add(
        kDebugMode
            ? PrettyDioLogger(
                requestHeader: true,
                requestBody: true,
                responseBody: false,
                responseHeader: false,
                error: true,
                compact: true,
                maxWidth: 1000,
              )
            : PrettyDioLogger(
                requestHeader: false,
                requestBody: false,
                responseBody: false,
                responseHeader: false,
                error: false,
                compact: false,
                maxWidth: 1000,
              ),
      );
    // ..add(getIt<CacheInterceptor>());
    return dio;
  }

  @singleton
  BitcoinAPI bitcoinAPI() =>
      BitcoinAPI(provideDio(CombiningSmartInterceptor()));

  @singleton
  AlgorandAPI algorandAPI() => AlgorandAPI(provideDio(CombiningSmartInterceptor()));
}

dynamic _parseAndDecode(String response) => jsonDecode(response);

dynamic parseJson(String text) =>
    compute<String, dynamic>(_parseAndDecode, text);