// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../core/ui_components.dart';
import '../models/player_model.dart';
import '../services/notification_service.dart';
import 'dimension_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'pack_screen.dart';
import 'leaderboard_screen.dart';
import 'wallet_screen.dart';
import 'profile_edit_screen.dart';
import '../widgets/promo_code_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'campagnes_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  final PlayerModel player;
  const HomeScreen({super.key, required this.player});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Démarrer le polling des notifications en arrière-plan
    notificationService.startPolling();
    // Envoyer le token Firebase au backend
    notificationService.syncFcmToken();
  }

  @override
  void dispose() {
    notificationService.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _buildTab()),
      bottomNavigationBar: _BottomNav(
          current: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0: return _HomeTab(
          player: appState.user ?? widget.player,
          onTabChange: (i) => setState(() => _tab = i));
      case 1: return _TiragesTab(player: appState.user ?? widget.player);
      case 2: return LeaderboardScreen(
          currentUserName: (appState.user ?? widget.player).nom);
      case 3: return HistoryScreen(player: appState.user ?? widget.player);
      case 4: return _ProfileTab(player: appState.user ?? widget.player);
      default: return _HomeTab(
          player: appState.user ?? widget.player,
          onTabChange: (i) => setState(() => _tab = i));
    }
  }
}

// ── Onglet Accueil ────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final PlayerModel player;
  final void Function(int) onTabChange;

  const _HomeTab({required this.player, required this.onTabChange});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _unreadCount = notificationService.unreadCount;

  @override
  void initState() {
    super.initState();
    notificationService.unreadCountNotifier.addListener(_updateBadge);
    notificationService.fetchNotifications();
  }

  @override
  void dispose() {
    notificationService.unreadCountNotifier.removeListener(_updateBadge);
    super.dispose();
  }

  void _updateBadge() {
    setState(() => _unreadCount = notificationService.unreadCount);
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = appState.user ?? widget.player;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bonjour 👋',
                  style: TextStyle(fontSize: 12, color: AppColors.grey)),
              Text(currentPlayer.nom,
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700, color: AppColors.white)),
            ]),
          ]),
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const NotificationsScreen())),
              child: Stack(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.notifications_none_rounded,
                    color: AppColors.white, size: 22),
                ),
                if (_unreadCount > 0)
                  Positioned(top: 4, right: 4,
                    child: Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle))),
              ]),
            ),
          ]),
        ]),

        const SizedBox(height: 24),

        // ── Carte solde ──
        DarkCard(
          color: AppColors.surface2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text('Portefeuille & Tentatives',
                  style: TextStyle(fontSize: 12, color: AppColors.grey)),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.grey, size: 14),
              ),
            ]),

            const SizedBox(height: 16),
            
            // Dual Balance Display
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TENTATIVES',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.greyLight, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('${currentPlayer.tentatives}',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800, color: AppColors.white)),
                ]),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('GAINS RETRAITABLES',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gold, letterSpacing: 0.5)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => appState.toggleHideBalance(),
                      child: Icon(appState.hideBalance ? Icons.visibility_off : Icons.visibility, color: AppColors.gold, size: 14),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(appState.hideBalance ? '••••••' : appState.formatMoney(currentPlayer.creditConverti),
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800, color: AppColors.gold)),
                ]),
              ),
            ]),

            const SizedBox(height: 18),
            const AppDivider(),
            const SizedBox(height: 16),

            // ── Bouton Acheter un pack (remplace Dépôt) ──
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PackScreen(
                    player: appState.user ?? widget.player),
              )),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFE68900)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withAlpha(77),
                        blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.add_circle_outline_rounded,
                    size: 18, color: AppColors.bg),
                  SizedBox(width: 6),
                  Text('Acheter un pack',
                    style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.bg)),
                ]),
              ),
            ),

            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RetraitScreen(player: currentPlayer))),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.arrow_circle_down_rounded,
                    size: 18, color: AppColors.grey),
                  SizedBox(width: 6),
                  Text('Retrait',
                    style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            const AppDivider(),
            const SizedBox(height: 16),

            // Stats
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
              // Jauge de connexion
              Expanded(child: Column(children: [
                Icon(Icons.local_fire_department_rounded,
                    color: currentPlayer.loginStreak >= 7 ? AppColors.gold : AppColors.grey, size: 24),
                const SizedBox(height: 4),
                Text('${currentPlayer.loginStreak}/7 jours',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white)),
                Text('Connexions', style: TextStyle(fontSize: 10, color: AppColors.greyLight)),
              ])),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(child: StatChip(icon: Icons.emoji_events_outlined,
                  value: '${currentPlayer.gagnes}',
                  label: 'Gagnés')),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(child: StatChip(icon: Icons.group_outlined,
                  value: '${currentPlayer.parrainages}',
                  label: 'Parrainages')),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // ── CTA Jouer ──
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DimensionScreen(
                  player: appState.user ?? widget.player))),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B3FBE), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.purple.withAlpha(102),
                    blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(children: [
              Text('🎁', style: TextStyle(fontSize: 42)),
              SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Choisir un cadeau',
                style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white)),
              SizedBox(height: 4),
              Text('Tentez votre chance maintenant !',
                style: TextStyle(fontSize: 12,
                  color: AppColors.greyLight)),
              ])),
              Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.white, size: 16),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ── CTA Souscription Terrain ──
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const CampagnesScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A6B3C), Color(0xFF2ECC71)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2ECC71),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(children: [
              const Text('🏘️', style: TextStyle(fontSize: 42)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Souscription Terrain',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    )),
                  const SizedBox(height: 4),
                  Text('Participez au tirage — 10 000 / 20 000 FCFA',
                    style: TextStyle(fontSize: 12, color: AppColors.white)),
                ],
              )),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.white, size: 16),
            ]),
          ),
        ),

        const SizedBox(height: 24),

        // ── Comment ça marche ──
        Text('Comment ça marche ?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.white)),
        const SizedBox(height: 14),
        _Step(num: '1', label: 'Achetez un pack de tentatives'),
        const SizedBox(height: 10),
        _Step(num: '2', label: 'Choisissez la dimension de parcelle'),
        const SizedBox(height: 10),
        _Step(num: '3',
            label: 'Sélectionnez un cadeau et découvrez si vous avez gagné !'),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final String num, label;
  const _Step({required this.num, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text(num, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: AppColors.bg))),
    ),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: TextStyle(
        fontSize: 14, color: AppColors.greyLight))),
  ]);
}

