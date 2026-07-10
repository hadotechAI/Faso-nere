// lib/core/app_state.dart
import 'package:flutter/foundation.dart';
import '../models/player_model.dart';
import '../services/api_client.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  PlayerModel? _user;
  bool _loading = false;
  bool _isDarkMode = true;
  bool _hideBalance = false;

  PlayerModel? get user       => _user;
  bool         get loading    => _loading;
  bool         get isLoggedIn => _user != null;
  bool         get isDarkMode => _isDarkMode;
  bool         get hideBalance => _hideBalance;
  
  bool _isTouristMode = false;
  bool get isTouristMode => _isTouristMode;

  void toggleTouristMode() {
    _isTouristMode = !_isTouristMode;
    notifyListeners();
  }

  String formatMoney(int? v) {
    if (v == null) return isTouristMode ? '0 F (~0 € / ~0 \$)' : '0 F';
    final base = v.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    if (_isTouristMode) {
      final eur = (v / 655.957).toStringAsFixed(2);
      final usd = (v / 600.0).toStringAsFixed(2);
      return '$base F (~$eur € / ~$usd \$)';
    }
    return '$base F';
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleHideBalance() {
    _hideBalance = !_hideBalance;
    notifyListeners();
  }

  void setUser(PlayerModel user) {
    _user = user;
    notifyListeners();
  }

  void updateSolde(int solde) {
    if (_user == null) return;
    _user = _user!.copyWith(solde: solde);
    notifyListeners();
  }

  void updateCreditConverti(int creditConverti) {
    if (_user == null) return;
    _user = _user!.copyWith(creditConverti: creditConverti);
    notifyListeners();
  }

  void updateTentatives(int tentatives) {
    if (_user == null) return;
    _user = _user!.copyWith(tentatives: tentatives);
    notifyListeners();
  }

  void decrementTentatives() {
    if (_user == null || _user!.tentatives <= 0) return;
    _user = _user!.copyWith(tentatives: _user!.tentatives - 1);
    notifyListeners();
  }

  void incrementGagnes() {
    if (_user == null) return;
    _user = _user!.copyWith(gagnes: _user!.gagnes + 1);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout', {});
    } catch (_) {}
    await api.clearTokens();
    _user = null;
    notifyListeners();
  }

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<bool> tryRestoreSession() async {
    final hasToken = await api.isLoggedIn();
    if (!hasToken) return false;

    _loading = true;
    notifyListeners();

    try {
      final res = await api.get('/users/me');
      final player = PlayerModel.fromJson(res['user'] as Map<String, dynamic>);
      _user = player;
      _loading = false;
      notifyListeners();
      return true;
    } catch (_) {
      await api.clearTokens();
      _user = null;
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}

final appState = AppState.instance;