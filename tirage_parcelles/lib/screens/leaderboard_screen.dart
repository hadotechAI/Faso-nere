import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../core/ui_components.dart';
import '../services/leaderboard_service.dart';

class WinnerModel {
  final String nom;
  final String prenom;
  final String ville;
  final int nbGains;
  final int valeurTotale;
  final int nbTirages;

  const WinnerModel({
    required this.nom,
    required this.prenom,
    required this.ville,
    required this.nbGains,
    required this.valeurTotale,
    required this.nbTirages,
  });

  factory WinnerModel.fromJson(Map<String, dynamic> json) {
    return WinnerModel(
      nom: json['nom'] ?? 'Inconnu',
      prenom: json['prenom'] ?? '',
      ville: json['ville'] ?? 'Inconnue',
      nbGains: json['nb_gains'] ?? 0,
      valeurTotale: json['valeur_totale'] ?? 0,
      nbTirages: json['nb_tirages'] ?? 0,
    );
  }

  String get initiales =>
      '${nom.isNotEmpty ? nom[0] : ''}${prenom.isNotEmpty ? prenom[0] : ''}'.toUpperCase();

  String get nomComplet => '$nom $prenom'.trim();
}

const List<Color> _avatarColors = [
  Color(0xFFB8860B),
  Color(0xFF4A3575),
  Color(0xFF534AB7),
  Color(0xFF0F6E56),
  Color(0xFF993C1D),
  Color(0xFF3B6D11),
  Color(0xFF185FA5),
  Color(0xFF712B13),
  Color(0xFF3C3489),
  Color(0xFF085041),
];

enum PeriodFilter { semaine, mois, annee, toutTemps }

extension PeriodLabel on PeriodFilter {
  String get label {
    switch (this) {
      case PeriodFilter.semaine:    return 'Cette semaine';
      case PeriodFilter.mois:      return 'Ce mois';
      case PeriodFilter.annee:     return 'Cette année';
      case PeriodFilter.toutTemps: return 'Tout temps';
    }
  }

  String? get value {
    switch (this) {
      case PeriodFilter.semaine: return 'semaine';
      case PeriodFilter.mois:    return 'mois';
      case PeriodFilter.annee:   return 'annee';
      case PeriodFilter.toutTemps: return null;
    }
  }
}

class LeaderboardScreen extends StatefulWidget {
  final String? currentUserName;

