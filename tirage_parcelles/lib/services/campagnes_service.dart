// lib/services/campagnes_service.dart
import 'api_client.dart';

final campagnesService = CampagnesService();

class CampagnesService {
  ApiClient get apiClient => ApiClient.instance;

  /// URL de base pour construire les URLs d'images (sans /api).
  String get mediaBaseUrl => apiClient.baseUrl.replaceAll('/api', '');

  /// Récupère toutes les campagnes actives.
  Future<List<Map<String, dynamic>>> getCampagnes({bool activeOnly = true}) async {
    final data = await apiClient.get(
      '/campagnes?active_only=${activeOnly ? 'true' : 'false'}',
    );
    return List<Map<String, dynamic>>.from(data['campagnes'] ?? []);
  }

  /// Récupère les détails d'une campagne avec ses participants.
  Future<Map<String, dynamic>> getCampagneDetail(String id, {int page = 1}) async {
    return await apiClient.get('/campagnes/$id?page=$page&limit=20');
  }

  /// Souscrit à une campagne (débite le solde).
  Future<Map<String, dynamic>> souscrire(String campagneId) async {
    return await apiClient.post('/campagnes/$campagneId/souscrire', {});
  }
}
