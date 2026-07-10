import 'dart:math';
import 'package:faso_nere/core/app_state.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../models/player_model.dart';
import '../models/dimension_model.dart';
import '../models/gift_model.dart';
import '../services/api_client.dart';
import '../services/tirage_service.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final PlayerModel player;
  final DimensionModel dimension;
  final bool isWinner;
  final GiftModel prize; // cadeau réellement obtenu
  final String? tirageId;
  final bool isConverted;

  const ResultScreen({
    super.key,
    required this.player,
    required this.dimension,
    required this.isWinner,
    required this.prize,
    this.tirageId,
    this.isConverted = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _entryScale;
  final _pieces = <_Piece>[];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _entryScale = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);
    _entryCtrl.forward();

    _confettiCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5));

    if (widget.isWinner) {
      final rng = Random();
      for (int i = 0; i < 60; i++) {
        _pieces.add(_Piece(
          x: rng.nextDouble(),
          delay: rng.nextDouble() * 0.4,
          size: 5 + rng.nextDouble() * 9,
          color: [AppColors.gold, AppColors.goldLight, Colors.white,
            AppColors.purple, AppColors.warning][rng.nextInt(5)],
          shape: rng.nextBool(),
        ));
      }
      _confettiCtrl.forward();
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(children: [
          if (widget.isWinner)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, _) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ConfettiPainter(_pieces, _confettiCtrl.value),
              ),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: widget.isWinner
                ? _WinContent(
                    player: widget.player,
                    dimension: widget.dimension,
                    prize: widget.prize,
                    scaleAnim: _entryScale,
                    tirageId: widget.tirageId,
                    isConverted: widget.isConverted,
                  )
                : _LoseContent(
                    player: widget.player,
                    dimension: widget.dimension,
                    scaleAnim: _entryScale,
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Contenu GAGNÉ ─────────────────────────────────────────────
class _WinContent extends StatefulWidget {
  final PlayerModel player;
  final DimensionModel dimension;
  final GiftModel prize;
  final Animation<double> scaleAnim;
  final String? tirageId;
  final bool isConverted;

  const _WinContent({
    required this.player,
    required this.dimension,
    required this.prize,
    required this.scaleAnim,
    this.tirageId,
    this.isConverted = false,
  });

  @override
  State<_WinContent> createState() => _WinContentState();
}

class _WinContentState extends State<_WinContent> {
  bool _isConverting = false;
  late bool _isConverted = widget.isConverted;

  String get _prizeEmoji {
    switch (widget.prize.category) {
      case GiftCategory.terrain:   return '🌳';
      case GiftCategory.ciment:    return '🏗️';
      case GiftCategory.materiaux: return '🧱';
      default:                     return '🎁';
    }
  }

  Color get _prizeColor {
    switch (widget.prize.category) {
      case GiftCategory.terrain:   return AppColors.success;
      case GiftCategory.ciment:    return AppColors.warning;
      case GiftCategory.materiaux: return AppColors.purpleLight;
      default:                     return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 20),

      ScaleTransition(
        scale: widget.scaleAnim,
        child: Column(children: [
            Text('Félicitations ! 🎉',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                color: AppColors.gold)),
            const SizedBox(height: 4),
            Text('Vous avez gagné dans le ${widget.dimension.surface} !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.greyLight)),
          const SizedBox(height: 32),

          // Cercle du prix
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _prizeColor.withOpacity(0.28),
                _prizeColor.withOpacity(0.04),
              ]),
              boxShadow: [
                BoxShadow(color: _prizeColor.withOpacity(0.4),
                    blurRadius: 40, spreadRadius: 8),
              ],
            ),
            child: Center(child: Text(_prizeEmoji,
              style: TextStyle(fontSize: 80))),
          ),

          const SizedBox(height: 28),

          // Carte du prix
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: _prizeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _prizeColor.withOpacity(0.4), width: 2),
            ),
            child: Column(children: [
              Text(widget.prize.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: _prizeColor)),
              const SizedBox(height: 6),
              Text(widget.prize.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.grey)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldDark.withOpacity(0.4)),
                ),
                child: Text(widget.prize.prixLabel,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                color: AppColors.gold)),
              ),
            ]),
          ),
        ]),
      ),

      const SizedBox(height: 24),

      DarkCard(
        color: AppColors.surface2,
        child: Column(children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            const SizedBox(height: 10),
            Text("Votre gain est confirmé !",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.white)),
            const SizedBox(height: 6),
            Text('Notre équipe vous contactera bientôt\npour la livraison de votre lot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey, height: 1.5)),
          if (_isConverted) ...[
            const SizedBox(height: 14),
            Text('Le montant a été crédité sur votre solde retraitable.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.success, height: 1.4)),
          ],
        ]),
      ),

      const SizedBox(height: 20),

      if (!_isConverted && widget.tirageId != null) ...[
        GoldBtn(
          label: _isConverting ? 'Conversion en cours…' : 'Créditer mon gain',
          icon: Icons.account_balance_wallet_rounded,
          onTap: _isConverting ? null : _confirmConvert,
        ),
        const SizedBox(height: 12),
      ],

      GoldBtn(label: 'Voir mes gains', icon: Icons.emoji_events_rounded, onTap: () {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => HomeScreen(player: widget.player)), (_) => false);
      }),
      const SizedBox(height: 12),
      OutlineBtn(
        label: 'Partager ma victoire',
        icon: Icons.share_rounded,
        onTap: () {},
      ),
      const SizedBox(height: 32),
    ]);
  }

  Future<void> _convertGain() async {
    if (widget.tirageId == null) return;
    setState(() => _isConverting = true);
    try {
      final res = await tirageService.convertirGain(tirageId: widget.tirageId!);
      if (!mounted) return;
      
      final credit = res['credit_converti'] as int?;
      if (credit != null) {
        appState.updateCreditConverti(credit);
      }

      final message = res['message'] as String?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Gain crédité avec succès.'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _isConverted = true);
    } catch (e) {
      if (!mounted) return;
      final error = e is ApiException ? e.message : 'Impossible de créditer le gain.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  Future<void> _confirmConvert() async {
    if (widget.tirageId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmer la conversion',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Voulez-vous créditer ce gain sur votre solde retraitable ?',
          style: TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.bg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _convertGain();
    }
  }
}

