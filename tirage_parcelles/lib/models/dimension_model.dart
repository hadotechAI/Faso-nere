// lib/models/dimension_model.dart
import 'gift_model.dart';

class DimensionModel {
  final String id;
  final String surface;
  final String subtitle;
  final String icon;
  final int cadeaux;
  final String description;
  final List<GiftModel> gifts;
  final int prixMin;
  final int prixMax;
  final int nbGagnants;

  const DimensionModel({
    required this.id,
    required this.surface,
    required this.subtitle,
    required this.icon,
    required this.cadeaux,
    required this.description,
    required this.gifts,
    required this.prixMin,
    required this.prixMax,
    required this.nbGagnants,
  });

  factory DimensionModel.fromJson(Map<String, dynamic> json) {
    final rawGifts = (json['cadeaux'] as List<dynamic>?) ?? [];
    final gifts = <GiftModel>[];
    for (final g in rawGifts) {
      final gift = GiftModel.fromJson(g as Map<String, dynamic>);
      final qty  = (g['quantite'] as int?) ?? 1;
      for (var i = 0; i < qty; i++) {
        gifts.add(gift);
      }
    }
    return DimensionModel(
      id:          json['id']            as String,
      surface:     json['nom']           as String,
      subtitle:    (json['subtitle']     as String?) ?? '',
      icon:        (json['icon']         as String?) ?? '🎁',
      cadeaux:     (json['nb_cadeaux']   as int?) ?? 20,
      description: (json['subtitle']     as String?) ?? '',
      gifts:       gifts,
      prixMin:     (json['prix_min']     as int?) ?? 0,
      prixMax:     (json['prix_max']     as int?) ?? 0,
      nbGagnants:  (json['nb_gagnants']  as int?) ?? 0,
    );
  }

  double get chancePercent =>
      cadeaux > 0 ? nbGagnants / cadeaux * 100 : 0;

  String get chanceLabel =>
      '$nbGagnants cadeaux gagnants sur $cadeaux (${chancePercent.toStringAsFixed(0)}%)';

  List<GiftModel> get uniquePrizes {
    final seen   = <String>{};
    final result = <GiftModel>[];
    final sorted = gifts.where((g) => g.isWinner).toList()
      ..sort((a, b) => b.prixReel.compareTo(a.prixReel));
    for (final g in sorted) {
      if (seen.add(g.name)) result.add(g);
    }
    return result;
  }

  static String _fmt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  String get prixMaxLabel => _fmt(prixMax);
  String get prixMinLabel => _fmt(prixMin);
}