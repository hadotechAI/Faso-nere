// lib/core/api_url_resolver.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
const _keyLastWorking = 'api_last_working_url';
const _probeTimeout = Duration(seconds: 6);

/// Détecte automatiquement l'URL API (émulateur ou téléphone sur le même Wi‑Fi).
class ApiUrlResolver {
  ApiUrlResolver._();

  static Future<String> resolve({bool forceRefresh = false}) async {
    if (AppConfig.compileTimeApiUrl.isNotEmpty) {
      return AppConfig.compileTimeApiUrl;
    }

    // En production → URL Render directement, sans détection
    if (AppConfig.isProduction) {
      if (kDebugMode) print('🚀 Production : ${AppConfig.productionApiUrl}');
      return AppConfig.productionApiUrl;
    }

    if (!forceRefresh) {
      final cached = await _storage.read(key: _keyLastWorking);
      if (cached != null && await _isReachable(cached)) {
        if (kDebugMode) print('✅ API (cache) : $cached');
        return cached;
      }
      if (cached != null) {
        await _storage.delete(key: _keyLastWorking);
      }
    }

    final candidates = AppConfig.devApiCandidates;
    for (final url in candidates) {
      if (await _isReachable(url)) {
        await _storage.write(key: _keyLastWorking, value: url);
        if (kDebugMode) print('✅ API trouvée : $url');
        return url;
      }
      if (kDebugMode) print('❌ Injoignable : $url');
    }

    if (kDebugMode) {
      print(
        '⚠️ Aucun serveur sur le port ${AppConfig.apiPort}. '
        'Lancez : cd faso-nere-backend && npm run dev',
      );
    }
    return candidates.first;
  }

  static Future<bool> _isReachable(String apiBaseUrl) async {
    final health = '${apiBaseUrl.replaceAll(RegExp(r'/api$'), '')}/health';
    try {
      final headers = <String, String>{
        HttpHeaders.acceptHeader: 'application/json',
      };
      if (apiBaseUrl.contains('ngrok')) {
        headers['ngrok-skip-browser-warning'] = 'true';
      }
      final client = http.Client();
      try {
        final res = await client
            .get(Uri.parse(health), headers: headers)
            .timeout(_probeTimeout);
        return res.statusCode == 200;
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) print('   → $e');
      return false;
    }
  }
}
