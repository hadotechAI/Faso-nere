import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../core/ui_components.dart';
import '../services/api_client.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _paysCtrl = TextEditingController();
  // We simulate date of birth as it might not be in the backend model yet, but we will collect it
  final _dobCtrl = TextEditingController();
  bool _loading = false;

  final List<String> _villes = [
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Koudougou',
    'Banfora',
    'Ouahigouya',
    'Kaya',
    'Tenkodogo',
    'Fada N\'Gourma',
    'Dédougou',
    'Dori',
    'Manga',
    'Ziniaré'
  ];
  String? _selectedVille;

  @override
  void initState() {
    super.initState();
    final p = appState.user;
    if (p != null) {
      _nomCtrl.text = p.nom;
      _prenomCtrl.text = p.prenom;
      _emailCtrl.text = p.email ?? '';
      _quartierCtrl.text = p.quartier ?? '';
      _paysCtrl.text = p.pays ?? 'Burkina Faso';
      if (p.ville != null && p.ville!.isNotEmpty) {
        if (_villes.contains(p.ville)) {
          _selectedVille = p.ville;
        } else {
          _villes.add(p.ville!);
          _selectedVille = p.ville;
        }
      } else {
        _selectedVille = 'Ouagadougou';
      }
      _villeCtrl.text = _selectedVille ?? '';
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _villeCtrl.dispose();
    _emailCtrl.dispose();
    _quartierCtrl.dispose();
    _paysCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await api.put('/users/me', {
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'quartier': _quartierCtrl.text.trim(),
        'pays': _paysCtrl.text.trim(),
        // Note: dob can be sent if backend supports it later
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.success),
        );
        appState.tryRestoreSession();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Compléter mon profil',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Nom'),
            _buildField(_nomCtrl, 'Votre nom'),
            const SizedBox(height: 16),
            const _Label('Prénom'),
            _buildField(_prenomCtrl, 'Votre prénom'),
            const SizedBox(height: 16),
            const _Label('Email'),
            _buildField(_emailCtrl, 'votre@email.com'),
            const SizedBox(height: 16),
            const _Label('Pays'),
            _buildField(_paysCtrl, 'Votre pays'),
            const SizedBox(height: 16),
            const _Label('Ville de résidence'),
            _buildDropdown(),
            const SizedBox(height: 16),
            const _Label('Quartier'),
            _buildField(_quartierCtrl, 'Votre quartier'),
            const SizedBox(height: 16),
            const _Label('Date de naissance (Optionnel)'),
            _buildField(_dobCtrl, 'JJ/MM/AAAA'),
            const SizedBox(height: 32),
            _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : GoldBtn(label: 'Enregistrer', onTap: _save),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: AppColors.surface,
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
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVille,
      dropdownColor: AppColors.surface2,
      style: TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
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
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey),
      items: _villes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedVille = val;
            _villeCtrl.text = val;
          });
        }
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.greyLight)),
  );
}
