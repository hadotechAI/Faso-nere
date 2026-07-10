// lib/core/country_picker.dart
// Modèle et données des pays supportés par l'application
import 'package:flutter/material.dart';
import 'app_colors.dart';

class CountryOption {
  final String flag;
  final String name;
  final String dialCode;
  const CountryOption({required this.flag, required this.name, required this.dialCode});
}

/// Pays supportés pour l'inscription / connexion
const kAvailableCountries = [
  CountryOption(flag: '🇧🇫', name: 'Burkina Faso', dialCode: '+226'),
  CountryOption(flag: '🇨🇮', name: "Côte d'Ivoire", dialCode: '+225'),
];

/// Affiche un BottomSheet de sélection de pays
/// Retourne le pays sélectionné ou null si annulé
Future<CountryOption?> showCountryPicker(
  BuildContext context,
  CountryOption current,
) {
  return showModalBottomSheet<CountryOption>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choisir le pays',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...kAvailableCountries.map((c) => ListTile(
            leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
            title: Text(c.name, style: TextStyle(color: AppColors.white, fontSize: 15)),
            trailing: Text(
              c.dialCode,
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
            ),
            selected: c.dialCode == current.dialCode,
            selectedTileColor: AppColors.gold.withValues(alpha: 0.08),
            onTap: () => Navigator.pop(ctx, c),
          )),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Widget préfixe téléphone cliquable avec drapeau + indicatif
/// À utiliser avec le paramètre `prefix` (pas `prefixIcon`) de InputDecoration
class PhoneCountryPrefix extends StatelessWidget {
  final CountryOption country;
  final VoidCallback onTap;
  const PhoneCountryPrefix({super.key, required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(country.flag, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(country.dialCode, style: TextStyle(color: AppColors.grey, fontSize: 14)),
        const SizedBox(width: 2),
        Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey, size: 18),
        const SizedBox(width: 8),
        Container(width: 1, height: 20, color: AppColors.border),
        const SizedBox(width: 8),
      ]),
    );
  }
}