// ── Contenu PERDU ─────────────────────────────────────────────
class _LoseContent extends StatelessWidget {
  final PlayerModel player;
  final DimensionModel dimension;
  final Animation<double> scaleAnim;
  const _LoseContent({required this.player, required this.dimension,
      required this.scaleAnim});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 20),
      ScaleTransition(
        scale: scaleAnim,
        child: Column(children: [
            Text('Pas cette fois 😔',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                color: AppColors.white)),
          const SizedBox(height: 6),
            Text("La boîte ne cachait aucun gain.",
              style: TextStyle(fontSize: 14, color: AppColors.grey)),
          const SizedBox(height: 32),
          Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface2,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Center(child: Text('🎁', style: TextStyle(fontSize: 72))),
          ),
        ]),
      ),

      const SizedBox(height: 28),

      // Rappel des lots disponibles
      DarkCard(
        color: AppColors.surface2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Retentez dans le même lot ou changez !',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.greyLight)),
          const SizedBox(height: 12),
          Row(children: [
            Text('🎁', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text('Petit Lot — jusqu\'à 5 000 000 FCFA',
                style: TextStyle(fontSize: 12, color: AppColors.grey))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('🏆', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text('Gros Lot — jusqu\'à 10 000 000 FCFA',
                style: TextStyle(fontSize: 12, color: AppColors.grey))),
          ]),
        ]),
      ),

      const SizedBox(height: 20),

      GoldBtn(
        label: 'Réessayer',
        icon: Icons.casino_rounded,
        onTap: () => Navigator.pop(context),
      ),
      const SizedBox(height: 12),
      OutlineBtn(
        label: 'Retour à l\'accueil',
        onTap: () => Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => HomeScreen(player: player)), (_) => false),
      ),
      const SizedBox(height: 32),
    ]);
  }
}

// ── Confetti ──────────────────────────────────────────────────
class _Piece {
  final double x, delay, size;
  final Color color;
  final bool shape;
  _Piece({required this.x, required this.delay,
      required this.size, required this.color, required this.shape});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double progress;
  _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final t = ((progress + p.delay) % 1.0);
      final y = t * size.height * 1.4;
      final x = p.x * size.width + sin(t * 10 + p.delay * 4) * 20;
      paint.color = p.color.withOpacity((1 - t * 0.8).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8);
      if (p.shape) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero,
            width: p.size, height: p.size * 0.5), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      }
      canvas.restore();
    }
  }

  @override bool shouldRepaint(_ConfettiPainter old) => true;
}