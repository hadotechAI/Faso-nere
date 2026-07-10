// lib/screens/opening_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/player_model.dart';
import '../models/dimension_model.dart';
import '../models/gift_model.dart';
import 'result_screen.dart';

class OpeningScreen extends StatefulWidget {
  final PlayerModel    player;
  final DimensionModel dimension;
  final GiftModel      selectedGift;
  final bool           isWinner;
  final String?        tirageId;

  const OpeningScreen({
    super.key,
    required this.player,
    required this.dimension,
    required this.selectedGift,
    required this.isWinner,
    this.tirageId,
  });

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _explodeCtrl;
  late final Animation<double>   _shake;
  late final Animation<double>   _scale;
  late final Animation<double>   _explode;

  bool _exploded = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _scaleCtrl   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _explodeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));

    _shake   = Tween(begin: -8.0, end: 8.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);
    _scale   = Tween(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
    _explode = CurvedAnimation(parent: _explodeCtrl, curve: Curves.easeOut);

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _shakeCtrl.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _shakeCtrl.stop(); _shakeCtrl.value = 0;

    await _scaleCtrl.forward();
    if (!mounted) return;

    setState(() => _exploded = true);
    _explodeCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ResultScreen(
        player:      widget.player,
        dimension:   widget.dimension,
        isWinner:    widget.isWinner,
        prize:       widget.selectedGift,
        tirageId:    widget.tirageId,
        isConverted: false,
      ),
    ));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _scaleCtrl.dispose();
    _explodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(children: [
          if (_exploded)
            AnimatedBuilder(
              animation: _explode,
              builder: (_, _) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ExplosionPainter(_explode.value, widget.isWinner),
              ),
            ),
            Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Ouverture en cours...',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.white)),
              const SizedBox(height: 8),
              Text('Découvrons ensemble !',
                style: TextStyle(fontSize: 14, color: AppColors.grey)),
              const SizedBox(height: 60),

              AnimatedBuilder(
                animation: Listenable.merge([_shakeCtrl, _scaleCtrl]),
                builder: (_, _) => Transform.translate(
                  offset: Offset(_exploded ? 0 : _shake.value, 0),
                  child: Transform.scale(
                    scale: _exploded ? _scale.value : 1.0,
                    child: _exploded ? _ExplodedGift() : _ClosedGiftLarge(),
                  ),
                ),
              ),

              const SizedBox(height: 60),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🍀 ', style: TextStyle(fontSize: 18)),
                Text('Bonne chance !',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.white)),
                Text(' 🍀', style: TextStyle(fontSize: 18)),
              ]),
                const SizedBox(height: 8),
                Text('Que la chance soit avec vous !',
                  style: TextStyle(fontSize: 13, color: AppColors.grey)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ClosedGiftLarge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 160, height: 160,
    decoration: BoxDecoration(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.borderLight, width: 2),
      boxShadow: [
        BoxShadow(color: AppColors.purple.withOpacity(0.4),
            blurRadius: 30, spreadRadius: 5),
      ],
    ),
    child: const Center(child: Text('🎁', style: TextStyle(fontSize: 72))),
  );
}

class _ExplodedGift extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 180, height: 180,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.gold.withOpacity(0.1),
      boxShadow: [
        BoxShadow(color: AppColors.gold.withOpacity(0.5),
            blurRadius: 50, spreadRadius: 10),
      ],
    ),
    child: const Center(child: Text('✨', style: TextStyle(fontSize: 80))),
  );
}

class _ExplosionPainter extends CustomPainter {
  final double progress;
  final bool   isWinner;
  _ExplosionPainter(this.progress, this.isWinner);

  @override
  void paint(Canvas canvas, Size size) {
    final rng    = Random(42);
    final paint  = Paint();
    final colors = isWinner
        ? [AppColors.gold, AppColors.goldLight, Colors.white, AppColors.warning]
        : [AppColors.purple, AppColors.purpleLight, AppColors.grey];
    final cx = size.width / 2; final cy = size.height / 2;

    for (int i = 0; i < 60; i++) {
      final angle  = (i / 60) * 2 * pi + rng.nextDouble() * 0.3;
      final radius = progress * (100 + rng.nextDouble() * 200);
      final x = cx + cos(angle) * radius;
      final y = cy + sin(angle) * radius;
      final r = 3 + rng.nextDouble() * 6;
      paint.color = colors[i % colors.length]
          .withOpacity((1 - progress).clamp(0, 1));
      canvas.drawCircle(Offset(x, y), r * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ExplosionPainter old) => old.progress != progress;
}