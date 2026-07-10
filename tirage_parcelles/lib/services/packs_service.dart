// lib/services/packs_service.dart
import '../models/pack_model.dart';
import 'api_client.dart';

class PacksService {
  PacksService._();
  static final PacksService instance = PacksService._();

  Future<List<PackModel>> getPacks() async {
    final res  = await api.get('/packs');
    final list = res['packs'] as List<dynamic>;
    return list.map((p) => PackModel.fromJson(p as Map<String, dynamic>)).toList();
  }
}

final packsService = PacksService.instance;
