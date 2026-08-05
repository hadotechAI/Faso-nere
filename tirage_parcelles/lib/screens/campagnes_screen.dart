// lib/screens/campagnes_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/campagnes_service.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';
import '../widgets/pawapay_payment_helper.dart';

class CampagnesScreen extends StatefulWidget {
  const CampagnesScreen({super.key});

  @override
  State<CampagnesScreen> createState() => _CampagnesScreenState();
}

class _CampagnesScreenState extends State<CampagnesScreen> {
  List<Map<String, dynamic>> _campagnes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await campagnesService.getCampagnes();
      if (mounted) setState(() { _campagnes = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Souscriptions Terrain'),
        backgroundColor: AppColors.bg,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _campagnes.isEmpty
                      ? const _EmptyView()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _campagnes.length,
                          itemBuilder: (ctx, i) => _CampagneCard(
                            campagne: _campagnes[i],
                            onSouscrit: _load,
                          ),
                        ),
                ),
    );
  }
}

// ── Carte campagne ───────────────────────────────────────────
class _CampagneCard extends StatefulWidget {
  final Map<String, dynamic> campagne;
  final VoidCallback onSouscrit;
  const _CampagneCard({required this.campagne, required this.onSouscrit});

  @override
  State<_CampagneCard> createState() => _CampagneCardState();
}

class _CampagneCardState extends State<_CampagneCard> {
  bool _subscribing = false;

  Map<String, dynamic> get c => widget.campagne;

