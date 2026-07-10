// lib/services/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/api_url_resolver.dart';

const Duration _kRequestTimeout = Duration(seconds: 10);

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken  = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  String _baseUrl = 'http://10.0.2.2:8080/api';

  String get baseUrl => _baseUrl;

  /// Détection auto émulateur / téléphone au démarrage.
  Future<void> loadSettings({bool forceRefresh = false}) async {
    _baseUrl = await ApiUrlResolver.resolve(forceRefresh: forceRefresh);
  }

  /// Si la connexion échoue, re-teste toutes les URLs (émulateur + Wi‑Fi).
  Future<void> reconnect() async {
    await loadSettings(forceRefresh: true);
  }

  Future<String?> getAccessToken()  => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken,  value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader:      'application/json',
    };
    if (_baseUrl.contains('ngrok')) {
      headers['ngrok-skip-browser-warning'] = 'true';
    }
    if (auth) {
      final token = await getAccessToken();
      if (token != null) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }
    return headers;
  }

  bool _refreshing = false;
  Completer<bool>? _refreshCompleter;

  Future<bool> _refreshToken() async {
    if (_refreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _refreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      final refreshHeaders = <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      };
      if (_baseUrl.contains('ngrok')) {
        refreshHeaders['ngrok-skip-browser-warning'] = 'true';
      }

      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/refresh'),
            headers: refreshHeaders,
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_kRequestTimeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final newAccess  = body['access_token']  as String?;
        final newRefresh = body['refresh_token'] as String?;
        if (newAccess != null && newRefresh != null) {
          await saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      await clearTokens();
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshing = false;
      _refreshCompleter = null;
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool retryOn401 = true,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers(auth: auth);
    final bodyStr = body != null ? jsonEncode(body) : null;

    http.Response res;
    try {
      if (method == 'GET') {
        res = await http.get(url, headers: headers).timeout(_kRequestTimeout);
      } else if (method == 'POST') {
        res = await http.post(url, headers: headers, body: bodyStr).timeout(_kRequestTimeout);
      } else if (method == 'PUT') {
        res = await http.put(url, headers: headers, body: bodyStr).timeout(_kRequestTimeout);
      } else {
        throw UnsupportedError('Method not supported: $method');
      }
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Il n\'y a pas de réseau. Délai d\'attente dépassé.',
      );
    } on SocketException {
      await reconnect();
      throw ApiException(
        statusCode: 0,
        message: 'Il n\'y a pas de réseau. Veuillez vérifier votre connexion.',
      );
    } on http.ClientException catch (_) {
      throw ApiException(
        statusCode: 0,
        message: 'Il n\'y a pas de réseau. Veuillez vérifier votre connexion.',
      );
    }

    if (res.statusCode == 401 && auth && retryOn401) {
      final success = await _refreshToken();
      if (success) {
        return _request(method, path, body: body, auth: auth, retryOn401: false);
      }
    }

    return _handle(res);
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    return _request('GET', path, auth: auth);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _request('POST', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _request('PUT', path, body: body, auth: auth);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('not a map');
      }
      body = decoded;
    } catch (_) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Erreur réseau ou réponse invalide.',
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    final detail = body['detail'];
    final String message;
    if (detail is String) {
      message = detail;
    } else if (detail is List && detail.isNotEmpty) {
      message = detail.first['msg']?.toString() ?? 'Erreur de validation';
    } else {
      message = body['error']?.toString() ?? body['message']?.toString() ?? 'Erreur inconnue';
    }
    final code = body['code'] as String?;

    if (res.statusCode == 401) clearTokens();

    throw ApiException(
      statusCode: res.statusCode,
      message: message,
      code: code,
    );
  }
}

final api = ApiClient.instance;
