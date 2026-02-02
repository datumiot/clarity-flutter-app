import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            final refreshed = await _refreshTokens();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            }
          } catch (_) {}
        }
        handler.next(error);
      },
    ));
  }

  Future<void> loadStoredTokens() async {
    _accessToken = await _storage.read(key: ApiConstants.accessTokenKey);
    _refreshToken = await _storage.read(key: ApiConstants.refreshTokenKey);
  }

  Future<void> storeTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
  }

  bool get hasTokens => _accessToken != null;

  Future<bool> _refreshTokens() async {
    try {
      final response = await Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {'Content-Type': 'application/json'},
      )).post('/auth/refresh', data: {'refresh_token': _refreshToken});

      final tokens = response.data;
      await storeTokens(
        tokens['access_token'] as String,
        tokens['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  // Auth
  Future<Response> login(String email, String password) =>
      dio.post('/auth/login', data: {'email': email, 'password': password});

  Future<Response> signup(Map<String, dynamic> data) =>
      dio.post('/auth/signup', data: data);

  Future<Response> logout() => dio.post('/auth/logout');

  Future<Response> getCurrentUser() => dio.get('/auth/me');

  // Collectors
  Future<Response> getCollectors() => dio.get('/collectors');

  Future<Response> getCollector(int id) => dio.get('/collectors/$id');

  Future<Response> updateCollector(int id, Map<String, dynamic> data) =>
      dio.patch('/collectors/$id', data: data);

  Future<Response> deleteCollector(int id) => dio.delete('/collectors/$id');

  // Meters
  Future<Response> getMeters(int collectorId) =>
      dio.get('/collectors/$collectorId/meters');

  Future<Response> getMeter(int meterId) => dio.get('/meters/$meterId');

  Future<Response> updateMeter(int meterId, Map<String, dynamic> data) =>
      dio.patch('/meters/$meterId', data: data);

  // Readings
  Future<Response> getMeterReadings(int meterId,
      {String? startDate, String? endDate, int? limit}) {
    final params = <String, dynamic>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (limit != null) params['limit'] = limit;
    return dio.get('/meters/$meterId/readings', queryParameters: params);
  }

  Future<Response> getLatestReading(int meterId) =>
      dio.get('/meters/$meterId/readings/latest');

  // Alerts
  Future<Response> getAlerts({bool? unreadOnly}) {
    final params = <String, dynamic>{};
    if (unreadOnly != null) params['unread_only'] = unreadOnly;
    return dio.get('/alerts', queryParameters: params);
  }

  Future<Response> markAlertRead(int alertId) =>
      dio.patch('/alerts/$alertId/read');

  Future<Response> markAllAlertsRead() => dio.post('/alerts/read-all');

  // Diagnostics
  Future<Response> getCollectorDiagnostics(int collectorId) =>
      dio.get('/collectors/$collectorId/diagnostics');

  Future<Response> getCollectorLogs(int collectorId, {int? limit}) {
    final params = <String, dynamic>{};
    if (limit != null) params['limit'] = limit;
    return dio.get('/collectors/$collectorId/logs', queryParameters: params);
  }

  // FCM Token
  Future<Response> registerFcmToken(String token, Map<String, dynamic> deviceInfo) =>
      dio.post('/users/devices', data: {'fcm_token': token, ...deviceInfo});
}
