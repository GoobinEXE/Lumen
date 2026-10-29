import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/lumen_glass_style.dart';

/// Pill de seleção — Liquid Glass no iOS; [FilterChip] Material 3 no Android.
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

    if (lumenUsesMaterialChrome()) {
      return FilterChip(
        label: Text(label),
        avatar: avatar,
        selected: selected,
        showCheckmark: false,
        onSelected: onTap == null
            ? null
            : (_) {
                if (!reduceMotion) HapticFeedback.selectionClick();
                onTap!();
              },
        selectedColor: selectedColor == null
            ? null
            : Color.alphaBlend(
                accent.withValues(alpha: 0.28),
                theme.colorScheme.secondaryContainer,
              ),
      );
    }

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

/// Ação em pill (equivalente a ActionChip).
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
    if (lumenUsesMaterialChrome()) {
      return ActionChip(
        label: Text(label),
        avatar: icon == null
            ? null
            : Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        onPressed: onTap,
      );
    }
    return GlassChip(
      label: label,
      onTap: onTap,
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
    );
  }
}
