// lib/screens/wallet_screen.dart
import 'package:faso_nere/widgets/pawapay_payment_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../core/ui_components.dart';
import '../models/player_model.dart';
import '../services/notification_service.dart';
import '../services/transaction_service.dart';
import '../services/api_client.dart';

// ═══════════════════════════════════════════════════════════════
//  ÉCRAN DÉPÔT
// ═══════════════════════════════════════════════════════════════
class DepotScreen extends StatefulWidget {
  final PlayerModel player;
  const DepotScreen({super.key, required this.player});
  @override
  State<DepotScreen> createState() => _DepotScreenState();
}

class _DepotScreenState extends State<DepotScreen> {
  final _montantCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  int  _methodIndex  = 0;
  bool _loading      = false;
  bool _loadingConfig = true;
  List<_PayMethod> _methods = [];
  String? _pinUssd;

  final _quickAmounts = [10000, 25000, 50000, 100000];

  static const _allMethods = {
    'orange_money': _PayMethod(
      icon: '🟠', name: 'orange_money', label: 'Orange Money BF',
      desc: '*144*1*5*montant#',
      imageAsset: 'assets/images/orange_bf.png',
    ),
    'moov_money': _PayMethod(
      icon: '💛', name: 'moov_money', label: 'Moov Money BF',
      desc: '*555*6# puis PIN',
      imageAsset: 'assets/images/moov_bf.png',
    ),
    'mtn_ci': _PayMethod(
      icon: '💛', name: 'mtn_ci', label: 'MTN Mobile Money CI',
      desc: 'Paiement via MTN Côte d\'Ivoire',
      imageAsset: 'assets/images/mtn-mobile-money-logo.png',
    ),
    'orange_ci': _PayMethod(
      icon: '🟠', name: 'orange_ci', label: 'Orange Money CI',
      desc: 'Paiement via Orange Côte d\'Ivoire',
      imageAsset: 'assets/images/orange_bf.png',
    ),
  };

