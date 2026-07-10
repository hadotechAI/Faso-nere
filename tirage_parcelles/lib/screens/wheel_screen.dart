// lib/screens/wheel_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../core/ui_components.dart';
import '../models/dimension_model.dart';
import '../models/gift_model.dart';
import '../models/player_model.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/tirage_service.dart';
import 'pack_screen.dart';
import 'result_screen.dart';

class WheelScreen extends StatefulWidget {
  final PlayerModel    player;
  final DimensionModel dimension;

  const WheelScreen({
    super.key,
    required this.player,
    required this.dimension,
  });

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────
  late AnimationController _spinCtrl;
  late Animation<double>   _spinAnim;
  double _wheelAngle = 0;

  // ── État ───────────────────────────────────────────────────
  // Segments visuels uniquement (pour l'affichage de la roue)
  late List<GiftModel> _segments;

  bool       _spinning  = false;
  bool       _calling   = false;   // appel API en cours
  TirageResult? _tirageResult;     // résultat complet du serveur
  late int        _tentatives;

  @override
  void initState() {
    super.initState();
    _tentatives = widget.player.tentatives;

    // Les segments sont juste visuels — on les mélange pour l'esthétique
    // mais le VRAI cadeau vient du serveur
    _segments = List<GiftModel>.from(widget.dimension.gifts)..shuffle();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _spinAnim = Tween<double>(begin: 0, end: 0).animate(_spinCtrl);
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  // ── Lance la roue : appel API + animation ──────────────────
  Future<void> _spin() async {
    if (_spinning || _calling) return;

    if (_tentatives <= 0) {
      _showSnack('Plus de tentatives ! Achetez un pack.');
      return;
    }

    setState(() {
      _spinning = true;
      _calling  = true;
      _tirageResult = null;
    });

    // ── 1. Appel API (pendant que la roue tourne) ───────────
    late final TirageResult tirageResult;
    try {
      tirageResult = await tirageService.jouer(
        lotId: widget.dimension.id,
        mode:  'roue',
      );
      // Mettre à jour le state global
      appState.updateTentatives(tirageResult.tentativesRestantes);
      setState(() {
        _tentatives = tirageResult.tentativesRestantes;
        _calling    = false;
      });
    } on ApiException catch (e) {
      setState(() { _spinning = false; _calling = false; });
      if (e.statusCode == 402) {
        _showNoAttemptsDialog();
      } else {
        _showSnack(e.message);
      }
      return;
    } catch (_) {
      setState(() { _spinning = false; _calling = false; });
      _showSnack('Erreur réseau. Vérifiez votre connexion.');
      return;
    }

    // ── 2. Animation de la roue ─────────────────────────────
    // On fait tourner la roue visuellement en visant le vrai cadeau retourné.
    final rng       = Random.secure();
    final tours     = 7 + rng.nextInt(5);
    final arc       = 2 * pi / _segments.length;
    final resultId  = tirageResult.cadeau.id;
    int selectedIndex = _segments.indexWhere((g) => g.id == resultId);
    if (selectedIndex < 0) {
      selectedIndex = _segments.indexWhere((g) => g.name == tirageResult.cadeau.name);
    }
    
    // Si on n'a pas trouvé la case exacte, on applique l'option 2 (choisir une case "aucun gain" au hasard)
    if (selectedIndex < 0) {
      if (!tirageResult.isWinner) {
        // C'est un tirage perdant : on cherche toutes les cases perdantes
        final losers = [];
        for (int i = 0; i < _segments.length; i++) {
          if (_segments[i].isLoser || !_segments[i].isWinner) {
            losers.add(i);
          }
        }
        // S'il y a des cases perdantes, on en choisit une au hasard
        if (losers.isNotEmpty) {
          selectedIndex = losers[rng.nextInt(losers.length)];
        }
      } else {
        // C'est un tirage gagnant : on cherche toutes les cases gagnantes
        final winners = [];
        for (int i = 0; i < _segments.length; i++) {
          if (_segments[i].isWinner) winners.add(i);
        }
        if (winners.isNotEmpty) {
          selectedIndex = winners[rng.nextInt(winners.length)];
        }
      }
    }
    
    final targetIndex = selectedIndex >= 0 ? selectedIndex : rng.nextInt(_segments.length);

    // Aligner le centre du segment choisi sous le pointeur en haut.
    final desiredAngle = (2 * pi - ((targetIndex + 0.5) * arc) % (2 * pi)) % (2 * pi);
    final degreesToAdd = ((desiredAngle - _wheelAngle) % (2 * pi) + 2 * pi) % (2 * pi);
    final extra = tours * 2 * pi + degreesToAdd;
    final targetAngle = _wheelAngle + extra;

    _spinAnim = Tween<double>(begin: _wheelAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.decelerate),
    );

    _spinCtrl.reset();
    await _spinCtrl.forward();

    if (!mounted) return;

    _wheelAngle = targetAngle % (2 * pi);

    // ── 3. Afficher le vrai résultat du serveur ─────────────
    if (tirageResult.isWinner) {
      await notificationService.showGain(
        tirageResult.cadeau.name,
        tirageResult.cadeau.prixReel.toString(),
      );
    }
    setState(() {
      _tirageResult = tirageResult;
      _spinning     = false;
    });
  }

