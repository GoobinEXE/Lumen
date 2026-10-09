import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/lumen_glass_style.dart';

/// Botão circular 44×44 com Liquid Glass — ações no cabeçalho do corpo.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.child,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Substitui o [icon] (ex.: spinner durante importação).
  final Widget? child;

  static const double _size = 44;
  static const double _radius = _size / 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = AppColors.mutedText(isDark);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: enabled
              ? () {
                  if (!reduceMotion) HapticFeedback.selectionClick();
                  onPressed!();
                }
              : null,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: lumenGlassShadow(
                  isDark: isDark,
                  role: LumenGlassRole.chip,
                ),
              ),
              child: LumenGlass(
                role: LumenGlassRole.chip,
                cornerRadius: _radius,
                interactive: enabled,
                child: SizedBox(
                  width: _size,
                  height: _size,
                  child: Center(
                    child: child ?? Icon(icon, size: 20, color: muted),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