  int get _montant =>
      int.tryParse(_montantCtrl.text.replaceAll(' ', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.player.telephone;
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    // Méthodes CI toujours disponibles (indépendant de la config PawaPay)
    const ciMethods = ['mtn_ci', 'orange_ci'];

    try {
      final cfg = await transactionService.getPawaPayConfig();
      final providers = (cfg['providers'] as List?) ?? [];
      final methods = <_PayMethod>[];
      String? pin;
      for (final raw in providers) {
        final p = Map<String, dynamic>.from(raw as Map);
        final name = p['methode'] as String?;
        if (name != null && _allMethods.containsKey(name)) {
          methods.add(_allMethods[name]!);
          if (methods.length == 1) {
            pin = p['pin_ussd'] as String?;
          }
        }
      }
      // Ajouter les méthodes CI si pas déjà présentes via la config
      for (final ci in ciMethods) {
        if (!methods.any((m) => m.name == ci)) {
          methods.add(_allMethods[ci]!);
        }
      }
      if (mounted) {
        setState(() {
          _methods = methods.isNotEmpty ? methods : [_allMethods['moov_money']!];
          _pinUssd = pin;
          _loadingConfig = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _methods = [
            _allMethods['moov_money']!,
            _allMethods['orange_money']!,
            _allMethods['mtn_ci']!,
            _allMethods['orange_ci']!,
          ];
          _loadingConfig = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  void _showUnavailableDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.gold),
            const SizedBox(width: 10),
            Text('Indisponible', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: TextStyle(color: AppColors.grey, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Compris', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  Future<void> _continuer() async {

    if (_montant < 25000) {
      _snack('Montant minimum : 25 000 FCFA', isError: true);
      return;
    }
    if (_montant % 5 != 0) {
      _snack('Le montant doit être un multiple de 5', isError: true);
      return;
    }
    
    final method = _methods[_methodIndex].name;
    final messenger = ScaffoldMessenger.of(context);

    // Validation OTP pour Orange
    if (method == 'orange_money' && _otpCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Composez le *144*4*6*$_montant# sur votre téléphone, puis entrez le code reçu.',
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      final preAuthCode = _otpCtrl.text.trim();
      
      String phone = _phoneCtrl.text.trim().replaceAll('+', '').replaceAll(' ', '');
      if (method.endsWith('_ci')) {
        if (!phone.startsWith('225')) phone = '225$phone';
      } else {
        if (!phone.startsWith('226')) phone = '226$phone';
      }

      final response = await transactionService.initierDepotPawaPay(
        montant: _montant,
        methode: method,
        telephonePaiement: phone,
        preAuthCode: preAuthCode.isNotEmpty ? preAuthCode : null,
      );
      if (!mounted) return;

      final reference = response['reference'] as String?;
      if (reference == null) {
        throw const ApiException(
          statusCode: 400,
          message: 'Impossible d\'initier le paiement.',
        );
      }

      final initStatut = response['statut'] as String?;
      if (initStatut == 'success') {
        await appState.tryRestoreSession();
        _showSuccessSheet(_montant);
        return;
      }

      final success = await PawaPayPaymentHelper.pollPayment(
        context: context,
        reference: reference,
        pinUssd: _pinUssd,
      );
      if (success == true) {
        _showSuccessSheet(_montant);
      } else {
        _snack('Paiement annulé ou échoué.', isError: true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 503) {
        _showUnavailableDialog(e.message);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessSheet(int montant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Dépôt réussi !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.white)),
          const SizedBox(height: 6),
          Text('${_fmt(montant)} FCFA ont été crédités\nsur votre portefeuille.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.grey, height: 1.5)),
          const SizedBox(height: 24),
          GoldBtn(
            label: 'Retour à l\'accueil',
            onTap: () { Navigator.pop(context); Navigator.pop(context); },
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingConfig) {
      return AppScaffold(
        title: 'Dépôt',
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final currentSolde = appState.user?.solde ?? widget.player.solde;

    return AppScaffold(
      title: 'Dépôt',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Solde actuel
          DarkCard(
            color: AppColors.surface2,
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                    child: Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.success, size: 22)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Solde actuel',
                  style: TextStyle(fontSize: 12, color: AppColors.grey)),
                Text('${_fmt(currentSolde)} FCFA',
                  style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: AppColors.white)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // Montant
            Text('Montant à déposer',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.greyLight)),
          const SizedBox(height: 10),
          TextField(
            controller: _montantCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppColors.white, fontSize: 22,
                fontWeight: FontWeight.w800),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.grey, fontSize: 22),
              suffixText: 'FCFA',
                suffixStyle: TextStyle(
                  color: AppColors.grey, fontSize: 14,
                  fontWeight: FontWeight.w600),
              filled: true, fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.gold, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),

          // Montants rapides
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _quickAmounts.map((amt) {
              final isSelected = _montant == amt;
              return GestureDetector(
                onTap: () {
                  _montantCtrl.text = amt.toString();
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text('${_fmt(amt)} F',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.greyLight)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Méthode
            Text('Méthode de paiement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.greyLight)),
          const SizedBox(height: 10),
          ...List.generate(_methods.length, (i) {
            final m = _methods[i];
            final isSelected = i == _methodIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _methodIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withOpacity(0.06)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Container(width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: m.imageAsset != null 
                            ? Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(m.imageAsset!, fit: BoxFit.contain),
                              )
                            : Center(child: Text(m.icon,
                                      style: TextStyle(fontSize: 20)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(m.label, style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: AppColors.white)),
                      const SizedBox(height: 2),
                        Text(m.desc, style: TextStyle(
                          fontSize: 11, color: AppColors.grey)),
                    ])),
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.gold : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 12, color: AppColors.bg)
                          : null,
                    ),
                  ]),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
            Text('Numéro de paiement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.greyLight)),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppColors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: (_methods.isNotEmpty && _methods[_methodIndex].name.endsWith('_ci'))
                  ? '2250701234567'
                  : '22670123456',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
            ),
          ),

          if (_methods.isNotEmpty && _methods[_methodIndex].name == 'orange_money') ...[
            const SizedBox(height: 16),
            DarkCard(
              color: AppColors.gold.withOpacity(0.1),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Composez le *144*4*6*${_montant > 0 ? _montant : 'montant'}# sur votre téléphone pour générer votre code OTP de paiement, puis saisissez-le ci-dessous.',
                  style: TextStyle(fontSize: 12, color: AppColors.gold, height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: AppColors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Code de paiement (OTP)',
                hintText: 'Code généré par Orange',
                labelStyle: TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
              ),
            ),
          ],

          const SizedBox(height: 8),
          DarkCard(
            color: AppColors.surface2,
            child: Row(children: [
              Icon(Icons.shield_outlined, color: AppColors.success, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Paiement mobile sécurisé · BF & CI (PawaPay)',
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              )),
            ]),
          ),
          const SizedBox(height: 24),

            _loading
              ? Center(child: CircularProgressIndicator(
                color: AppColors.gold))
              : GoldBtn(
                  label: _montant > 0
                      ? 'Déposer ${_fmt(_montant)} FCFA'
                      : 'Déposer',
                  icon: Icons.arrow_downward_rounded,
                  onTap: _montant >= 25000 ? _continuer : null,
                ),

          const SizedBox(height: 10),
            Center(child: Text('Minimum : 25 000 FCFA',
              style: TextStyle(fontSize: 11, color: AppColors.grey))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ÉCRAN RETRAIT
// ═══════════════════════════════════════════════════════════════
class RetraitScreen extends StatefulWidget {
  final PlayerModel player;
  const RetraitScreen({super.key, required this.player});
  @override
  State<RetraitScreen> createState() => _RetraitScreenState();
}

class _RetraitScreenState extends State<RetraitScreen> {
  final _montantCtrl = TextEditingController();
  final _numeroCtrl  = TextEditingController();
  int  _methodIndex  = 0;
  bool _loading      = false;

  final _quickAmounts = [5000, 10000, 25000];

  static const _methods = [
    _PayMethod(icon: '🟠', name: 'orange_money',      label: 'Orange Money BF',       desc: 'Retrait vers Orange Money BF', imageAsset: 'assets/images/orange_bf.png'),
    _PayMethod(icon: '💛', name: 'moov_money',        label: 'Moov Money BF',         desc: 'Retrait vers Moov Money BF', imageAsset: 'assets/images/moov_bf.png'),
    _PayMethod(icon: '💛', name: 'mtn_ci',            label: 'MTN Mobile Money CI',   desc: 'Retrait vers MTN Côte d\'Ivoire', imageAsset: 'assets/images/mtn-mobile-money-logo.png'),
    _PayMethod(icon: '🟠', name: 'orange_ci',         label: 'Orange Money CI',       desc: 'Retrait vers Orange Côte d\'Ivoire', imageAsset: 'assets/images/orange_bf.png'),
    _PayMethod(icon: '🏦', name: 'carte_bancaire',    label: 'Virement bancaire (Indisponible)',     desc: 'Vers votre compte bancaire', isAvailable: false),
  ];

  int get _montant =>
      int.tryParse(_montantCtrl.text.replaceAll(' ', '')) ?? 0;
  int get _creditConverti => appState.user?.creditConverti ?? widget.player.creditConverti;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _numeroCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  void _showUnavailableDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.gold),
            const SizedBox(width: 10),
            Text('Indisponible', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: TextStyle(color: AppColors.grey, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Compris', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  Future<void> _continuer() async {
    if (_montant < 1000) {
      _snack('Montant minimum : 1 000 FCFA', isError: true); return;
    }
    if (_montant > _creditConverti) {
      _snack('Gains insuffisants', isError: true); return;
    }
    if (_numeroCtrl.text.trim().length < 8) {
      _snack('Numéro de réception invalide', isError: true); return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Attention', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Selon les règles, retirer de l\'argent entraînera la déduction d\'un nombre équivalent de tentatives de votre compte.\n\nVoulez-vous vraiment continuer ?',
          style: TextStyle(color: AppColors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text('Continuer', style: TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      String phone = _numeroCtrl.text.trim().replaceAll('+', '').replaceAll(' ', '');
      String methodeName = _methods[_methodIndex].name;
      
      if (methodeName.endsWith('_ci')) {
        if (!phone.startsWith('225')) phone = '225$phone';
      } else {
        if (!phone.startsWith('226')) phone = '226$phone';
      }

      final response = await transactionService.initierRetrait(
        montant:         _montant,
        methode:         methodeName,
        numeroReception: phone,
      );
      if (!mounted) return;
      final otpCode = response['otp_code'] as String?;
      if (otpCode != null && otpCode.isNotEmpty) {
        await notificationService.showOtp(otpCode);
      } else {
        await notificationService.showSysteme(
          'OTP envoyé',
          'Votre code OTP a été envoyé dans vos notifications.',
        );
      }
      final success = await _showOtpDialog();
      if (success == true) {
        _showSuccessSheet(_montant);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 503) {
        _showUnavailableDialog(e.message);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(e.message),
              backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _showOtpDialog() async {
    final otpCtrl = TextEditingController();
    bool validating = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, set) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmation OTP',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Un code OTP a été envoyé (SMS ou notification).',
              style: TextStyle(color: AppColors.grey, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppColors.white, fontSize: 22,
                fontWeight: FontWeight.w800, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '000000', counterText: '',
              hintStyle: TextStyle(color: AppColors.grey),
              filled: true, fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.gold, width: 1.5)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: validating ? null : () => Navigator.pop(ctx2, false),
            child: Text('Annuler',
              style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: validating ? null : () async {
              final messenger = ScaffoldMessenger.of(context);
              set(() => validating = true);
              try {
                final result = await transactionService.confirmerRetrait(
                  montant:         _montant,
                  methode:         _methods[_methodIndex].name,
                  numeroReception: _numeroCtrl.text.trim(),
                  otpCode:         otpCtrl.text.trim(),
                );
                appState.updateSolde(result['solde'] as int);
                appState.updateCreditConverti(result['credit_converti'] as int);
                appState.updateTentatives(result['tentatives'] as int);
                if (!mounted) return;
                await notificationService.show(
                  titre: '💸 Retrait initié',
                  message: 'Retrait de ${_fmt(_montant)} FCFA en cours de transfert vers ${_numeroCtrl.text.trim()}.',
                  type: 'paiement',
                );
                Navigator.pop(ctx2, true);
              } on ApiException catch (e) {
                set(() => validating = false);
                if (!mounted) return;
                if (e.statusCode == 503) {
                  Navigator.pop(ctx2); // fermer la popup otp
                  _showUnavailableDialog(e.message);
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(e.message),
                        backgroundColor: AppColors.error),
                  );
                }
              } catch (e) {
                set(() => validating = false);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Erreur inattendue : $e'),
                      backgroundColor: AppColors.error),
                );
              }
            },
            child: validating
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Valider'),
          ),
        ],
      )),
    );
    otpCtrl.dispose();
    return result;
  }

  void _showSuccessSheet(int montant) {
    final isAuto = montant < 25000;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
                child: Icon(Icons.check_circle_rounded,
                  color: AppColors.gold, size: 36)),
          const SizedBox(height: 16),
            Text(isAuto ? 'Virement en cours !' : 'Retrait initié !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.white)),
          const SizedBox(height: 6),
            Text(
              isAuto
                ? '${_fmt(montant)} FCFA seront transférés\nsous 5 à 10 minutes.'
                : '${_fmt(montant)} FCFA seront traités\npar un administrateur sous 24h.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, color: AppColors.grey, height: 1.5)),
          const SizedBox(height: 24),
          GoldBtn(
            label: 'Retour à l\'accueil',
            onTap: () { Navigator.pop(context); Navigator.pop(context); },
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Retrait',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Solde dispo
          DarkCard(
            color: AppColors.surface2,
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                    child: Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.gold, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Gains retraitables',
                          style: TextStyle(fontSize: 12, color: AppColors.grey)),
                Text('${_fmt(_creditConverti)} FCFA',
                  style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: AppColors.white)),
              ])),
              GestureDetector(
                onTap: () {
                  _montantCtrl.text = _creditConverti.toString();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.goldDark.withOpacity(0.4)),
                  ),
                    child: Text('Tout retirer',
                      style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Montant
            Text('Montant à retirer',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.greyLight)),
          const SizedBox(height: 10),
          TextField(
            controller: _montantCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppColors.white, fontSize: 22,
                fontWeight: FontWeight.w800),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.grey, fontSize: 22),
              suffixText: 'FCFA',
              suffixStyle: TextStyle(color: AppColors.grey,
                  fontSize: 14, fontWeight: FontWeight.w600),
              errorText: _montant > _creditConverti ? 'Gains insuffisants' : null,
              filled: true, fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.gold, width: 1.5)),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.error, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 8, runSpacing: 8,
            children: _quickAmounts.map((amt) {
              final isSelected = _montant == amt;
              final disabled   = amt > _creditConverti;
              return GestureDetector(
                onTap: disabled ? null : () {
                  _montantCtrl.text = amt.toString();
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: disabled
                          ? AppColors.border.withOpacity(0.4)
                          : isSelected ? AppColors.gold : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text('${_fmt(amt)} F',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? AppColors.grey.withOpacity(0.4)
                              : isSelected
                                  ? AppColors.gold
                                  : AppColors.greyLight)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Méthode
            Text('Méthode de retrait',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.greyLight)),
          const SizedBox(height: 10),
          ...List.generate(_methods.length, (i) {
            final m = _methods[i];
            final isSelected = i == _methodIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: m.isAvailable ? () => setState(() => _methodIndex = i) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: m.isAvailable
                        ? (isSelected ? AppColors.gold.withOpacity(0.06) : AppColors.surface)
                        : AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border.withOpacity(m.isAvailable ? 1 : 0.5),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Container(width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: m.imageAsset != null 
                            ? Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(m.imageAsset!, fit: BoxFit.contain),
                              )
                            : Center(child: Text(m.icon,
                                      style: TextStyle(fontSize: 20)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(m.label, style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: m.isAvailable ? AppColors.white : AppColors.greyLight,
                          decoration: m.isAvailable ? null : TextDecoration.lineThrough,
                        )),
                      const SizedBox(height: 2),
                        Text(m.desc, style: TextStyle(
                          fontSize: 11, color: AppColors.grey)),
                    ])),
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.gold : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                                ? Icon(Icons.check, size: 12,
                                  color: AppColors.bg)
                          : null,
                    ),
                  ]),
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          // Numéro de réception
            Text('Numéro de réception',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.greyLight)),
          const SizedBox(height: 10),
          TextField(
            controller: _numeroCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
            ],
            style: TextStyle(color: AppColors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: _methods[_methodIndex].name.endsWith('_ci')
                  ? '+225 •• •• •• •• ••'
                  : '+226 •• •• •• ••',
              hintStyle: TextStyle(color: AppColors.grey),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _methods[_methodIndex].name.endsWith('_ci') ? '🇨🇮' : '🇧🇫',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _methods[_methodIndex].name.endsWith('_ci') ? '+225' : '+226',
                      style: TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                  ]),
              ),
              filled: true, fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.gold, width: 1.5)),
            ),
          ),
          const SizedBox(height: 24),

          _loading
                ? Center(child: CircularProgressIndicator(
                  color: AppColors.gold))
              : GoldBtn(
                  label: _montant > 0
                      ? 'Retirer ${_fmt(_montant)} FCFA'
                      : 'Retirer',
                  icon: Icons.arrow_upward_rounded,
                  onTap: (_montant >= 1000 && _montant <= _creditConverti)
                      ? _continuer
                      : null,
                ),

          const SizedBox(height: 10),
              Center(
              child: Text(
                'Minimum : 1 000 FCFA · < 25 000 FCFA : automatique · ≥ 25 000 FCFA : sous 24h',
                style: TextStyle(fontSize: 11, color: AppColors.grey)),
              ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────
class _PayMethod {
  final String icon, name, label, desc;
  final String? imageAsset;
  final bool isAvailable;
  const _PayMethod({required this.icon, required this.name,
      required this.label, required this.desc, this.imageAsset, this.isAvailable = true});
}

String _fmt(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');