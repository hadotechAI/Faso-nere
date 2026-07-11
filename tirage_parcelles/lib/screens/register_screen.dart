import 'package:faso_nere/services/api_client.dart';
import 'package:faso_nere/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../core/country_picker.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telCtrl       = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _parainCtrl    = TextEditingController();
  final _nomCtrl       = TextEditingController();
  final _prenomCtrl    = TextEditingController();
  bool _loading    = false;
  bool _showPass   = false;
  bool _accepted   = false;
  CountryOption _selectedCountry = kAvailableCountries[0]; // Burkina Faso par défaut

  Future<void> _pickCountry() async {
    final result = await showCountryPicker(context, _selectedCountry);
    if (result != null && mounted) {
      setState(() => _selectedCountry = result);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Acceptez les conditions"), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final phone = '${_selectedCountry.dialCode}${_telCtrl.text.trim().replaceAll(' ', '')}';
      final player = await authService.register(
        nom:         _nomCtrl.text.trim(),
        prenom:      _prenomCtrl.text.trim(),
        telephone:   phone,
        motDePasse:  _passCtrl.text,
        codeParrain: _parainCtrl.text.trim().isEmpty ? null : _parainCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(player: player)),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inscription impossible : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _telCtrl.dispose(); _passCtrl.dispose(); _parainCtrl.dispose();
    _nomCtrl.dispose(); _prenomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Créer un compte',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: ClipOval(
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text('FASO NERE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                      color: AppColors.gold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 6),
            Text('Entrez vos informations pour commencer',
                style: TextStyle(fontSize: 14, color: AppColors.grey)),
            const SizedBox(height: 22),

            _FieldLabel('nom'),
            _DarkField(controller: _nomCtrl, hint: 'Entrez votre nom'),
            _FieldLabel('prenom'),
            _DarkField(controller: _prenomCtrl, hint: 'Entrez votre prénom'),
            const SizedBox(height: 16),

            // Téléphone avec sélecteur de pays
            _FieldLabel('Numéro de téléphone'),
            _PhoneField(
              controller: _telCtrl,
              selectedCountry: _selectedCountry,
              onCountryTap: _pickCountry,
            ),
            const SizedBox(height: 16),

            // Mot de passe
            _FieldLabel('Mot de passe'),
            _DarkField(
              controller: _passCtrl,
              hint: '•• •• •• ••',
              obscure: !_showPass,
              suffix: IconButton(
                icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.grey, size: 20),
                onPressed: () => setState(() => _showPass = !_showPass),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
            ),
            const SizedBox(height: 16),

            // Code parrainage
            _FieldLabel('Code de parrainage (optionnel)'),
            _DarkField(
              controller: _parainCtrl,
              hint: 'Entrez le code',
            ),
            const SizedBox(height: 20),

            // CGU
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => setState(() => _accepted = !_accepted),
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: _accepted ? AppColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: _accepted ? AppColors.gold : AppColors.border, width: 2),
                  ),
                  child: _accepted
                      ? Icon(Icons.check, size: 14, color: AppColors.bg)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: "J'accepte les ",
                    style: TextStyle(fontSize: 13, color: AppColors.grey),
                    recognizer: TapGestureRecognizer()..onTap = () => setState(() => _accepted = !_accepted),
                    children: [
                      TextSpan(
                        text: "Conditions d'utilisation",
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () async {
                          final url = Uri.parse('https://faso-nere-backend-kxzb.onrender.com/static/politique.html');
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                      ),
                      TextSpan(
                        text: ' et la ',
                        style: TextStyle(color: AppColors.grey),
                        recognizer: TapGestureRecognizer()..onTap = () => setState(() => _accepted = !_accepted),
                      ),
                      TextSpan(
                        text: 'Politique de confidentialité',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () async {
                          final url = Uri.parse('https://faso-nere-backend-kxzb.onrender.com/static/politique.html');
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 28),

            _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : GoldBtn(label: "S'inscrire", onTap: _submit),

            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text.rich(
                  TextSpan(
                    text: 'Déjà un compte ? ',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                    children: [
                      TextSpan(text: 'Se connecter',
                          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 13,
        fontWeight: FontWeight.w600, color: AppColors.greyLight)),
  );
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final CountryOption selectedCountry;
  final VoidCallback onCountryTap;
  const _PhoneField({
    required this.controller,
    required this.selectedCountry,
    required this.onCountryTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
      style: TextStyle(color: AppColors.white, fontSize: 15),
      validator: (v) => (v == null || v.trim().length < 8) ? 'Numéro invalide' : null,
      decoration: InputDecoration(
        hintText: '•• •• •• ••',
        hintStyle: TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: AppColors.surface,
        prefix: PhoneCountryPrefix(
          country: selectedCountry,
          onTap: onCountryTap,
        ),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(focused: true),
        errorBorder: _border(error: true),
        errorStyle: TextStyle(color: AppColors.error),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: error ? AppColors.error : (focused ? AppColors.gold : AppColors.border),
          width: focused ? 1.5 : 1,
        ),
      );
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(focused: true),
        errorBorder: _border(error: true),
        errorStyle: TextStyle(color: AppColors.error),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: error ? AppColors.error : (focused ? AppColors.gold : AppColors.border),
          width: focused ? 1.5 : 1,
        ),
      );
}