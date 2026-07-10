import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../core/country_picker.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'suspended_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _telCtrl  = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading   = false;
  bool _showPass  = false;
  CountryOption _selectedCountry = kAvailableCountries[0]; // Burkina Faso par défaut

  void _submit() async {
    final tel  = _telCtrl.text.trim();
    final pass = _passCtrl.text;
    if (tel.length < 8 || pass.isEmpty) return;

    setState(() => _loading = true);
    try {
      await api.reconnect();
      final phone = '${_selectedCountry.dialCode}${tel.replaceAll(' ', '')}';
      final player = await authService.login(
        telephone:  phone,
        motDePasse: pass,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(player: player)),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403 && e.message.toLowerCase().contains('suspendu')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuspendedScreen()),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connexion impossible : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCountry() async {
    final result = await showCountryPicker(context, _selectedCountry);
    if (result != null && mounted) {
      setState(() => _selectedCountry = result);
    }
  }

  @override
  void dispose() { _telCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Se connecter',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 14),
          Center(child: Text('FASO NERE',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
              color: AppColors.gold, letterSpacing: 1.5))),
          const SizedBox(height: 4),
          Text('Bienvenue de retour !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
          const SizedBox(height: 6),
          Text('Connectez-vous pour continuer',
              style: TextStyle(fontSize: 13, color: AppColors.grey)),
          const SizedBox(height: 28),

          const _Label('Numéro de téléphone'),
          TextFormField(
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
            style: TextStyle(color: AppColors.white, fontSize: 15),
            decoration: _deco('•• •• •• ••',
                prefix: PhoneCountryPrefix(
                  country: _selectedCountry,
                  onTap: _pickCountry,
                )),
          ),
          const SizedBox(height: 16),

          const _Label('Mot de passe'),
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: Text('Mot de passe oublié ?',
                  style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 28),

          _loading
              ? Center(child: CircularProgressIndicator(color: AppColors.gold))
              : GoldBtn(label: 'Se connecter', onTap: _submit),

          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: Text.rich(TextSpan(
                text: "Pas encore de compte ? ",
                style: TextStyle(color: AppColors.grey, fontSize: 13),
                children: [TextSpan(text: "S'inscrire",
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700))],
              )),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  InputDecoration _deco(String hint, {Widget? prefix, Widget? suffix}) =>
      InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: AppColors.grey),
        filled: true, fillColor: AppColors.surface,
        prefix: prefix, suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 13,
        fontWeight: FontWeight.w600, color: AppColors.greyLight)),
  );
}
