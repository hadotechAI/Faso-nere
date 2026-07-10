// lib/services/auth_service.dart
import '../models/player_model.dart';
import '../core/app_state.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<PlayerModel> register({
    required String nom, required String prenom,
    required String telephone, required String motDePasse,
    String? codeParrain,
  }) async {
    final res = await api.post('/auth/register', {
      'nom': nom, 'prenom': prenom,
      'telephone': telephone, 'mot_de_passe': motDePasse,
      if (codeParrain != null && codeParrain.isNotEmpty) 'code_parrain': codeParrain,
    }, auth: false);

    final accessToken = (res['access_token'] ?? res['accessToken']) as String?;
    final refreshToken = (res['refresh_token'] ?? res['refreshToken']) as String?;

    if (accessToken == null || refreshToken == null) {
      throw ApiException(
        statusCode: 500,
        message: "Les jetons d'accès n'ont pas pu être récupérés du serveur.",
      );
    }

    await api.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    final player = PlayerModel.fromJson(res['user'] as Map<String, dynamic>);
    appState.setUser(player);
    return player;
  }

  Future<PlayerModel> login({required String telephone, required String motDePasse}) async {
    final res = await api.post('/auth/login', {
      'telephone': telephone, 'mot_de_passe': motDePasse,
    }, auth: false);

    final accessToken = (res['access_token'] ?? res['accessToken']) as String?;
    final refreshToken = (res['refresh_token'] ?? res['refreshToken']) as String?;

    if (accessToken == null || refreshToken == null) {
      throw ApiException(
        statusCode: 500,
        message: "Les jetons de connexion n'ont pas pu être récupérés du serveur.",
      );
    }

    await api.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    final player = PlayerModel.fromJson(res['user'] as Map<String, dynamic>);
    appState.setUser(player);
    return player;
  }

  Future<void> logout() => appState.logout();

  Future<void> sendOtp() => api.post('/auth/otp/send', {});

  Future<bool> verifyOtp(String code) async {
    try {
      await api.post('/auth/otp/verify', {'code': code});
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<PlayerModel?> tryRestoreSession() async {
    if (!await api.isLoggedIn()) return null;
    try {
      final res    = await api.get('/users/me');
      final player = PlayerModel.fromJson(res['user'] as Map<String, dynamic>);
      appState.setUser(player);
      return player;
    } on ApiException {
      await api.clearTokens();
      return null;
    }
  }


  Future<void> forgotPassword(String telephone) async {
    await api.post('/auth/forgot-password', {
      'telephone': telephone,
    }, auth: false);
  }

  Future<void> resetPassword(String telephone, String code, String newPassword) async {
    await api.post('/auth/reset-password', {
      'telephone': telephone,
      'code': code,
      'new_password': newPassword,
    }, auth: false);
  }
}

final authService = AuthService.instance;
