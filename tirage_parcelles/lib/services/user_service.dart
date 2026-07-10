// lib/services/user_service.dart
import '../models/player_model.dart';
import '../core/app_state.dart';
import 'api_client.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  Future<PlayerModel> getMe() async {
    final res    = await api.get('/users/me');
    final player = PlayerModel.fromJson(res['user'] as Map<String, dynamic>);
    appState.setUser(player);
    return player;
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await api.get('/users/me/stats');
    return res['stats'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getParrainages() async {
    final res = await api.get('/users/me/parrainages');
    return (res['parrainages'] as List).cast<Map<String, dynamic>>();
  }

  Future<PlayerModel> updateProfile(Map<String, dynamic> fields) async {
    final res    = await api.put('/users/me', fields);
    final player = PlayerModel.fromJson(res['user'] as Map<String, dynamic>);
    appState.setUser(player);
    return player;
  }
}

final userService = UserService.instance;
