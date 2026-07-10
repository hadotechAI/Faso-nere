// lib/services/lots_service.dart
import '../models/dimension_model.dart';
import 'api_client.dart';

class LotsService {
  LotsService._();
  static final LotsService instance = LotsService._();

  Future<List<DimensionModel>> getLots() async {
    final res  = await api.get('/lots');
    final list = (res['lots'] as List<dynamic>);
    return list.map((l) => DimensionModel.fromJson(l as Map<String, dynamic>)).toList();
  }

  Future<DimensionModel> getLot(String id) async {
    final res = await api.get('/lots/$id');
    return DimensionModel.fromJson(res['lot'] as Map<String, dynamic>);
  }
}

final lotsService = LotsService.instance;
