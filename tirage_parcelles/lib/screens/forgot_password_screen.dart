import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../core/country_picker.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _telCtrl = TextEditingController();
  bool _loading = false;
  CountryOption _selectedCountry = kAvailableCountries[0]; // Burkina Faso par défaut

  Future<void> _pickCountry() async {
    final result = await showCountryPicker(context, _selectedCountry);
    if (result != null && mounted) {
      setState(() => _selectedCountry = result);
    }
  }

  void _submit() async {
    final tel = _telCtrl.text.trim();
    if (tel.length < 8) return;

    setState(() => _loading = true);
    try {
      final phone = '${_selectedCountry.dialCode}${tel.replaceAll(' ', '')}';
      await authService.forgotPassword(phone);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(telephone: phone)),
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
    _telCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mot de passe oublié',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Réinitialisation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white)),
            const SizedBox(height: 8),
            Text(
              'Entrez votre numéro de téléphone. Si votre compte existe, un code de vérification vous sera envoyé par SMS.',
              style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Numéro de téléphone',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.greyLight)),
            ),
            TextFormField(
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
              style: TextStyle(color: AppColors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: '•• •• •• ••',
                hintStyle: TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: AppColors.surface,
                prefix: PhoneCountryPrefix(
                  country: _selectedCountry,
                  onTap: _pickCountry,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
              ),
            ),
            const SizedBox(height: 32),

            _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : GoldBtn(label: 'Envoyer le code SMS', onTap: _submit),
          ],
        ),
      ),
    );
  }
}
