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
    this.imageAsset = 'assets/images/terrain.png',
    required this.name,
    required this.description,
    required this.prixReel,
    this.isWinner = false,
    this.isLoser  = false,
    this.category = GiftCategory.aucun,
    this.quantite = 1,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) => GiftModel(
    id:          json['id']          as String,
    icon:        (json['icon']       as String?) ?? '🎁',
    imageAsset:  _imageForCategory((json['categorie'] as String?) ?? 'aucun'),
    name:        json['nom']         as String,
    description: json['description'] as String,
    prixReel:    (json['prix_reel']  as int?) ?? 0,
    isWinner:    (json['is_winner']  as bool?) ?? false,
    isLoser:     (json['is_loser']   as bool?) ?? false,
    category:    _parseCategory((json['categorie'] as String?) ?? 'aucun'),
    quantite:    (json['quantite']   as int?) ?? 1,
  );

  static String _imageForCategory(String cat) {
    switch (cat) {
      case 'terrain':   return 'assets/images/terrain.png';
      case 'ciment':    return 'assets/images/ciment.png';
      case 'materiaux': return 'assets/images/material.png';
      default:          return 'assets/images/cascade.png';
    }
  }

  static GiftCategory _parseCategory(String cat) {
    switch (cat) {
      case 'terrain':   return GiftCategory.terrain;
      case 'ciment':    return GiftCategory.ciment;
      case 'materiaux': return GiftCategory.materiaux;
      default:          return GiftCategory.aucun;
    }
  }

  String get prixLabel => prixReel > 0
      ? '${_fmt(prixReel)} FCFA'
      : 'Aucun gain';

  static String _fmt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}