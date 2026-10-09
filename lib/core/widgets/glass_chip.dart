import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/lumen_glass_style.dart';

/// Pill de seleção no estilo Apple — sem `Chip` Material.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.avatar,
    this.selectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? avatar;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = selectedColor ?? AppColors.primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final textColor = selected
        ? (isDark ? AppColors.textLight : AppColors.textDark)
        : AppColors.mutedText(isDark);

    Widget pill = LumenGlass(
      role: LumenGlassRole.chip,
      tint: selected ? accent : null,
      forceLite: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              avatar!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    if (selected) {
      pill = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(
            color: accent.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        child: pill,
      );
    }

    if (onTap == null) return pill;

    return GestureDetector(
      onTap: () {
        if (!reduceMotion) {
          HapticFeedback.selectionClick();
        }
        onTap!();
      },
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }
}

/// Ação em pill (equivalente a ActionChip sem Material).
class GlassActionChip extends StatelessWidget {
  const GlassActionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GlassChip(
      label: label,
      onTap: onTap,
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
    );
  }
}
