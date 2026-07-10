import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String telephone;
  const ResetPasswordScreen({super.key, required this.telephone});
  @override State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;

  void _submit() async {
    final code = _codeCtrl.text.trim();
    final pass = _passCtrl.text;
    if (code.length != 6 || pass.length < 6) return;

    setState(() => _loading = true);
    try {
      await authService.resetPassword(widget.telephone, code, pass);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé avec succès !'), backgroundColor: Colors.green),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nouveau mot de passe',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Vérification',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white)),
            const SizedBox(height: 8),
            Text('Un code SMS a été envoyé au ${widget.telephone}. Veuillez le saisir ci-dessous ainsi que votre nouveau mot de passe.',
                style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.5)),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Code SMS (6 chiffres)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.greyLight)),
            ),
            TextFormField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: TextStyle(color: AppColors.white, fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: _deco('••••••'),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Nouveau mot de passe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.greyLight)),
            ),
            TextField(
              controller: _passCtrl,
              obscureText: !_showPass,
              style: TextStyle(color: AppColors.white, fontSize: 15),
              decoration: _deco('••••••••',
                  suffix: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.grey, size: 20),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  )),
            ),
            const SizedBox(height: 32),

            _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : GoldBtn(label: 'Réinitialiser mon mot de passe', onTap: _submit),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String hint, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: AppColors.grey, letterSpacing: 1),
        filled: true, fillColor: AppColors.surface,
        counterText: '',
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
      );
}
