// lib/screens/payment_screen.dart
import 'package:faso_nere/widgets/pawapay_payment_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../core/ui_components.dart';
import '../models/player_model.dart';
import '../models/pack_model.dart';
import '../services/transaction_service.dart';
import '../services/api_client.dart';
import 'home_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  Choix de la méthode de paiement
// ═══════════════════════════════════════════════════════════════
class PaymentScreen extends StatefulWidget {
  final PlayerModel player;
  final PackModel   pack;
  const PaymentScreen({super.key, required this.player, required this.pack});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _method = 0;
  bool _loadingConfig = true;
  List<_PayMethod> _methods = [];
  final Map<String, Map<String, dynamic>> _providerMeta = {};

  static const _allMethods = {
    'orange_money': _PayMethod(
      icon: '🟠', name: 'orange_money', label: 'Orange Money BF',
      desc: 'Paiement via Orange Money BF',
      imageAsset: 'assets/images/orange_bf.png',
    ),
    'moov_money': _PayMethod(
      icon: '💛', name: 'moov_money', label: 'Moov Money BF',
      desc: 'Paiement via Moov Money BF',
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

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    const ciMethods = ['mtn_ci', 'orange_ci'];
    try {
      final cfg = await transactionService.getPawaPayConfig();
      final providers = (cfg['providers'] as List?) ?? [];
      final methods = <_PayMethod>[];
      _providerMeta.clear();
      for (final raw in providers) {
        final p = Map<String, dynamic>.from(raw as Map);
        final name = p['methode'] as String?;
        if (name != null && _allMethods.containsKey(name)) {
          methods.add(_allMethods[name]!);
          _providerMeta[name] = p;
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
          _methods = methods;
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
  Widget build(BuildContext context) {
    if (_loadingConfig) {
      return AppScaffold(
        title: 'Méthode de paiement',
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    if (_methods.isEmpty) {
      return AppScaffold(
        title: 'Méthode de paiement',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucun opérateur mobile activé sur PawaPay.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Méthode de paiement',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sélectionnez votre moyen de paiement',
              style: TextStyle(fontSize: 14, color: AppColors.grey)),
          const SizedBox(height: 20),

          ...List.generate(_methods.length, (i) {
            final m = _methods[i];
            final isSelected = i == _method;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _method = i),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withOpacity(0.05)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: m.imageAsset != null
                          ? Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset(m.imageAsset!, fit: BoxFit.contain),
                            )
                          : Center(child: Text(m.icon,
                                style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(m.label,
                          style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white)),
                      const SizedBox(height: 2),
                        Text(m.desc,
                          style: TextStyle(
                            fontSize: 12, color: AppColors.grey)),
                    ])),
                      Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.grey, size: 14),
                  ]),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
            Row(children: [
            Expanded(child: _TrustItem(
              icon: Icons.shield_outlined,
              label: 'Sécurisé', sub: 'Transactions protégées')),
            const SizedBox(width: 12),
            Expanded(child: _TrustItem(
              icon: Icons.flash_on_rounded,
              label: 'Rapide', sub: 'Paiement instantané')),
            ]),

          const SizedBox(height: 24),

          GoldBtn(
            label: 'Continuer',
            icon: Icons.arrow_forward_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ConfirmPaymentScreen(
                player:     widget.player,
                pack:       widget.pack,
                methodName: _methods[_method].name,
                methodLabel:_methods[_method].label,
                pinUssd:    _providerMeta[_methods[_method].name]?['pin_ussd'] as String?,
                defaultPhone: _providerMeta[_methods[_method].name]?['sandbox_test_msisdn'] as String?
                    ?? widget.player.telephone,
              ),
            )),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _PayMethod {
  final String icon, name, label, desc;
  final String? imageAsset;
  const _PayMethod({required this.icon, required this.name,
      required this.label, required this.desc, this.imageAsset});
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _TrustItem({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => DarkCard(
    color: AppColors.surface2,
    child: Row(children: [
      Icon(icon, color: AppColors.success, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w700, color: AppColors.white)),
        Text(sub, style: TextStyle(fontSize: 10, color: AppColors.grey)),
      ]),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
//  Confirmation + OTP
// ═══════════════════════════════════════════════════════════════
class ConfirmPaymentScreen extends StatefulWidget {
  final PlayerModel player;
  final PackModel   pack;
  final String      methodName;
  final String      methodLabel;
  final String?     pinUssd;
  final String      defaultPhone;
  const ConfirmPaymentScreen({
    super.key,
    required this.player,
    required this.pack,
    required this.methodName,
    required this.methodLabel,
    this.pinUssd,
    required this.defaultPhone,
  });
  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  late final TextEditingController _numeroDepotCtrl;
  late final TextEditingController _otpCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _numeroDepotCtrl = TextEditingController(text: widget.defaultPhone);
    _otpCtrl = TextEditingController();
  }

  String _fmt(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  void dispose() {
    _numeroDepotCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
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

  Future<void> _pay() async {

    final depot = _numeroDepotCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    // Validation : OTP obligatoire pour Orange Money
    if (widget.methodName == 'orange_money' && _otpCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Composez le *144*4*6*${widget.pack.prix}# sur votre téléphone, puis entrez le code reçu.',
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      String phone = depot.isEmpty ? widget.player.telephone : depot;
      phone = phone.replaceAll('+', '').replaceAll(' ', '');
      if (widget.methodName.endsWith('_ci')) {
        if (!phone.startsWith('225')) phone = '225$phone';
      } else {
        if (!phone.startsWith('226')) phone = '226$phone';
      }

      final preAuthCode = _otpCtrl.text.trim();

      final response = await transactionService.initierPackPawaPay(
        packId:  widget.pack.id,
        methode: widget.methodName,
        telephonePaiement: phone,
        preAuthCode: preAuthCode.isNotEmpty ? preAuthCode : null,
      );

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
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(player: appState.user ?? widget.player),
          ),
          (_) => false,
        );
        return;
      }

      if (!mounted) return;

      final success = await PawaPayPaymentHelper.pollPayment(
        context: context,
        reference: reference,
        pinUssd: widget.pinUssd,
      );
      if (success == true) {
        // Mettre à jour l'état de l'utilisateur pour afficher le nouveau nombre de tentatives
        await appState.tryRestoreSession();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(player: appState.user ?? widget.player),
          ),
          (_) => false,
        );
      } else {
         messenger.showSnackBar(
           SnackBar(content: Text('Paiement annulé ou échoué.'), backgroundColor: AppColors.error),
         );
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
        SnackBar(content: Text('Erreur inattendue: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Confirmation',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),

          // Résumé pack
          DarkCard(
            color: AppColors.surface2,
            child: Column(children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                    child: Icon(Icons.casino_outlined,
                      color: AppColors.gold, size: 24),
                ),
                  const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text('${widget.pack.tentatives} tentatives',
                      style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white)),
                  if (widget.pack.badge != null)
                    Text(widget.pack.badge!,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.gold)),
                ])),
                Text('${_fmt(widget.pack.prix)} FCFA',
                  style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold)),
              ]),
              const SizedBox(height: 14),
              const AppDivider(),
              const SizedBox(height: 14),
                Row(children: [
                Icon(Icons.payment_rounded,
                  color: AppColors.grey, size: 16),
                const SizedBox(width: 8),
                Text('Via ${widget.methodLabel}',
                  style: TextStyle(
                    fontSize: 13, color: AppColors.greyLight)),
                ]),
            ]),
          ),

          const SizedBox(height: 24),

          DarkCard(
            color: AppColors.surface2,
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Confirmez le paiement sur votre téléphone (invite USSD ou push notification).',
                style: TextStyle(
                    fontSize: 12, color: AppColors.grey, height: 1.5),
              )),
            ]),
          ),

          const SizedBox(height: 24),
          TextField(
            controller: _numeroDepotCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppColors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Numéro de paiement',
              hintText: widget.methodName.endsWith('_ci')
                  ? 'Ex : 2250701234567'
                  : 'Ex : 22670123456',
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

          if (widget.methodName == 'orange_money') ...[
            const SizedBox(height: 16),
            DarkCard(
              color: AppColors.gold.withOpacity(0.1),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Composez le *144*4*6*${widget.pack.prix}# sur votre téléphone pour générer votre code OTP de paiement, puis saisissez-le ci-dessous.',
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

          const SizedBox(height: 24),

          _loading
              ? CircularProgressIndicator(color: AppColors.gold)
              : GoldBtn(
                  label: 'Confirmer le paiement',
                  icon: Icons.payment_rounded,
                  onTap: _pay,
                ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}