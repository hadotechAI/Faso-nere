import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int currentStep;
  final int totalSteps;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress steps
        Row(
          children: List.generate(totalSteps, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < currentStep
                      ? AppColors.purple
                      : AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Text(title,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.white)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                fontSize: 14, color: AppColors.grey)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class AppOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppOutlineButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  final List<Widget> children;
  final Color backgroundColor;
  final Color borderColor;

  const InfoBox({
    super.key,
    required this.children,
    this.backgroundColor = AppColors.card,
    this.borderColor = AppColors.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.3)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
