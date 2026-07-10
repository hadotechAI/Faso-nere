import 'package:flutter/material.dart';
import 'app_colors.dart';

// ── Scaffold de base ──────────────────────────────────────────
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final bool showBack;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.showBack = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: title != null
          ? AppBar(
              backgroundColor: AppColors.bg,
              elevation: 0,
              centerTitle: true,
              leading: showBack
                  ? IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.white, size: 18),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              title: Text(title!,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              actions: actions,
            )
          : null,
      body: SafeArea(child: body),
    );
  }
}

// ── Bouton principal (dégradé or) ─────────────────────────────
class GoldBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;

  const GoldBtn({super.key, required this.label, this.onTap, this.icon, this.height = 54});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFE68900)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: onTap == null ? AppColors.border : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null
              ? [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 12, offset: Offset(0, 4))]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: AppColors.bg), SizedBox(width: 8)],
              Text(label,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: onTap == null ? AppColors.grey : AppColors.bg)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bouton outline ────────────────────────────────────────────
class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const OutlineBtn({super.key, required this.label, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: AppColors.grey), SizedBox(width: 6)],
            Text(label,
                style: TextStyle(color: AppColors.greyLight, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Carte sombre ──────────────────────────────────────────────
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? radius;

  const DarkCard({super.key, required this.child, this.padding, this.color, this.onTap, this.radius});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: radius ?? BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  AppBadge(this.text, {super.key, Color? color, Color? textColor})
      : color = color ?? const Color(0xFF7B5EA7),
        textColor = textColor ?? const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5)),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: AppColors.border);
}

// ── Stat chip ────────────────────────────────────────────────
class StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatChip({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: AppColors.gold, size: 22),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.grey)),
    ]);
  }
}
