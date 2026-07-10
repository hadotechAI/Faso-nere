import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import 'login_screen.dart';

class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: false,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cancel_rounded,
                color: AppColors.error,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Compte Suspendu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Votre compte a été suspendu par l\'administration. Veuillez contacter le support administratif pour plus d\'informations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            GoldBtn(
              label: 'Retour à l\'accueil',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
