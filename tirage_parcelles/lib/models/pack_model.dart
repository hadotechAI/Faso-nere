// lib/models/pack_model.dart
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
    this.isPopular   = false,
    this.isBestValue = false,
    this.badge,
  });

  factory PackModel.fromJson(Map<String, dynamic> json) => PackModel(
    id:               json['id']                  as String,
    tentatives:       json['tentatives']           as int,
    prix:             json['prix']                 as int,
    prixParTentative: (json['prix_par_tentative']  as int?) ??
                      ((json['prix'] as int) ~/ (json['tentatives'] as int)),
    isPopular:        (json['is_popular']           as bool?) ?? false,
    isBestValue:      (json['is_best_value']        as bool?) ?? false,
    badge:            json['badge']                as String?,
  );

  /// Libellé affiché sur la carte du pack
  String get title => '$tentatives tentative${tentatives > 1 ? 's' : ''}';

  static String _fmt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  String get prixLabel          => '${_fmt(prix)} FCFA';
  String get prixParTentLabel   => '${_fmt(prixParTentative)} FCFA / tentative';
}