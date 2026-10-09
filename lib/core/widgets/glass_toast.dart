import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/lumen_glass_style.dart';
import 'glass_nav_bar.dart';

/// Banner inferior glass — substitui `SnackBar` Material.
void showGlassToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      return _GlassToastHost(
        message: message,
        duration: duration,
        onDismiss: () {
          entry.remove();
        },
      );
    },
  );
  overlay.insert(entry);
}

class _GlassToastHost extends StatefulWidget {
  const _GlassToastHost({
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_GlassToastHost> createState() => _GlassToastHostState();
}

class _GlassToastHostState extends State<_GlassToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final reduce = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.reduceMotion;
    _controller = AnimationController(
      vsync: this,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    Future<void>.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = GlassNavBar.reservedBottom(context) + 8;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: AppSpacing.screenH,
      right: AppSpacing.screenH,
      bottom: bottom,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.button),
                boxShadow: lumenGlassShadow(
                  isDark: isDark,
                  role: LumenGlassRole.chip,
                ),
              ),
              child: LumenGlass(
                role: LumenGlassRole.surface,
                cornerRadius: AppRadii.button,
                forceLite: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
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
