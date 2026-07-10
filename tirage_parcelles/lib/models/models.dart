// lib/models/gift_model.dart
enum GiftCategory { terrain, ciment, materiaux, aucun }

class GiftModel {
  final String id;
  final String icon;
  final String imageAsset;
  final String name;
  final String description;
  final int prixReel;
  final bool isWinner;
  final bool isLoser;
  final GiftCategory category;
  final int quantite;

  const GiftModel({
    required this.id,
    required this.icon,
    required this.imageAsset,
    required this.name,
    required this.description,
    required this.prixReel,
    this.isWinner = false,
    this.isLoser = false,
    this.category = GiftCategory.aucun,
    this.quantite = 1,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id:          json['id']          as String,
      icon:        json['icon']        as String,
      imageAsset:  _imageFromCategory(json['categorie'] as String? ?? 'aucun'),
      name:        json['nom']         as String,
      description: json['description'] as String,
      prixReel:    json['prix_reel']   as int? ?? 0,
      isWinner:    json['is_winner']   as bool? ?? false,
      isLoser:     json['is_loser']    as bool? ?? false,
      category:    _parseCategory(json['categorie'] as String? ?? 'aucun'),
      quantite:    json['quantite']    as int? ?? 1,
    );
  }

  static GiftCategory _parseCategory(String cat) {
    switch (cat) {
      case 'terrain':   return GiftCategory.terrain;
      case 'ciment':    return GiftCategory.ciment;
      case 'materiaux': return GiftCategory.materiaux;
      default:          return GiftCategory.aucun;
    }
  }

  static String _imageFromCategory(String cat) {
    switch (cat) {
      case 'terrain':   return 'assets/images/terrain.png';
      case 'ciment':    return 'assets/images/ciment.png';
      case 'materiaux': return 'assets/images/material.png';
      default:          return 'assets/images/cascade.png';
    }
  }

  String get prixLabel =>
      prixReel > 0 ? '${_fmt(prixReel)} FCFA' : 'Aucun gain';

  static String _fmt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}


// ─────────────────────────────────────────────────────────────
// lib/models/dimension_model.dart
// ─────────────────────────────────────────────────────────────

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
    final rawGifts = json['cadeaux'] as List<dynamic>? ?? [];
    // On répète chaque cadeau selon sa quantité (pour la grille Flutter)
    final gifts = <GiftModel>[];
    for (final g in rawGifts) {
      final gift = GiftModel.fromJson(g as Map<String, dynamic>);
      for (int i = 0; i < gift.quantite; i++) {
        gifts.add(gift);
      }
    }

    return DimensionModel(
      id:          json['id']            as String,
      surface:     json['nom']           as String,
      subtitle:    json['subtitle']      as String,
      icon:        json['icon']          as String,
      cadeaux:     json['nb_cadeaux']    as int? ?? 20,
      description: '${json['nb_gagnants']} cadeaux gagnants sur ${json['nb_cadeaux']}',
      gifts:       gifts,
      prixMin:     json['prix_min']      as int? ?? 0,
      prixMax:     json['prix_max']      as int? ?? 0,
      nbGagnants:  json['nb_gagnants']   as int? ?? 0,
    );
  }

  double get chancePercent => nbGagnants / cadeaux * 100;

  String get chanceLabel =>
      '$nbGagnants cadeaux gagnants sur $cadeaux (${chancePercent.toStringAsFixed(0)}%)';

  List<GiftModel> get uniquePrizes {
    final seen = <String>{};
    final result = <GiftModel>[];
    final winners = gifts.where((g) => g.isWinner).toList()
      ..sort((a, b) => b.prixReel.compareTo(a.prixReel));
    for (final g in winners) {
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


// ─────────────────────────────────────────────────────────────
// lib/models/pack_model.dart
// ─────────────────────────────────────────────────────────────

class PackModel {
  final String id;
  final int tentatives;
  final int prix;
  final int prixParTentative;
  final bool isPopular;
  final bool isBestValue;
  final String? badge;

  const PackModel({
    required this.id,
    required this.tentatives,
    required this.prix,
    required this.prixParTentative,
    this.isPopular = false,
    this.isBestValue = false,
    this.badge,
  });

  factory PackModel.fromJson(Map<String, dynamic> json) {
    return PackModel(
      id:               json['id']               as String,
      tentatives:       json['tentatives']        as int,
      prix:             json['prix']              as int,
      prixParTentative: json['prix_par_tentative'] as int,
      isPopular:        json['is_popular']        as bool? ?? false,
      isBestValue:      json['is_best_value']     as bool? ?? false,
      badge:            json['badge']             as String?,
    );
  }
}
