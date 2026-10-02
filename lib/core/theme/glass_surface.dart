import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Overlay padrão para InkWell sobre superfícies coloridas / glass.
WidgetStateProperty<Color?> get glassInkOverlay =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.hovered)) {
        return Colors.white.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.focused)) {
        return Colors.white.withValues(alpha: 0.14);
      }
      return null;
    });

/// Card / botão flutuante com efeito Soft Liquid Glass.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadii.card,
    this.padding,
    this.tint,
    this.onTap,
    this.shadowColor,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final VoidCallback? onTap;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final fill = tint != null
        ? Color.alphaBlend(
            tint!.withValues(alpha: isDark ? 0.18 : 0.22),
            AppColors.glassFill(isDark),
          )
        : AppColors.glassFill(isDark);
    final contentPadding = padding ?? EdgeInsets.zero;

    Widget surface = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurSigma,
          sigmaY: AppColors.glassBlurSigma,
        ),
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: AppColors.glassBorder(isDark),
              width: 1,
            ),
          ),
          child: onTap == null
              ? Padding(padding: contentPadding, child: child)
              : InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  overlayColor: glassInkOverlay,
                  child: Padding(padding: contentPadding, child: child),
                ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: (shadowColor ??
                    (isDark ? Colors.black : const Color(0xFF6E6B7B)))
                .withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: surface,
    );
  }
}

/// Envelope de bottom sheet com Soft Liquid Glass.
///
/// Use [expandChild] para sheets longos (ex.: check-in): o [child] recebe
/// altura limitada e deve ser um [SingleChildScrollView] (ou similar).
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.padding,
    this.showHandle = true,
    this.expandChild = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;
  final bool expandChild;

  static const EdgeInsets defaultPadding = EdgeInsets.fromLTRB(
    AppSpacing.sheetH,
    AppSpacing.sheetTop,
    AppSpacing.sheetH,
    AppSpacing.sheetBottom,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const topRadius = BorderRadius.vertical(
      top: Radius.circular(AppRadii.sheet),
    );
    final media = MediaQuery.of(context);
    final maxSheetHeight = media.size.height * 0.92;

    Widget sheetBody = Padding(
      padding: padding ?? defaultPadding,
      child: Column(
        mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle) ...[
            Center(
              child: Container(
                width: AppSheetHandle.width,
                height: AppSheetHandle.height,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.handle),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );

    Widget painted = ClipRRect(
      borderRadius: topRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurSigma,
          sigmaY: AppColors.glassBlurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassFill(isDark),
            borderRadius: topRadius,
            border: Border(
              top: BorderSide(color: AppColors.glassBorder(isDark), width: 1),
              left: BorderSide(color: AppColors.glassBorder(isDark), width: 1),
              right: BorderSide(color: AppColors.glassBorder(isDark), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: sheetBody,
          ),
        ),
      ),
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: expandChild
          ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: painted,
            )
          : painted,
    );
  }
}