// ── Onglet Tirages ────────────────────────────────────────────
class _TiragesTab extends StatelessWidget {
  final PlayerModel player;
  const _TiragesTab({required this.player});

  @override
  Widget build(BuildContext context) {
    final currentPlayer = appState.user ?? player;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tirages', style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.w800, color: AppColors.white)),
        const SizedBox(height: 8),

        // Solde + tentatives restantes
        DarkCard(
          color: AppColors.surface2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.payments_outlined, color: AppColors.gold, size: 20),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => appState.toggleHideBalance(),
                  child: Icon(appState.hideBalance ? Icons.visibility_off : Icons.visibility, color: AppColors.grey, size: 16),
                ),
              ]),
              const SizedBox(height: 4),
              Text(appState.hideBalance ? '••••••' : appState.formatMoney(currentPlayer.creditConverti),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white)),
              Text('Gains', style: TextStyle(fontSize: 10, color: AppColors.greyLight)),
            ]),
            Container(width: 1, height: 40, color: AppColors.border),
            StatChip(icon: Icons.casino_outlined,
                value: '${currentPlayer.tentatives}',
                label: 'Tentatives'),
          ]),
        ),

        const SizedBox(height: 20),
        GoldBtn(
          label: 'Nouveau tirage',
          icon: Icons.casino_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DimensionScreen(player: currentPlayer))),
        ),
        const SizedBox(height: 20),
        PromoCodeWidget(player: currentPlayer),
        const SizedBox(height: 20),

        Text('Besoin de tentatives ?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.white)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PackScreen(player: currentPlayer))),
            child: DarkCard(
            color: AppColors.surface2,
            child: Row(children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.gold, size: 24),
              SizedBox(width: 12),
              Expanded(child: Text('Acheter un pack de tentatives',
                  style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white))),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.grey, size: 14),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Onglet Profil ─────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  final PlayerModel player;
  const _ProfileTab({required this.player});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final p = appState.user ?? widget.player;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.purple,
          child: Text(
            p.nom.isNotEmpty ? p.nom[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 32,
                fontWeight: FontWeight.w800, color: AppColors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(p.nomComplet, style: TextStyle(fontSize: 20,
            fontWeight: FontWeight.w700, color: AppColors.white)),
        Text(p.telephone,
            style: TextStyle(fontSize: 14, color: AppColors.grey)),
        const SizedBox(height: 28),

        _ProfileItem(
          icon: Icons.payments_outlined,
          label: 'Gains retraitables',
          value: appState.hideBalance ? '••••••' : appState.formatMoney(p.creditConverti),
          trailing: IconButton(
            onPressed: () => appState.toggleHideBalance(),
            icon: Icon(
              appState.hideBalance ? Icons.visibility_off : Icons.visibility,
              color: AppColors.grey,
            ),
          ),
        ),
        _ProfileItem(icon: Icons.casino_outlined,
            label: 'Tentatives', value: '${p.tentatives}'),
        _ProfileItem(icon: Icons.emoji_events_outlined,
            label: 'Gains', value: '${p.gagnes}'),
        _ProfileItem(icon: Icons.group_outlined,
            label: 'Parrainages', value: '${p.parrainages}'),
        _ProfileItem(icon: Icons.qr_code_rounded,
            label: 'Code parrain', value: p.codeParrain),
        const SizedBox(height: 24),
        
        Align(alignment: Alignment.centerLeft, child: Text('Paramètres', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 12),
        _ActionItem(icon: Icons.person_add_alt_1_rounded, label: 'Compléter mon profil', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
        }),
        _ActionItem(icon: Icons.support_agent_rounded, label: 'Support client', onTap: () {
          _showInfo(context, 'Support Client', 'Pour toute assistance, veuillez nous contacter par téléphone ou WhatsApp au +226 46 82 34 34 ou par email à contact@fasonere.com');
        }),
        _ActionItem(icon: Icons.info_outline_rounded, label: 'À propos de l\'application', onTap: () async {
          final packageInfo = await PackageInfo.fromPlatform();
          final version = '${packageInfo.version}+${packageInfo.buildNumber}';
          if (!context.mounted) return;
          _showInfo(context, 'À propos', 'Faso Nere est une application innovante permettant de gagner des parcelles et divers lots.\n\nVersion installée : $version');
        }),
        _ActionItem(icon: Icons.privacy_tip_outlined, label: 'Politique de confidentialité & CGU', onTap: () async {
          final url = Uri.parse('https://faso-nere-backend-kxzb.onrender.com/static/politique.html');
          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
        }),
        _ThemeToggleItem(),
        const SizedBox(height: 24),
        OutlineBtn(
          label: 'Se déconnecter',
          icon: Icons.logout_rounded,
          onTap: () async {
            await appState.logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (_) => false);
            }
          },
        ),
      ]),
    );
  }

  void _showInfo(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: TextStyle(color: AppColors.white)),
        content: Text(content, style: TextStyle(color: AppColors.grey, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Fermer', style: TextStyle(color: AppColors.gold))),
        ],
      ),
    );
  }
}

