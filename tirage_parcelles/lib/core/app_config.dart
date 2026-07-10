// lib/core/app_config.dart

class AppConfig {
  AppConfig._();

  /// Si renseigné via --dart-define=API_URL=..., aucune détection auto.
  static const String compileTimeApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  /// IP du PC sur le Wi‑Fi (téléphone physique). Modifier si besoin :
  /// flutter run --dart-define=DEV_LAN_IP=192.168.x.x
  static const String devLanIp = String.fromEnvironment(
    'DEV_LAN_IP',
    defaultValue: '192.168.100.6',
  );

  static const int apiPort = 8080;

  /// URLs testées au démarrage (la première qui répond est utilisée).
  static List<String> get devApiCandidates => [
        'http://10.0.2.2:$apiPort/api',
        'http://$devLanIp:$apiPort/api',
      ];

  static const String env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const String productionApiUrl =
      'https://faso-nere-backend.onrender.com';

  static bool get isProduction => env == 'production';
  static bool get isDevelopment => env == 'development';

  /// URL finale selon l'environnement.
  static String get apiUrl {
    if (compileTimeApiUrl.isNotEmpty) return compileTimeApiUrl;
    if (isProduction) return productionApiUrl;
    return devApiCandidates.first;
  }
}