  // ── Helpers UI ─────────────────────────────────────────────
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showNoAttemptsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Plus de tentatives',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        content: Text('Achetez un pack pour continuer à jouer.',
          style: TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
              style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.bg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PackScreen(player: appState.user!),
              ));
            },
            child: Text('Acheter un pack',
              style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Roue de la fortune',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(children: [

          // ── Infos lot + tentatives ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoPill(
                emoji: widget.dimension.icon,
                label: widget.dimension.surface,
                color: AppColors.gold,
              ),
              _InfoPill(
                emoji: '🎟️',
                label: '$_tentatives tentative${_tentatives > 1 ? 's' : ''}',
                color: _tentatives > 0
                    ? AppColors.purpleLight
                    : AppColors.error,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Roue + pointeur ─────────────────────────────────
          SizedBox(
            width: 320,
            height: 345,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 22, left: 10, right: 10, bottom: 0,
                  child: AnimatedBuilder(
                    animation: _spinning
                        ? _spinAnim
                        : AlwaysStoppedAnimation(_wheelAngle),
                    builder: (context, child) => CustomPaint(
                      painter: _WheelPainter(
                        segments: _segments,
                        angle: _spinning ? _spinAnim.value : _wheelAngle,
                      ),
                    ),
                  ),
                ),
                const Positioned(top: 0, child: _PointerWidget()),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Zone résultat / état ────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _tirageResult != null
                ? _ResultCard(
                    key:       ValueKey(_tirageResult!.cadeau.name),
                    gift:      _tirageResult!.cadeau,
                    player:    appState.user ?? widget.player,
                    dimension: widget.dimension,
                    tirageId:  _tirageResult!.id,
                    isConverted: _tirageResult!.isConverted,
                    onRetry: () => setState(() => _tirageResult = null),
                  )
                : (_spinning || _calling)
                    ? Column(
                        key: const ValueKey('spinning'),
                        children: [
                            CircularProgressIndicator(
                              color: AppColors.gold, strokeWidth: 2.5),
                          const SizedBox(height: 10),
                          Text(
                            _calling
                                ? 'Tirage en cours...'
                                : 'La roue tourne…',
                            style: TextStyle(
                              fontSize: 13, color: AppColors.grey),
                          ),
                        ],
                      )
                    : SizedBox(
                        key: const ValueKey('idle'),
                        height: 52,
                        child: Center(
                          child: Text(
                            _tentatives > 0
                                ? 'Appuyez sur "Tourner" pour démarrer'
                                : 'Plus de tentatives disponibles',
                            style: TextStyle(
                              fontSize: 13,
                              color: _tentatives > 0
                                  ? AppColors.grey
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ),
          ),

          const SizedBox(height: 16),

          // ── Bouton tourner ──────────────────────────────────
          if (_tirageResult == null && !_spinning && !_calling)
            GoldBtn(
              label: _tentatives > 0
                  ? 'Tourner la roue'
                  : 'Acheter des tentatives',
              icon: _tentatives > 0
                  ? Icons.rotate_right_rounded
                  : Icons.add_circle_outline_rounded,
              onTap: _tentatives > 0
                  ? _spin
                  : () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PackScreen(
                            player: appState.user ?? widget.player),
                      )),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Roue (CustomPainter)
// ─────────────────────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final List<GiftModel> segments;
  final double          angle;
  const _WheelPainter({required this.segments, required this.angle});

  Color _fill(GiftModel g) {
    if (g.isLoser) return const Color(0xFF2A2350);
    switch (g.category) {
      case GiftCategory.terrain:   return const Color(0xFF1A6B3C);
      case GiftCategory.ciment:    return const Color(0xFF7A5200);
      case GiftCategory.materiaux: return const Color(0xFF4A2D7A);
      default:                     return AppColors.surface2;
    }
  }

  Color _stroke(GiftModel g) {
    if (g.isLoser) return const Color(0xFF1A1535);
    switch (g.category) {
      case GiftCategory.terrain:   return AppColors.success;
      case GiftCategory.ciment:    return AppColors.warning;
      case GiftCategory.materiaux: return AppColors.purpleLight;
      default:                     return AppColors.border;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx  = size.width  / 2;
    final cy  = size.height / 2;
    final r   = min(size.width, size.height) / 2;
    final n   = segments.length;
    final arc = 2 * pi / n;

    final pFill   = Paint()..style = PaintingStyle.fill;
    final pStroke = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < n; i++) {
      final startAngle = angle + i * arc - pi / 2;
      pFill.color   = _fill(segments[i]);
      pStroke.color = _stroke(segments[i]);

      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
            startAngle, arc, false)
        ..close();

      canvas.drawPath(path, pFill);
      canvas.drawPath(path, pStroke);

      // Label
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(startAngle + arc / 2);
      final label = segments[i].isLoser
          ? 'Aucun gain'
          : segments[i].name.length <= 13
              ? segments[i].name
              : '${segments[i].name.substring(0, 12)}…';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: segments[i].isLoser ? 9 : 10,
            fontWeight: FontWeight.w700,
            color: segments[i].isLoser ? AppColors.grey : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.58);
      tp.paint(canvas, Offset(r * 0.40, -tp.height / 2));
      canvas.restore();
    }

    // Hub central
    pFill.color = AppColors.bg;
    canvas.drawCircle(Offset(cx, cy), r * 0.17, pFill);
    pStroke
      ..color       = AppColors.gold
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), r * 0.17, pStroke);

    final hub = TextPainter(
      text: TextSpan(
        text: 'FASO\nNERE',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
            color: AppColors.gold, height: 1.3),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    hub.paint(canvas, Offset(cx - hub.width / 2, cy - hub.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.angle != angle || old.segments != segments;
}

// ─────────────────────────────────────────────────────────────
//  Pointeur
// ─────────────────────────────────────────────────────────────
class _PointerWidget extends StatelessWidget {
  const _PointerWidget();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(30, 38), painter: _PointerPainter());
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path,
        Paint()
          ..color      = Colors.black38
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(path, Paint()..color = AppColors.gold);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
//  Carte résultat
// ─────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final GiftModel      gift;
  final PlayerModel    player;
  final DimensionModel dimension;
  final String?        tirageId;
  final bool          isConverted;
  final VoidCallback  onRetry;

  const _ResultCard({
    super.key,
    required this.gift,
    required this.player,
    required this.dimension,
    required this.onRetry,
    this.tirageId,
    this.isConverted = false,
  });

  bool get isWin => gift.isWinner;

  Color get _color {
    if (!isWin) return AppColors.error;
    switch (gift.category) {
      case GiftCategory.terrain:   return AppColors.success;
      case GiftCategory.ciment:    return AppColors.warning;
      case GiftCategory.materiaux: return AppColors.purpleLight;
      default:                     return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayIcon = isWin ? gift.icon : '❌';
    final displayName = isWin ? gift.name : 'Aucun gain';

    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _color.withAlpha((0.08 * 255).round()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withAlpha((0.4 * 255).round()), width: 1.5),
        ),        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _color.withAlpha((0.12 * 255).round()),
              borderRadius: BorderRadius.circular(14),
            ),            child: Center(child: Text(displayIcon,
                style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWin ? '🎉 Félicitations !' : '😔 Pas de chance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _color),
              ),
              const SizedBox(height: 3),
                Text(displayName, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.white)),
              const SizedBox(height: 4),
              isWin
                  ? Text(gift.prixLabel, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.gold))
                    : Text('Retentez votre chance !',
                      style: TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
          )),
        ]),
      ),

      const SizedBox(height: 14),

      if (isWin) ...[
        GoldBtn(
          label: 'Voir mon gain 🎊',
          icon: Icons.emoji_events_rounded,
          onTap: () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => ResultScreen(
              player:      appState.user ?? player,
              dimension:   dimension,
              isWinner:    true,
              prize:       gift,
              tirageId:    tirageId,
              isConverted: isConverted,
            )),
          ),
        ),
      ] else ...[
        GoldBtn(
          label: 'Réessayer',
          icon: Icons.casino_rounded,
          onTap: onRetry,
        ),
        const SizedBox(height: 10),
        OutlineBtn(
          label: "Retour à l'accueil",
          icon: Icons.home_rounded,
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  Pill info
// ─────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final String emoji, label;
  final Color  color;
  const _InfoPill({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withAlpha((0.10 * 255).round()),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha((0.35 * 255).round())),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: TextStyle(fontSize: 15)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}