class _ThemeToggleItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => appState.toggleTheme(),
        child: DarkCard(
          child: Row(children: [
            Icon(
              appState.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.gold, size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(
              appState.isDarkMode ? 'Mode clair' : 'Mode sombre',
              style: TextStyle(fontSize: 14, color: AppColors.white, fontWeight: FontWeight.w600),
            )),
            Switch(
              value: !appState.isDarkMode,
              onChanged: (_) => appState.toggleTheme(),
              activeColor: AppColors.gold,
              inactiveThumbColor: AppColors.grey,
              inactiveTrackColor: AppColors.surface2,
            ),
          ]),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GestureDetector(
      onTap: onTap,
      child: DarkCard(
        child: Row(children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: AppColors.white, fontWeight: FontWeight.w600))),
          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.grey, size: 14),
        ]),
      ),
    ),
  );
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Widget?  trailing;
  const _ProfileItem({required this.icon, required this.label,
      required this.value, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DarkCard(
      child: Row(children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(
            fontSize: 14, color: AppColors.greyLight))),
        if (trailing != null) trailing!,
        Text(value, style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w700, color: AppColors.white)),
      ]),
    ),
  );
}

// ── Bottom Nav ────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded,           'Accueil'),
      (Icons.casino_outlined,        'Tirages'),
      (Icons.emoji_events_outlined,  'Top'),
      (Icons.history_rounded,        'Historique'),
      (Icons.person_outline_rounded, 'Profil'),
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = i == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(items[i].$1, size: 24,
                    color: isActive ? AppColors.gold : AppColors.grey),
                const SizedBox(height: 4),
                Text(items[i].$2, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.gold : AppColors.grey)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

String _fmt(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');