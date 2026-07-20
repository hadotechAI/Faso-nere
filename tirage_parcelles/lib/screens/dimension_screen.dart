// lib/screens/dimension_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../models/dimension_model.dart';
import '../models/gift_model.dart';
import '../models/player_model.dart';
import '../services/lots_service.dart';
import 'tirage_screen.dart';
import 'wheel_screen.dart'; 

class DimensionScreen extends StatefulWidget {
  final PlayerModel player;
  const DimensionScreen({super.key, required this.player});

  @override
  State<DimensionScreen> createState() => _DimensionScreenState();
}

class _DimensionScreenState extends State<DimensionScreen> {
  int _selected        = 0;
  int _mode            = 0; // 0 = boîtes, 1 = roue
  List<DimensionModel> _lots       = [];
  bool                 _loading    = true;
  String?              _error;

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  Future<void> _loadLots() async {
    try {
      final lots = await lotsService.getLots();
      setState(() { _lots = lots; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (_error != null || _lots.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Choisir votre lot'),
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('😕', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(_error ?? 'Aucun lot disponible',
                style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 20),
            GoldBtn(label: 'Réessayer', onTap: () {
              setState(() { _loading = true; _error = null; });
              _loadLots();
            }),
          ]),
        ),
      );
    }

    return AppScaffold(
      title: 'Choisir votre lot',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Sélectionnez le lot auquel vous souhaitez participer',
            style: TextStyle(fontSize: 13, color: AppColors.grey, height: 1.5),
          ),
          const SizedBox(height: 20),

          // ── Sélecteur de mode ──────────────────────────────────
            Text('Mode de jeu',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.greyLight)),
          const SizedBox(height: 10),
          Row(children: [
            _ModeCard(
              icon: '🎁', label: 'Boîtes cadeaux',
              desc: 'Choisissez 1 boîte\nparmi ${_lots.isNotEmpty ? _lots[_selected].cadeaux : 20}',
              selected: _mode == 0,
              onTap: () => setState(() => _mode = 0),
            ),
            const SizedBox(width: 12),
            _ModeCard(
              icon: '🎡', label: 'Roue de la fortune',
              desc: 'Faites tourner\nla roue',
              selected: _mode == 1,
              onTap: () => setState(() => _mode = 1),
            ),
          ]),

          const SizedBox(height: 24),

          // ── Cartes des lots ───────────────────────────────────
          ...List.generate(_lots.length, (i) {
            final dim        = _lots[i];
            final isSelected = i == _selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withOpacity(0.07)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.gold.withOpacity(0.15),
                            blurRadius: 16, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Column(children: [
                    // En-tête
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: isSelected
                              ? [const Color(0xFF3B2800), const Color(0xFF5C3D00)]
                              : [AppColors.surface2, AppColors.card],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                      ),
                      child: Row(children: [
                      Text(dim.icon, style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(dim.surface, style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: isSelected ? AppColors.gold : AppColors.white,
                          letterSpacing: 0.3)),
                        const SizedBox(height: 3),
                        Text(dim.subtitle, style: TextStyle(
                          fontSize: 11, color: AppColors.grey, height: 1.4)),
                      ])),
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.gold : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.gold : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 14, color: AppColors.bg)
                              : null,
                        ),
                      ]),
                    ),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatBadge(icon: Icons.casino_outlined,
                              label: dim.chanceLabel, color: AppColors.success),
                          _StatBadge(icon: Icons.emoji_events_outlined,
                              label: 'Max ${dim.prixMaxLabel} FCFA',
                              color: AppColors.gold),
                        ]),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AppDivider(),
                    ),

                    // Cadeaux
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text('Cadeaux possibles',
                              style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey)),
                          const SizedBox(height: 10),
                          ...dim.uniquePrizes.map((g) => _PrizeRow(gift: g)),
                          _PrizeRow(
                            gift: const GiftModel(
                              id: 'loser', icon: '❌', name: 'Aucun gain',
                              description: 'Pas de gain', prixReel: 0,
                              isLoser: true,
                            ),
                            count: dim.gifts.where((g) => g.isLoser).length,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),

          // Hint
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
                Text(_mode == 0 ? '💡' : '🎡',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _mode == 0
                    ? 'Chaque boîte cache un cadeau différent.\nVous ouvrez 1 boîte parmi ${_lots.isNotEmpty ? _lots[_selected].cadeaux : 20} — bonne chance !'
                    : 'La roue contient les ${_lots.isNotEmpty ? _lots[_selected].cadeaux : 20} cadeaux du lot.\nFaites-la tourner et découvrez votre cadeau !',
                style: TextStyle(fontSize: 12,
                  color: AppColors.greyLight, height: 1.5),
              )),
            ]),
          ),

          const SizedBox(height: 24),

          GoldBtn(
            label: _lots.isEmpty
                ? 'Chargement...'
                : _mode == 0
                    ? 'Choisir une boîte – ${_lots[_selected].surface}'
                    : 'Tourner la roue – ${_lots[_selected].surface}',
            icon: _mode == 0
                ? Icons.casino_rounded
                : Icons.rotate_right_rounded,
            onTap: _lots.isEmpty ? null : () {
              if (widget.player.tentatives <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Vous n\'avez plus de tentatives. Achetez un pack !'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }
              if (_mode == 0) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TirageScreen(
                    player:    widget.player,
                    dimension: _lots[_selected],
                  ),
                ));
              } else {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => WheelScreen(
                    player:    widget.player,
                    dimension: _lots[_selected],
                  ),
                ));
              }
            },
          ),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }
}

// ── Widgets locaux ────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final String icon, label, desc;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.icon, required this.label, required this.desc,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Text(icon, style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: selected ? AppColors.gold : AppColors.white)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.grey, height: 1.4)),
        ]),
      ),
    ),
  );
}

class _PrizeRow extends StatelessWidget {
  final GiftModel gift;
  final int? count;
  const _PrizeRow({required this.gift, this.count});

  Color get _catColor {
    switch (gift.category) {
      case GiftCategory.terrain:   return AppColors.success;
      case GiftCategory.ciment:    return AppColors.warning;
      case GiftCategory.materiaux: return AppColors.purpleLight;
      default:                     return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoser = gift.isLoser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isLoser
                ? AppColors.border.withOpacity(0.3)
                : _catColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(gift.icon,
              style: TextStyle(fontSize: isLoser ? 14 : 16))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Row(children: [
          Text(gift.name, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: isLoser ? AppColors.grey : AppColors.white)),
          if (count != null && count! > 1) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('×$count', style: TextStyle(fontSize: 10,
                  color: AppColors.grey, fontWeight: FontWeight.w700)),
            ),
          ],
        ])),
        Text(isLoser ? '—' : gift.prixLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: isLoser ? AppColors.grey : AppColors.gold)),
      ]),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(label, 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
  ]);
}