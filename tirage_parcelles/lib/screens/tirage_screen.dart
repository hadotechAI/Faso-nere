// lib/screens/tirage_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../core/ui_components.dart';
import '../models/player_model.dart';
import '../models/dimension_model.dart';
import '../services/tirage_service.dart';
import '../services/api_client.dart';
import 'opening_screen.dart';
import 'pack_screen.dart';

class TirageScreen extends StatefulWidget {
  final PlayerModel player;
  final DimensionModel dimension;
  const TirageScreen({super.key, required this.player, required this.dimension});
  @override
  State<TirageScreen> createState() => _TirageScreenState();
}

class _TirageScreenState extends State<TirageScreen> {
  bool _selecting = false;

  /// Appelé quand l'utilisateur tape sur une boîte.
  /// On envoie la requête au serveur — c'est lui qui décide du cadeau.
  Future<void> _onSelectGift() async {
    if (_selecting) return;
    setState(() => _selecting = true);

    try {
      final result = await tirageService.jouer(
        lotId: widget.dimension.id,
        mode:  'boites',
      );

      // Mettre à jour l'état global
      appState.updateTentatives(result.tentativesRestantes);
      if (result.isWinner) appState.incrementGagnes();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OpeningScreen(
            player:       appState.user ?? widget.player,
            dimension:    widget.dimension,
            selectedGift: result.cadeau,
            isWinner:     result.isWinner,
            tirageId:     result.id,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _selecting = false);

      if (e.statusCode == 402) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Plus de tentatives',
                style: TextStyle(color: AppColors.white)),
            content: Text(e.message,
                style: TextStyle(color: AppColors.grey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler',
                    style: TextStyle(color: AppColors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PackScreen(
                          player: appState.user ?? widget.player),
                    ),
                  );
                },
                child: Text('Acheter un pack'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message),
              backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _selecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final winners = widget.dimension.gifts
        .where((g) => g.isWinner)
        .length;

    return AppScaffold(
      title: 'Choisissez votre cadeau',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(
            'Sélectionnez une boîte parmi ${widget.dimension.cadeaux}'
            ' pour découvrir\nce qu\'elle cache !',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppColors.grey, height: 1.5),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Badge(label: widget.dimension.surface,
                  color: AppColors.gold,
                  bg: AppColors.gold.withOpacity(0.12)),
              _Badge(
                  label:
                      '$winners cadeaux gagnants sur ${widget.dimension.cadeaux}',
                  color: AppColors.success,
                  bg: AppColors.success.withOpacity(0.10)),
            ],
          ),

          const SizedBox(height: 20),

          if (_selecting)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                CircularProgressIndicator(color: AppColors.gold),
                SizedBox(height: 14),
                Text('Tirage en cours…',
                    style: TextStyle(color: AppColors.grey, fontSize: 13)),
              ]),
            )
          else
            // Grille 4×5 (20 boîtes)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: widget.dimension.cadeaux,
              itemBuilder: (_, i) => _GiftBox(
                index: i,
                onTap: _onSelectGift,
              ),
            ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
              child: Row(children: [
              Icon(Icons.emoji_events_rounded,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Gain maximum : ${widget.dimension.prixMaxLabel} FCFA\n'
                'Chance de gagner : '
                '${widget.dimension.chancePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12, color: AppColors.grey, height: 1.5),
              )),
            ]),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Badge ──────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  );
}

// ── Boîte cadeau ───────────────────────────────────────────────
class _GiftBox extends StatefulWidget {
  final int index;
  final VoidCallback onTap;
  const _GiftBox({required this.index, required this.onTap});
  @override
  State<_GiftBox> createState() => _GiftBoxState();
}

class _GiftBoxState extends State<_GiftBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: 1800 + (widget.index * 200) % 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: 1.0 + _pulse.value * 0.025,
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2050), Color(0xFF1E1640)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(color: AppColors.purple.withOpacity(0.2),
                  blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Stack(children: [
            Positioned(top: 6, left: 8,
              child: Text('${widget.index + 1}',
                style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey))),
            Center(child: _GiftImage()),
          ]),
        ),
      ),
    );
  }
}

class _GiftImage extends StatelessWidget {
  const _GiftImage();
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              shape: BoxShape.circle)),
      CustomPaint(size: const Size(44, 44), painter: _GiftPainter()),
    ],
  );
}

class _GiftPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .05, h * .38, w * .9, h * .55),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFF5B2D8E));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, h * .28, w, h * .18),
            const Radius.circular(3)),
        Paint()..color = const Color(0xFF7B3FBE));
    canvas.drawRect(Rect.fromLTWH(w * .44, h * .28, w * .12, h * .65),
        Paint()..color = const Color(0xFFFFB300));
    canvas.drawRect(Rect.fromLTWH(0, h * .33, w, h * .08),
        Paint()..color = const Color(0xFFFFB300));
    canvas.drawOval(Rect.fromLTWH(w * .18, h * .08, w * .24, h * .20),
        Paint()..color = const Color(0xFFFFC300));
    canvas.drawOval(Rect.fromLTWH(w * .58, h * .08, w * .24, h * .20),
        Paint()..color = const Color(0xFFFFC300));
    canvas.drawCircle(Offset(w * .5, h * .18), w * .07,
        Paint()..color = const Color(0xFFFFD700));
  }
  @override
  bool shouldRepaint(_) => false;
}