  Future<void> _souscrireWallet() async {
    // Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirmer la souscription',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Souscrire à "${c['titre']}" pour ${_fmtMontant(c['frais_souscription'])} FCFA ?\n'
          'Ce montant sera débité de votre portefeuille retraitable.',
          style: TextStyle(color: AppColors.greyLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _subscribing = true);
    try {
      await campagnesService.souscrire(c['id'].toString());
      if (mounted) {
        _showSnack('✅ Souscription réussie ! Bonne chance 🤞', isError: false);
        await authService.tryRestoreSession();
        widget.onSouscrit();
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  void _souscrire() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SouscriptionSheet(
        campagne: c,
        onSouscrireWallet: () {
          Navigator.pop(context);
          _souscrireWallet();
        },
        onSouscrirePawaPay: (methode, phone, otp) {
          Navigator.pop(context);
          _initierPawaPay(methode, phone, otp);
        },
      ),
    );
  }

  Future<void> _initierPawaPay(String methode, String phone, String? otp) async {
    setState(() => _subscribing = true);
    try {
      final res = await transactionService.initierSouscriptionPawaPay(
        campagneId: c['id'].toString(),
        methode: methode,
        telephonePaiement: phone,
        preAuthCode: otp,
      );
      if (!mounted) return;
      
      final ref = res['reference'] as String?;
      if (ref == null) throw Exception("Pas de référence PawaPay");

      if (res['statut'] == 'success') {
        _showSnack('✅ Souscription réussie ! Bonne chance 🤞', isError: false);
        await authService.tryRestoreSession();
        widget.onSouscrit();
        return;
      }

      final success = await PawaPayPaymentHelper.pollPayment(context: context, reference: ref);
      if (success == true) {
        _showSnack('✅ Souscription réussie ! Bonne chance 🤞', isError: false);
        await authService.tryRestoreSession();
        widget.onSouscrit();
      } else {
        _showSnack('Paiement annulé ou échoué.', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _openDetail() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CampagneDetailScreen(campagneId: c['id'].toString()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool aSouscrit   = c['a_souscrit'] == true;
    final bool tirageEffec = c['tirage_effectue'] == true;
    final bool isCommercial = c['type_terrain'] == 'commercial';
    final dateFin           = _parseDate(c['date_fin']);
    final isExpired         = dateFin != null && dateFin.isBefore(DateTime.now());
    final baseUrl           = campagnesService.mediaBaseUrl;

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: aSouscrit ? AppColors.gold.withOpacity(0.5) : AppColors.border,
          ),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  c['image_url'] != null
                      ? Image.network(
                          c['image_url'].toString().startsWith('http') ? c['image_url'] : '$baseUrl${c['image_url']}',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _PlaceholderImage(height: 180),
                        )
                      : _PlaceholderImage(height: 180),
                  // Overlay gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                        ),
                      ),
                    ),
                  ),
                  // Badges
                  Positioned(
                    top: 12, left: 12,
                    child: _badge(
                      isCommercial ? '🏢 Commercial' : '🏡 Habitation',
                      isCommercial ? AppColors.purple : AppColors.gold.withOpacity(0.8),
                    ),
                  ),
                  if (aSouscrit)
                    Positioned(
                      top: 12, right: 12,
                      child: _badge('✅ Inscrit', AppColors.success),
                    ),
                  if (tirageEffec)
                    Positioned(
                      top: 12, right: 12,
                      child: _badge('🏆 Tiré', AppColors.gold),
                    ),
                ],
              ),
            ),

            // ── Contenu ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['titre'] ?? '',
                    style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  if (c['description'] != null && c['description'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(c['description'],
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Infos ligne 1
                  Row(children: [
                    _infoChip(Icons.people_outline, '${c['nb_participants'] ?? 0} participants'),
                    const SizedBox(width: 10),
                    _infoChip(Icons.calendar_today_outlined,
                      dateFin != null ? 'Fin le ${_fmtDate(dateFin)}' : '—'),
                  ]),
                  const SizedBox(height: 12),

                  // Prix + bouton
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Souscription',
                          style: TextStyle(color: AppColors.grey, fontSize: 11)),
                        Text(
                          '${_fmtMontant(c['frais_souscription'])} FCFA',
                          style: TextStyle(
                            color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ]),
                      const Spacer(),
                      if (tirageEffec)
                        _statusPill('Tirage effectué', AppColors.purple)
                      else if (isExpired)
                        _statusPill('Terminée', AppColors.grey)
                      else if (aSouscrit)
                        _statusPill('Déjà inscrit ✓', AppColors.success)
                      else
                        ElevatedButton(
                          onPressed: _subscribing ? null : _souscrire,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.bg,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _subscribing
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Souscrire', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.85),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _infoChip(IconData icon, String text) => Row(children: [
    Icon(icon, size: 13, color: AppColors.grey),
    const SizedBox(width: 4),
    Text(text, style: TextStyle(color: AppColors.greyLight, fontSize: 12)),
  ]);

  Widget _statusPill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

// ── Ecran détail avec top 15 + position du joueur ────────────
class CampagneDetailScreen extends StatefulWidget {
  final String campagneId;
  const CampagneDetailScreen({super.key, required this.campagneId});

  @override
  State<CampagneDetailScreen> createState() => _CampagneDetailScreenState();
}

class _CampagneDetailScreenState extends State<CampagneDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await campagnesService.getCampagneDetail(widget.campagneId);
      if (mounted) setState(() { _detail = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_detail?['titre'] ?? 'Détails'),
        backgroundColor: AppColors.bg,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _buildBody(),
                ),
    );
  }

  Widget _buildBody() {
    final d = _detail!;
    final participants = List<Map<String, dynamic>>.from(d['participants'] ?? []);
    final baseUrl = campagnesService.mediaBaseUrl;
    final total = d['nb_participants'] ?? 0;
    final monRang = d['mon_rang'] as Map<String, dynamic>?;
    final monRangNum = monRang?['rang'] as int?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (d['image_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                d['image_url'].toString().startsWith('http') ? d['image_url'] : '$baseUrl${d['image_url']}',
                height: 200, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderImage(height: 200),
              ),
            )
          else
            _PlaceholderImage(height: 200),
          const SizedBox(height: 16),

          // Titre & description
          Text(d['titre'] ?? '',
            style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          if ((d['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(d['description'], style: TextStyle(color: AppColors.grey, fontSize: 14)),
          ],
          const SizedBox(height: 16),

          // Infos détaillées
          _InfoGrid(campagne: d),
          const SizedBox(height: 20),

          // Gagnant
          if (d['tirage_effectue'] == true && d['gagnant_nom'] != null)
            _GagnantBanner(nom: d['gagnant_nom'], prenom: d['gagnant_prenom']),

          // ── Section participants ───────────────────────────
          const SizedBox(height: 20),
          Text('Participants ($total)',
            style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          if (participants.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Aucun participant pour l\'instant',
                  style: TextStyle(color: AppColors.grey)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Les 15 premiers
                  ...participants.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.surface2,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          title: Text(
                            '${p['prenom']} ${p['nom']}',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                          ),
                        ),
                        if (i < participants.length - 1)
                          Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }),

                  // ── Points de suspension si plus de 15 participants ──
                  if (total > participants.length) ...[
                    Divider(color: AppColors.border, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Text('·', style: TextStyle(color: AppColors.grey, fontSize: 20, height: 0.6)),
                          Text('·', style: TextStyle(color: AppColors.grey, fontSize: 20, height: 0.6)),
                          Text('·', style: TextStyle(color: AppColors.grey, fontSize: 20, height: 0.6)),
                          const SizedBox(height: 6),
                          Text(
                            '${total - participants.length} autre${(total - participants.length) > 1 ? 's' : ''} participant${(total - participants.length) > 1 ? 's' : ''}',
                            style: TextStyle(color: AppColors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Position du joueur connecté (s'il est hors top 15) ──
                  if (monRang != null && monRangNum != null && monRangNum > participants.length) ...[
                    Divider(color: AppColors.border, height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surface2,
                        child: Text(
                          '🎯$monRangNum',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        '${monRang['prenom']} ${monRang['nom']}',
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      trailing: Text(
                        'Vous',
                        style: TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}


// ── Widgets partagés ─────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final Map<String, dynamic> campagne;
  const _InfoGrid({required this.campagne});

  @override
  Widget build(BuildContext context) {
    final frais = campagne['frais_souscription'] as int? ?? 0;
    final type  = campagne['type_terrain'] == 'commercial' ? '🏢 Commercial' : '🏡 Habitation';
    final nb    = campagne['nb_participants'] ?? 0;
    final debut = _parseDate(campagne['date_debut']);
    final fin   = _parseDate(campagne['date_fin']);

    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.5,
      children: [
        _InfoTile(label: 'Type',         value: type),
        _InfoTile(label: 'Frais',        value: '${_fmtMontant(frais)} FCFA'),
        _InfoTile(label: 'Participants', value: '$nb inscrits'),
        _InfoTile(label: 'Fin',          value: fin != null ? _fmtDate(fin) : '—'),
        _InfoTile(label: 'Début',        value: debut != null ? _fmtDate(debut) : '—'),
        _InfoTile(label: 'Statut',
          value: campagne['tirage_effectue'] == true ? '🏆 Tiré' : (campagne['is_active'] == true ? '✅ En cours' : '❌ Fermé')),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: TextStyle(color: AppColors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _GagnantBanner extends StatelessWidget {
  final String nom, prenom;
  const _GagnantBanner({required this.nom, required this.prenom});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.gold.withOpacity(0.2), AppColors.purple.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Column(children: [
        const Text('🏆', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 6),
        Text('Gagnant(e) du tirage', style: TextStyle(color: AppColors.gold, fontSize: 12)),
        Text('$prenom $nom',
          style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final double height;
  const _PlaceholderImage({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.landscape_outlined, size: 40, color: AppColors.grey.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text('Aucune image disponible', style: TextStyle(color: AppColors.grey, fontSize: 12)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.grey),
      const SizedBox(height: 12),
      Text(error, style: TextStyle(color: AppColors.grey), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
    ]));
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.map_outlined, size: 48, color: AppColors.grey.withOpacity(0.5)),
      const SizedBox(height: 12),
      Text('Aucune campagne en cours', style: TextStyle(color: AppColors.grey, fontSize: 15)),
      const SizedBox(height: 4),
      Text('Revenez plus tard !', style: TextStyle(color: AppColors.grey.withOpacity(0.6), fontSize: 13)),
    ]));
  }
}

// ── Utilitaires ──────────────────────────────────────────────
DateTime? _parseDate(dynamic val) {
  if (val == null) return null;
  try { return DateTime.parse(val.toString()); } catch (_) { return null; }
}

String _fmtDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String _fmtMontant(dynamic v) {
  if (v == null) return '0';
  final n = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
  return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}


class _SouscriptionSheet extends StatefulWidget {
  final Map<String, dynamic> campagne;
  final VoidCallback onSouscrireWallet;
  final void Function(String methode, String phone, String? otp) onSouscrirePawaPay;

  const _SouscriptionSheet({
    required this.campagne,
    required this.onSouscrireWallet,
    required this.onSouscrirePawaPay,
  });

  @override
  State<_SouscriptionSheet> createState() => _SouscriptionSheetState();
}

class _SouscriptionSheetState extends State<_SouscriptionSheet> {
  bool _usePawaPay = false;
  String _methode = 'moov_money';
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  final _methodes = {
    'moov_money': 'Moov Money BF',
    'orange_money': 'Orange Money BF',
    'mtn_ci': 'MTN Mobile Money CI',
    'orange_ci': 'Orange Money CI',
  };

  String _fmtMontantLoc(dynamic val) {
    if (val == null) return '0';
    return val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final montant = _fmtMontantLoc(widget.campagne['frais_souscription']);
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Souscrire à la campagne',
            style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Montant : $montant FCFA',
            style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          if (!_usePawaPay) ...[
            ElevatedButton.icon(
              icon: Icon(Icons.account_balance_wallet, color: AppColors.bg),
              label: const Text('Payer avec mon Portefeuille'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 54),
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: widget.onSouscrireWallet,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.phone_android, color: AppColors.white),
              label: const Text('Payer par Mobile Money'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 54),
                backgroundColor: AppColors.bg,
                foregroundColor: AppColors.white,
                side: BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _usePawaPay = true),
            ),
          ] else ...[
            Text('Opérateur Mobile Money', style: TextStyle(color: AppColors.greyLight, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _methode,
                  isExpanded: true,
                  dropdownColor: AppColors.bg,
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                  icon: Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
                  items: _methodes.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (v) => setState(() => _methode = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Numéro de téléphone', style: TextStyle(color: AppColors.greyLight, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg,
                hintText: 'Ex: 01020304',
                hintStyle: TextStyle(color: AppColors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.gold)),
              ),
            ),
            if (_methode == 'orange_money') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Composez le *144*4*6*${widget.campagne['frais_souscription']}# sur votre téléphone pour générer votre code OTP de paiement, puis saisissez-le ci-dessous.',
                    style: TextStyle(fontSize: 12, color: AppColors.gold, height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bg,
                  labelText: 'Code de paiement (OTP)',
                  hintText: 'Code généré par Orange',
                  hintStyle: TextStyle(color: AppColors.grey),
                  labelStyle: TextStyle(color: AppColors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.gold)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _usePawaPay = false),
                    child: Text('Retour', style: TextStyle(color: AppColors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.bg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      String phone = _phoneCtrl.text.trim();
                      if (phone.isEmpty) return;

                      final otp = _otpCtrl.text.trim();
                      
                      // Validation de l'OTP pour Orange Money BF
                      if (_methode == 'orange_money' && otp.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Veuillez entrer le code de paiement (OTP)'),
                          backgroundColor: AppColors.error,
                        ));
                        return;
                      }

                      // Nettoyage du numéro
                      phone = phone.replaceAll('+', '').replaceAll(' ', '');

                      // Ajout de l'indicatif automatique
                      if (_methode.endsWith('_ci')) {
                        // Côte d'Ivoire (225)
                        if (!phone.startsWith('225')) {
                          phone = '225$phone';
                        }
                      } else {
                        // Burkina Faso (226)
                        if (!phone.startsWith('226')) {
                          phone = '226$phone';
                        }
                      }

                      widget.onSouscrirePawaPay(_methode, phone, otp.isEmpty ? null : otp);
                    },
                    child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
