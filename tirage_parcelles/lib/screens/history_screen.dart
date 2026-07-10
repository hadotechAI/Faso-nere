// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../models/player_model.dart';
import '../services/tirage_service.dart';

enum HistoryFilter { tous, gagnes, perdus }

class HistoryScreen extends StatefulWidget {
  final PlayerModel player;
  const HistoryScreen({super.key, required this.player});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter           _filter     = HistoryFilter.tous;
  List<Map<String, dynamic>> _history = [];
  bool    _loading  = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() { _loading = true; _error = null; });
    try {
      String? filter;
      if (_filter == HistoryFilter.gagnes) filter = 'gagnes';
      if (_filter == HistoryFilter.perdus)  filter = 'perdus';

      final res = await tirageService.getHistorique(filter: filter);
      if (mounted) {
        setState(() {
          _history = (res['tirages'] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Historique des tirages',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.white)),
        const SizedBox(height: 20),

        // Filtres
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: HistoryFilter.values.map((f) {
            final isActive = f == _filter;
            final labels = {
              HistoryFilter.tous:   'Tous',
              HistoryFilter.gagnes: 'Gagnés',
              HistoryFilter.perdus: 'Perdus',
            };
            return GestureDetector(
              onTap: () {
                setState(() => _filter = f);
                _loadHistory();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.gold : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.gold : AppColors.border,
                  ),
                ),
                child: Text(labels[f]!,
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.bg : AppColors.grey)),
              ),
            );
          }).toList()),
        ),

        const SizedBox(height: 20),

        if (_loading)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          )
        else if (_error != null)
          Center(child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(children: [
              Text('😔', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey)),
              const SizedBox(height: 16),
              GoldBtn(label: 'Réessayer', onTap: _loadHistory),
            ]),
          ))
        else if (_history.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Column(children: [
                Text('🎲', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('Aucun résultat',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppColors.white)),
                const SizedBox(height: 6),
                Text('Effectuez des tirages pour voir\nvotre historique ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.grey, height: 1.5)),
              ]),
            ),
          )
        else
          ..._history.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HistoryRow(tirage: t),
          )),

        const SizedBox(height: 24),
      ]),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> tirage;
  const _HistoryRow({required this.tirage});

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}/'
          '${dt.month.toString().padLeft(2,'0')}/'
          '${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:'
          '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final isWin = tirage['is_winner'] as bool? ?? false;
    final nom   = tirage['cadeau_nom'] as String? ?? '—';
    final date  = _formatDate(tirage['created_at'] as String?);
    final lot   = tirage['lot_nom'] as String? ?? '';
    final cat   = tirage['categorie'] as String?;

    String icon = tirage['cadeau_icon'] as String? ?? '🎁';
    if (cat == 'terrain') icon = '🌳';
    else if (cat == 'ciment') icon = '🏗️';
    else if (cat == 'materiaux') icon = '🧱';

    final iconBg    = isWin
      ? AppColors.success.withOpacity(0.15)
      : AppColors.error.withOpacity(0.12);
    final status    = isWin ? 'Gagné' : 'Perdu';
    final statusColor = isWin ? AppColors.success : AppColors.error;

    return DarkCard(
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: iconBg, borderRadius: BorderRadius.circular(12),
          ),
            child: Center(child: Text(icon,
              style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(nom, style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: AppColors.white)),
          const SizedBox(height: 2),
          Text(lot.isNotEmpty ? '$lot · $date' : date,
              style: TextStyle(fontSize: 11, color: AppColors.grey)),
        ])),
        Text(status,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: statusColor)),
      ]),
    );
  }
}