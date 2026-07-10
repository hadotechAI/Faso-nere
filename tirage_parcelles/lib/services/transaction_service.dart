// lib/services/transaction_service.dart
import '../core/app_state.dart';
import 'api_client.dart';

class TransactionService {
  TransactionService._();
  static final TransactionService instance = TransactionService._();

  // ── PawaPay (encaissements) ───────────────────────────────────
  Future<Map<String, dynamic>> initierDepotPawaPay({
    required int montant,
    required String methode,
    String? telephonePaiement,
    String? preAuthCode,
  }) async {
    return api.post('/transactions/pawapay/depot/initier', {
      'montant': montant,
      'methode': methode,
      if (telephonePaiement != null) 'telephone_paiement': telephonePaiement,
      if (preAuthCode != null) 'pre_auth_code': preAuthCode,
    });
  }

  Future<Map<String, dynamic>> initierPackPawaPay({
    required String packId,
    required String methode,
    String? telephonePaiement,
    String? preAuthCode,
  }) async {
    return api.post('/transactions/pawapay/pack/initier', {
      'pack_id': packId,
      'methode': methode,
      if (telephonePaiement != null) 'telephone_paiement': telephonePaiement,
      if (preAuthCode != null) 'pre_auth_code': preAuthCode,
    });
  }

  Future<Map<String, dynamic>> initierSouscriptionPawaPay({
    required String campagneId,
    required String methode,
    String? telephonePaiement,
    String? preAuthCode,
  }) async {
    return api.post('/transactions/pawapay/souscription/initier', {
      'campagne_id': campagneId,
      'methode': methode,
      if (telephonePaiement != null) 'telephone_paiement': telephonePaiement,
      if (preAuthCode != null) 'pre_auth_code': preAuthCode,
    });
  }

  Future<Map<String, dynamic>> statutPawaPay(String reference) async {
    return api.get('/transactions/pawapay/statut/$reference');
  }

  Future<Map<String, dynamic>> getPawaPayConfig() async {
    return api.get('/transactions/pawapay/config');
  }

  // ── Dépôt (OTP — legacy) ───────────────────────────────────────
  Future<Map<String, dynamic>> initierDepot({required int montant, required String methode}) async {
    return api.post('/transactions/depot/initier', {'montant': montant, 'methode': methode});
  }

  Future<int> confirmerDepot({
    required int montant, required String methode,
    required String otpCode, String? telephonePaiement,
  }) async {
    final res = await api.post('/transactions/depot/confirmer', {
      'montant': montant, 'methode': methode,
      'otp_code': otpCode,
      if (telephonePaiement != null) 'telephone_paiement': telephonePaiement,
    });
    final solde = res['solde'] as int;
    appState.updateSolde(solde);
    return solde;
  }

  // ── Retrait ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> initierRetrait({
    required int montant, required String methode, required String numeroReception,
  }) async {
    return api.post('/transactions/retrait/initier', {
      'montant': montant, 'methode': methode, 'numero_reception': numeroReception,
    });
  }

  Future<Map<String, int>> confirmerRetrait({
    required int montant, required String methode,
    required String numeroReception, required String otpCode,
  }) async {
    final res = await api.post('/transactions/retrait/confirmer', {
      'montant': montant, 'methode': methode,
      'numero_reception': numeroReception, 'otp_code': otpCode,
    });
    final solde = res['solde'] as int;
    final creditConverti = res['credit_converti'] as int;
    final tentatives = res['tentatives'] as int;
    appState.updateSolde(solde);
    appState.updateTentatives(tentatives);
    return {'solde': solde, 'credit_converti': creditConverti, 'tentatives': tentatives};
  }

  // ── Achat pack ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> initierAchatPack({
    required String packId, required String methode,
    String? telephonePaiement,
  }) async {
    final res = await api.post('/transactions/pack/initier', {
      'pack_id': packId,
      'methode': methode,
      if (telephonePaiement != null) 'telephone_paiement': telephonePaiement,
    });
    return res;
  }

  Future<int> confirmerAchatPack({
    required String packId, required String methode,
    required String otpCode, String? telephonePaiement,
  }) async {
    final res = await api.post('/transactions/pack/confirmer', {
      'pack_id': packId, 'methode': methode, 'otp_code': otpCode,
      if (telephonePaiement != null) 'telephone_paiement': telephonePaiement,
    });
    final tentatives = res['tentatives'] as int;
    appState.updateTentatives(tentatives);
    return tentatives;
  }

  // ── Historique ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTransactions({int page = 1, int limit = 20}) async {
    return api.get('/transactions?page=$page&limit=$limit');
  }
}

final transactionService = TransactionService.instance;
