// lib/services/tirage_service.dart
import '../models/gift_model.dart';
import '../core/app_state.dart';
import 'api_client.dart';

class TirageResult {
  final String   id;
  final bool     isWinner;
  final bool     isConverted;
  final int      valeurGagnee;
  final String   mode;
  final GiftModel cadeau;
  final int      tentativesRestantes;
  final int      solde;  // ✅ solde après débit

  const TirageResult({
    required this.id,
    required this.isWinner,
    required this.isConverted,
    required this.valeurGagnee,
    required this.mode,
    required this.cadeau,
    required this.tentativesRestantes,
    required this.solde,
  });

  factory TirageResult.fromJson(Map<String, dynamic> json) {
    final tirageMap = json['tirage'] as Map<String, dynamic>;
    final cadeauMap = json['cadeau'] as Map<String, dynamic>;

    final adaptedCadeau = {
      'id':          cadeauMap['id'],
      'nom':         cadeauMap['nom'],
      'description': cadeauMap['description'],
      'icon':        cadeauMap['icon'] ?? '🎁',
      'prix_reel':   cadeauMap['prix_reel'] ?? 0,
      'categorie':   cadeauMap['categorie'] ?? 'aucun',
      'is_winner':   cadeauMap['is_winner'] ?? false,
      'is_loser':    cadeauMap['is_loser'] ?? true,
      'quantite':    1,
    };

    return TirageResult(
      id:                  tirageMap['id']            as String,
      isWinner:            tirageMap['is_winner']     as bool,
      isConverted:         (tirageMap['is_converted'] as bool?) ?? false,
      valeurGagnee:        tirageMap['valeur_gagnee'] as int,
      mode:                tirageMap['mode']          as String,
      cadeau:              GiftModel.fromJson(adaptedCadeau),
      tentativesRestantes: json['tentatives_restantes'] as int,
      solde:               json['solde'] as int,  // ✅
    );
  }
}

class TirageService {
  TirageService._();
  static final TirageService instance = TirageService._();

  Future<TirageResult> jouer({
    required String lotId,
    String mode = 'boites',
  }) async {
    final res = await api.post('/tirages', {
      'lot_id': lotId,
      'mode':   mode,
    });
    final result = TirageResult.fromJson(res);

    // ✅ Mettre à jour tentatives ET solde dans le state global
    appState.updateTentatives(result.tentativesRestantes);
    appState.updateSolde(result.solde);

    return result;
  }

  Future<Map<String, dynamic>> getHistorique({
    int page = 1, int limit = 20, String? filter,
  }) async {
    final params = ['page=$page', 'limit=$limit'];
    if (filter != null) params.add('filter=$filter');
    return api.get('/tirages?${params.join('&')}');
  }

  Future<Map<String, dynamic>> convertirGain({required String tirageId}) async {
    final res = await api.post('/tirages/$tirageId/convertir', {});
    if (res.containsKey('credit_converti')) {
      final creditConverti = res['credit_converti'] as int;
      appState.updateCreditConverti(creditConverti);
    }
    return res;
  }

  Future<Map<String, dynamic>> getGains() async =>
      api.get('/tirages/gains');
}

final tirageService = TirageService.instance;