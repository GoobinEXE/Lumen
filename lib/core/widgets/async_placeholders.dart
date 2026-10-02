import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra arredondada com pulso de opacidade para skeletons locais.
class PulseSkeletonBar extends StatefulWidget {
  const PulseSkeletonBar({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<PulseSkeletonBar> createState() => _PulseSkeletonBarState();
}

class _PulseSkeletonBarState extends State<PulseSkeletonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Slot de loading com altura estável (anti CLS).
class SlotSkeleton extends StatelessWidget {
  const SlotSkeleton({
    super.key,
    required this.height,
    this.bars = 2,
    this.padding = EdgeInsets.zero,
  });

  final double height;
  final int bars;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < bars; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              PulseSkeletonBar(
                width: i == bars - 1 && bars > 1 ? 120 : double.infinity,
                height: i == 0 && bars > 2 ? 16 : 12,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton de formulário (título + blocos) para telas full-screen.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: const [
        PulseSkeletonBar(width: 180, height: 22),
        SizedBox(height: 8),
        PulseSkeletonBar(width: 240, height: 12),
        SizedBox(height: 24),
        _BlockSkeleton(),
        SizedBox(height: 16),
        _BlockSkeleton(),
        SizedBox(height: 16),
        _BlockSkeleton(),
      ],
    );
  }
}

class _BlockSkeleton extends StatelessWidget {
  const _BlockSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight.withValues(alpha: 0.5),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PulseSkeletonBar(width: 140, height: 14),
          SizedBox(height: 12),
          PulseSkeletonBar(height: 12),
          SizedBox(height: 8),
          PulseSkeletonBar(width: 200, height: 12),
        ],
      ),
    );
  }
}

/// Conteúdo de botão: label ou spinner (padrão check-in/rotina).
class BusyButtonChild extends StatelessWidget {
  const BusyButtonChild({
    super.key,
    required this.busy,
    required this.label,
    this.spinnerColor = Colors.white,
    this.spinnerSize = 20,
  });

  final bool busy;
  final Widget label;
  final Color spinnerColor;
  final double spinnerSize;

  @override
  Widget build(BuildContext context) {
    if (!busy) return label;
    return SizedBox(
      height: spinnerSize,
      width: spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: spinnerColor,
      ),
    );
  }
}

/// Crossfade + leve slide entre loading e conteúdo (padrão Unstuck).
class FadeSwap extends StatelessWidget {
  const FadeSwap({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: child,
    );
  }
}
