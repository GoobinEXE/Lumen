import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/lumen_glass_style.dart';

/// CTA flutuante Lumen — sem FloatingActionButton Material.
class LumenFab extends StatelessWidget {
  const LumenFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final child = label == null
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: Colors.white, size: 22),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );

    final button = GestureDetector(
      onTap: () {
        if (!reduceMotion) HapticFeedback.lightImpact();
        onPressed();
      },
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.button),
          boxShadow: lumenGlassShadow(
            isDark: Theme.of(context).brightness == Brightness.dark,
            role: LumenGlassRole.chip,
            shadowColor: AppColors.primary,
          ),
        ),
        child: LumenGlass(
          role: LumenGlassRole.chip,
          cornerRadius: AppRadii.button,
          tint: AppColors.primary,
          forceLite: true,
          interactive: true,
          child: ColoredBox(
            color: AppColors.primary.withValues(alpha: 0.82),
            child: child,
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