  const LeaderboardScreen({
    super.key,
    this.currentUserName,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  PeriodFilter _period = PeriodFilter.toutTemps;
  late final AnimationController _podiumCtrl;
  late final Animation<double>   _podiumAnim;

  List<WinnerModel> _winners = [];
  Map<String, dynamic>? _myRank;
  int _totalGagnants = 0;
  int _totalValeur = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _podiumCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _podiumAnim = CurvedAnimation(parent: _podiumCtrl, curve: Curves.easeOutBack);
    _fetchData();
  }

  @override
  void dispose() {
    _podiumCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await leaderboardService.getLeaderboard(period: _period.value);
      final myRankRes = await leaderboardService.getMyRank();
      if (mounted) {
        setState(() {
          _winners = (res['leaderboard'] as List).map((e) => WinnerModel.fromJson(e)).toList();
          _totalGagnants = res['stats']?['total_gagnants'] ?? 0;
          _totalValeur = res['stats']?['valeur_totale'] ?? 0;
          _myRank = myRankRes['rank'];
          _loading = false;
        });
        _podiumCtrl.reset();
        _podiumCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Top Gagnants',
      showBack: false, // <-- Désactivé car c'est un onglet
      body: Column(children: [
        _buildPeriodFilters(),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: AppColors.gold))
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
                  : RefreshIndicator(
                      color: AppColors.gold,
                      onRefresh: _fetchData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(children: [
                          _buildGlobalStats(),
                          if (_winners.length >= 3) _buildPodiumSection(_winners),
                          const SizedBox(height: 4),
                          _buildListSection(_winners),
                          if (_myRank != null && _myRank!['rank'] != null) _buildMyPosition(),
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildPeriodFilters() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: PeriodFilter.values.map((f) {
          final isActive = f == _period;
          return GestureDetector(
            onTap: () {
              setState(() => _period = f);
              _fetchData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? AppColors.gold : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? AppColors.gold : AppColors.border),
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.bg : AppColors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlobalStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(child: _StatCard(
          value: '$_totalGagnants',
          label: 'Gagnants',
          icon: Icons.emoji_events_rounded,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          value: '${_fmt(_totalValeur)} FCFA',
          label: 'Valeur totale',
          icon: Icons.account_balance_wallet_rounded,
        )),
      ]),
    );
  }

  Widget _buildPodiumSection(List<WinnerModel> winners) {
    final first  = winners[0];
    final second = winners[1];
    final third  = winners[2];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PODIUM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.greyLight, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _PodiumColumn(winner: second, rank: 2, blockHeight: 64, avatarSize: 44, color: _avatarColors[1], animation: _podiumAnim, medal: '🥈')),
            const SizedBox(width: 8),
            Expanded(child: _PodiumColumn(winner: first, rank: 1, blockHeight: 86, avatarSize: 52, color: _avatarColors[0], animation: _podiumAnim, medal: '🥇', isCrown: true)),
            const SizedBox(width: 8),
            Expanded(child: _PodiumColumn(winner: third, rank: 3, blockHeight: 48, avatarSize: 40, color: _avatarColors[2], animation: _podiumAnim, medal: '🥉')),
          ],
        ),
      ]),
    );
  }

  Widget _buildListSection(List<WinnerModel> winners) {
    if (winners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('Aucun gagnant pour le moment', style: TextStyle(fontSize: 14, color: AppColors.grey)),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CLASSEMENT COMPLET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.greyLight, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: winners.length,
            separatorBuilder: (_, _) => Divider(height: 1, thickness: 1, color: AppColors.border),
            itemBuilder: (_, i) => _LeaderboardRow(winner: winners[i], rank: i + 1, avatarColor: _avatarColors[i % _avatarColors.length]),
          ),
        ),
      ]),
    );
  }

  Widget _buildMyPosition() {
    final name = appState.user?.nomComplet ?? widget.currentUserName ?? 'Vous';
    final rank = _myRank?['rank'] ?? '-';
    final nbGains = _myRank?['nb_gains'] ?? 0;
    final valeurTotale = _myRank?['valeur_totale'] ?? 0;
    final nbTirages = _myRank?['nb_tirages'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: [
        Row(children: [
          Expanded(child: Divider(color: AppColors.border, thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('VOTRE POSITION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey, letterSpacing: 0.5)),
          ),
          Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        ]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.goldDark.withOpacity(0.5)),
                ),
                child: Center(child: Text('$rank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold))),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
                  const SizedBox(height: 2),
                  Text('$nbTirages tentatives', style: TextStyle(fontSize: 11, color: AppColors.grey)),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${_fmt(valeurTotale)} FCFA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold)),
                const SizedBox(height: 2),
                Text('$nbGains gain(s)', style: TextStyle(fontSize: 10, color: AppColors.grey)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}

class _PodiumColumn extends StatelessWidget {
  final WinnerModel winner;
  final int rank;
  final double blockHeight;
  final double avatarSize;
  final Color color;
  final Animation<double> animation;
  final String medal;
  final bool isCrown;

  const _PodiumColumn({
    required this.winner,
    required this.rank,
    required this.blockHeight,
    required this.avatarSize,
    required this.color,
    required this.animation,
    required this.medal,
    this.isCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => Transform.scale(
        scale: animation.value.clamp(0.0, 1.0),
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCrown) Text('👑', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Container(
              width: avatarSize, height: avatarSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: rank == 1 ? AppColors.gold : AppColors.borderLight, width: rank == 1 ? 2.5 : 1.5),
              ),
              child: Center(
                child: Text(winner.initiales, style: TextStyle(fontSize: avatarSize * 0.36, fontWeight: FontWeight.w800, color: AppColors.white)),
              ),
            ),
            const SizedBox(height: 4),
            Text(winner.nom, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: rank == 1 ? 11 : 10, fontWeight: FontWeight.w800, color: AppColors.white)),
            const SizedBox(height: 2),
            Text('${winner.nbGains} gain(s)', style: TextStyle(fontSize: 10, color: AppColors.grey)),
            const SizedBox(height: 4),
            Container(
              height: blockHeight,
              decoration: BoxDecoration(
                color: rank == 1 ? Color(0xFF5B3F0B) : rank == 2 ? Color(0xFF2D255A) : AppColors.surface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(color: rank == 1 ? AppColors.gold : rank == 2 ? AppColors.purpleLight : AppColors.border),
              ),
              child: Center(child: Text(medal, style: TextStyle(fontSize: 20))),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final WinnerModel winner;
  final int rank;
  final Color avatarColor;

  const _LeaderboardRow({
    required this.winner,
    required this.rank,
    required this.avatarColor,
  });

  String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Center(
            child: isTop3
                ? Text(medals[rank]!, style: TextStyle(fontSize: 16))
                : Text('$rank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey)),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
          child: Center(child: Text(winner.initiales, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(winner.nomComplet, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${winner.ville} · ${winner.nbTirages} tentatives', style: TextStyle(fontSize: 10, color: AppColors.grey)),
          ],
        )),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_fmt(winner.valeurTotale)} FCFA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold)),
          const SizedBox(height: 2),
          Text('${winner.nbGains} gain(s)', style: TextStyle(fontSize: 10, color: AppColors.grey)),
        ]),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.gold, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white)),
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.grey)),
          ],
        )),
      ]),
    );
  }
}