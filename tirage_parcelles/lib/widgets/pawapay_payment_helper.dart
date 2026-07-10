// lib/widgets/pawapay_payment_helper.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../services/transaction_service.dart';

class PawaPayPaymentHelper {
  PawaPayPaymentHelper._();

  /// Affiche un dialogue de polling qui attend la confirmation du paiement USSD.
  static Future<bool> pollPayment({
    required BuildContext context,
    required String reference,
    String? pinUssd,
  }) async {
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PollingDialog(reference: reference, pinUssd: pinUssd),
    );

    return result ?? false;
  }
}

class _PollingDialog extends StatefulWidget {
  final String reference;
  final String? pinUssd;

  const _PollingDialog({required this.reference, this.pinUssd});

  @override
  State<_PollingDialog> createState() => _PollingDialogState();
}

class _PollingDialogState extends State<_PollingDialog> {
  Timer? _timer;
  String _statusText = 'Veuillez confirmer le paiement sur votre téléphone…';
  bool _checking = false;
  int _attempts = 0;
  static const int _maxAttempts = 24;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _startPolling);
  }

  void _startPolling() {
    if (!mounted) return;
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_checking || !mounted) return;
    _attempts++;
    setState(() => _checking = true);

    try {
      final st = await transactionService.statutPawaPay(widget.reference);
      final statut = st['statut']?.toString() ?? '';

      if (statut == 'success') {
        _timer?.cancel();
        final solde = st['solde'] as int?;
        final tentatives = st['tentatives'] as int?;
        if (solde != null) appState.updateSolde(solde);
        if (tentatives != null) appState.updateTentatives(tentatives);
        await appState.tryRestoreSession();
        if (mounted) Navigator.of(context).pop(true);
        return;
      } else if (statut == 'failed') {
        _timer?.cancel();
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      if (_attempts >= _maxAttempts) {
        _timer?.cancel();
        if (mounted) {
          setState(() => _statusText = 'Délai dépassé. Vérifiez votre historique.');
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      if (mounted) {
        setState(() {
          _statusText = 'En attente de confirmation (${_attempts}/$_maxAttempts)…';
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _pinHint {
    if (widget.pinUssd != null && widget.pinUssd!.isNotEmpty) {
      return 'Composez ${widget.pinUssd} sur votre téléphone et entrez votre code PIN pour valider.';
    }
    return 'Consultez votre téléphone et entrez votre code PIN pour valider.';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Paiement en cours',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(Icons.phone_android_rounded, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _pinHint,
                  style: TextStyle(fontSize: 12, color: AppColors.greyLight, height: 1.5),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.5),
          const SizedBox(height: 14),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop(false);
          },
          child: Text('Fermer', style: TextStyle(color: AppColors.grey)),
        ),
      ],
    );
  }
}
