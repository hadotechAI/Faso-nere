// lib/models/player_model.dart
class PlayerModel {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final String role;
  final String? ville;
  final String? quartier;
  final String? pays;
  final String codeParrain;
  final String? avatarUrl;
  final int loginStreak;
  final int solde;
  final int creditConverti; // ✅ Solde de gains converti et retraitable
  
  final int gagnes;
  final int parrainages;
  final bool isVerified;
  final bool isActive;

  int tentatives;

  PlayerModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.role        = 'joueur',
    this.ville,
    this.quartier,
    this.pays,
    required this.codeParrain,
    this.avatarUrl,
    this.loginStreak = 0,
    this.solde       = 0,
    this.creditConverti = 0,
    this.tentatives  = 0,
    this.gagnes      = 0,
    this.parrainages = 0,
    this.isVerified  = false,
    this.isActive    = true,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) => PlayerModel(
    id:             json['id']               as String,
    nom:            json['nom']              as String,
    prenom:         json['prenom']           as String,
    telephone:      json['telephone']        as String,
    email:          json['email']            as String?,
    role:           (json['role']            as String?) ?? 'joueur',
    ville:          json['ville']            as String?,
    quartier:       json['quartier']         as String?,
    pays:           json['pays']             as String?,
    codeParrain:    (json['code_parrain']    as String?) ?? '',
    avatarUrl:      json['avatar_url']       as String?,
    loginStreak:    (json['login_streak']    as int?)    ?? 0,
    solde:          (json['solde']           as int?)    ?? 0,
    creditConverti: (json['credit_converti'] as int?)    ?? 0,
    tentatives:     (json['tentatives']      as int?)    ?? 0,
    gagnes:         (json['gagnes']          as int?)    ?? 0,
    parrainages:    (json['parrainages']     as int?)    ?? 0,
    isVerified:     (json['is_verified']     as bool?)   ?? false,
    isActive:       (json['is_active']       as bool?)   ?? true,
  );

  PlayerModel copyWith({
    int?    solde,
    int?    creditConverti,
    int?    tentatives,
    int?    gagnes,
    int?    parrainages,
    bool?   isVerified,
    String? ville,
    String? quartier,
    String? pays,
    String? email,
    String? codeParrain,
    String? avatarUrl,
    int?    loginStreak,
  }) => PlayerModel(
    id:             id,
    nom:            nom,
    prenom:         prenom,
    telephone:      telephone,
    email:          email          ?? this.email,
    role:           role,
    ville:          ville          ?? this.ville,
    quartier:       quartier       ?? this.quartier,
    pays:           pays           ?? this.pays,
    codeParrain:    codeParrain    ?? this.codeParrain,
    avatarUrl:      avatarUrl      ?? this.avatarUrl,
    loginStreak:    loginStreak    ?? this.loginStreak,
    solde:          solde          ?? this.solde,
    creditConverti: creditConverti ?? this.creditConverti,
    tentatives:     tentatives     ?? this.tentatives,
    gagnes:         gagnes         ?? this.gagnes,
    parrainages:    parrainages    ?? this.parrainages,
    isVerified:     isVerified     ?? this.isVerified,
    isActive:       isActive,
  );

  String get nomComplet => '$nom $prenom';
}