import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../core/ui_components.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  int _page = 0;
  bool _checkingSession = true;

  final _pages = const [
    _HeroSlide(
      emoji: '🎁',
      title: 'Choisis ton cadeau',
      subtitle: 'et gagne une parcelle !',
      body: 'Tente ta chance et gagne des parcelles\net des cadeaux exclusifs.',
    ),
    _HeroSlide(
      emoji: '🏆',
      title: 'Des parcelles réelles',
      subtitle: 'à gagner chaque jour',
      body: 'Parcelles de 100 m² à 1600 m²\npour les grands gagnants.',
    ),
    _HeroSlide(
      emoji: '💰',
      title: 'Paiement sécurisé',
      subtitle: 'Mobile Money accepté',
      body: 'Orange Money, Moov Money\net cartes bancaires.',
    ),
    _HeroSlide(
      emoji: '⚡',
      title: 'Résultats instantanés',
      subtitle: 'Découvrez immédiatement',
      body: 'Sélectionnez un cadeau et découvrez\nsi vous avez gagné en temps réel.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _checkSession();
  }

  void _checkSession() async {
    final success = await appState.tryRestoreSession();
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(player: appState.user!)),
      );
    } else {
      if (mounted) {
        setState(() => _checkingSession = false);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.gold,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final isDark = appState.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0E0B1E) : const Color(0xFFF9F9FB);
    final cardBgColor = isDark ? const Color(0xFF1A1535) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1535);
    final textMutedColor = isDark ? const Color(0xFF8A85A8) : const Color(0xFF6B658A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Hero card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF141033), Color(0xFF281F57)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF141033).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + Titre
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, trace) =>
                                      Icon(Icons.home_work, color: AppColors.gold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: 'FASO ',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1),
                                    children: [
                                      TextSpan(
                                          text: 'NERE',
                                          style: TextStyle(color: AppColors.gold)),
                                    ],
                                  ),
                                ),
                                const Text('Promotion Immobiliere',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),
                        
                        // Textes du slide
                        Text(_pages[_page].title,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2)),
                        Text(_pages[_page].subtitle,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                                height: 1.2)),
                        const SizedBox(height: 16),
                        Text(_pages[_page].body,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.5)),
                        
                        const SizedBox(height: 30),
                        
                        // Bouton Commencer
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Commencer',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Indicateurs de page ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => GestureDetector(
                      onTap: () => setState(() => _page = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: i == _page ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == _page ? AppColors.gold : const Color(0xFFD0D0D5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    )),
                  ),

                  const SizedBox(height: 24),

                  // ── Cartes horizontales ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FeatureCard(
                            icon: Icons.shield_outlined,
                            title: '100% Sécurisé',
                            desc: 'Vos transactions sont protégées',
                            bgColor: cardBgColor,
                            textColor: textColor,
                            descColor: textMutedColor,
                          ),
                          const SizedBox(width: 12),
                          _FeatureCard(
                            icon: Icons.credit_card_outlined,
                            title: 'Paiement facile',
                            desc: 'Mobile Money et cartes bancaires',
                            bgColor: cardBgColor,
                            textColor: textColor,
                            descColor: textMutedColor,
                          ),
                          const SizedBox(width: 12),
                          _FeatureCard(
                            icon: Icons.flash_on_rounded,
                            title: 'Résultats instantanés',
                            desc: 'Confirmation immédiate de vos paiements',
                            bgColor: cardBgColor,
                            textColor: textColor,
                            descColor: textMutedColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section Pourquoi nous choisir ? ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1940) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text('Pourquoi nous choisir ?',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _WhyBadge(icon: Icons.verified_user_outlined, label: 'Paiement sécurisé', textColor: textColor, descColor: textMutedColor)),
                            Expanded(child: _WhyBadge(icon: Icons.speed_outlined, label: 'Validation rapide', textColor: textColor, descColor: textMutedColor)),
                            Expanded(child: _WhyBadge(icon: Icons.support_agent_outlined, label: 'Support client disponible', textColor: textColor, descColor: textMutedColor)),
                            Expanded(child: _WhyBadge(icon: Icons.access_time_outlined, label: 'Disponible 24h/24', textColor: textColor, descColor: textMutedColor)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── Boutons CTA ──
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.person_add_alt_1),
                        SizedBox(width: 12),
                        Text('Créer un compte',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen())),
                    child: Text.rich(
                      TextSpan(
                        text: 'Déjà un compte ? ',
                        style: TextStyle(color: textMutedColor, fontSize: 14),
                        children: [
                          TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSlide {
  final String emoji, title, subtitle, body;
  const _HeroSlide(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.body});
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color bgColor;
  final Color textColor;
  final Color descColor;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.bgColor,
    required this.textColor,
    required this.descColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.gold, size: 28),
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          const SizedBox(height: 6),
          Text(desc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: descColor, height: 1.3)),
        ],
      ),
    );
  }
}

class _WhyBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color descColor;

  const _WhyBadge({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.descColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withOpacity(0.5)),
          ),
          child: Icon(icon, color: textColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: descColor, height: 1.3)),
      ],
    );
  }
}