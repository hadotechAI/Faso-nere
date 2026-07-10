// lib/screens/pack_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../models/pack_model.dart';
import '../models/player_model.dart';
import '../services/packs_service.dart';
import 'payment_screen.dart';

class PackScreen extends StatefulWidget {
  final PlayerModel player;
  const PackScreen({super.key, required this.player});

  @override
  State<PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends State<PackScreen> {
  List<PackModel> _packs = [];
  bool _loading          = true;
  int  _selected         = 0;

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    try {
      final packs = await packsService.getPacks();
      setState(() { _packs = packs; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Obtenir des tentatives',
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _packs.isEmpty
                ? Center(child: Text('Aucun pack disponible',
                  style: TextStyle(color: AppColors.grey)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choisissez un pack pour continuer',
                        style: TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                      const SizedBox(height: 20),

                      ...List.generate(_packs.length, (i) {
                        final pack       = _packs[i];
                        final isSelected = i == _selected;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.gold.withOpacity(0.08)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.gold
                                      : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text(
                                          pack.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? AppColors.gold
                                                : AppColors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (pack.badge != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: pack.isBestValue
                                                  ? AppColors.gold.withOpacity(0.2)
                                                  : AppColors.purple.withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: pack.isBestValue
                                                    ? AppColors.goldDark
                                                    : AppColors.purple,
                                              ),
                                            ),
                                            child: Text(
                                              pack.badge!,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: pack.isBestValue
                                                    ? AppColors.gold
                                                    : AppColors.purpleLight,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                        pack.prixParTentLabel,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  pack.prixLabel,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? AppColors.gold
                                        : AppColors.white,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      DarkCard(
                        color: AppColors.surface2,
                        child: Row(children: [
                          Icon(Icons.security_rounded,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Paiement sécurisé\nVotre paiement est 100% sécurisé.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                  height: 1.5),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      GoldBtn(
                        label: 'Continuer',
                        icon: Icons.arrow_forward_rounded,
                        onTap: _packs.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentScreen(
                                      player: widget.player,
                                      pack:   _packs[_selected],
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}