// lib/widgets/promo_code_widget.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/api_client.dart';
import '../models/player_model.dart';
import '../core/app_state.dart';

class PromoCodeWidget extends StatefulWidget {
  final PlayerModel player;
  const PromoCodeWidget({super.key, required this.player});

  @override
  State<PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _redeemPromo() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final res = await api.post('/users/me/redeem-promo', {'code': code});
      final added = res['tentatives_offertes'] ?? 0;
      
      // Mettre à jour l'état local du joueur avec les nouvelles tentatives
      final updatedPlayer = widget.player.copyWith(
        tentatives: widget.player.tentatives + (added as int),
      );
      
      // Actualiser globalement
      appState.setUser(updatedPlayer);
      
      setState(() {
        _success = res['message'] ?? 'Code validé avec succès !';
        _codeCtrl.clear();
      });

      // Petite notification Snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $_success'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Erreur lors de la validation du code');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avez-vous un code promo ?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ENTRER LE CODE',
              hintStyle: TextStyle(color: AppColors.grey, fontSize: 12),
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _redeemPromo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _loading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Valider', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          if (_success != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_success!, style: TextStyle(color: AppColors.success, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
