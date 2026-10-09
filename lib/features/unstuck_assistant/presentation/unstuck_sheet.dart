import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/widgets/glass_toast.dart';

class UnstuckSheet extends StatefulWidget {
  const UnstuckSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showLumenSheet<void>(
      context: context,
      builder: (ctx) => const LumenKeyboardInset(child: UnstuckSheet()),
    );
  }

  @override
  State<UnstuckSheet> createState() => _UnstuckSheetState();
}

class _UnstuckSheetState extends State<UnstuckSheet>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  int _timerSeconds = 60;
  Timer? _timer;
  bool _timerRunning = false;
  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _orbController.stop();
    } else if (!_orbController.isAnimating) {
      _orbController.repeat(reverse: true);
    }
  }

  void _startTimer() {
    setState(() {
      _timerRunning = true;
      _timerSeconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        t.cancel();
        setState(() => _timerRunning = false);
      }
    });
  }

  void _advance(List<Map<String, String>> microSteps, AppLocalizations l10n) {
    if (_currentStep >= microSteps.length - 1 && _timerSeconds > 0) return;
    HapticFeedback.lightImpact();
    if (_currentStep < microSteps.length - 1) {
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context);
      showGlassToast(context, l10n.unstuckCongratsSnack);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final microSteps = [
      {
        'title': l10n.unstuckStep1Title,
        'instruction': l10n.unstuckStep1Instruction,
        'action': l10n.unstuckStep1Action,
      },
      {
        'title': l10n.unstuckStep2Title,
        'instruction': l10n.unstuckStep2Instruction,
        'action': l10n.unstuckStep2Action,
      },
      {
        'title': l10n.unstuckStep3Title,
        'instruction': l10n.unstuckStep3Instruction,
        'action': l10n.unstuckStep3Action,
      },
    ];
    final step = microSteps[_currentStep];
    final progress = (60 - _timerSeconds) / 60.0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final timerLabel =
        '${_timerSeconds ~/ 60}:${(_timerSeconds % 60).toString().padLeft(2, '0')}';

    return Material(
      color: AppColors.backgroundDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: AppColors.textLight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AssistantOrb(controller: _orbController),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.unstuck.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            child: Text(
                              l10n.unstuckModeBadge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.unstuck,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            l10n.unstuckSheetTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.unstuckSheetSubtitle,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: List.generate(3, (index) {
                    final active = index <= _currentStep;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 6,
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.unstuck
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.08)),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.unstuck.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 22),

                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: Semantics(
                    key: ValueKey(_currentStep),
                    container: true,
                    excludeSemantics: true,
                    label: '${step['title']!}. ${step['instruction']!}',
                    child: GlassSurface(
                      borderRadius: AppRadii.card,
                      padding: const EdgeInsets.all(18),
                      tint: AppColors.unstuck,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title']!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.unstuck,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step['instruction']!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Reserva altura do timer em todos os steps (anti CLS).
                Visibility(
                  visible: _currentStep == 2,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CustomPaint(
                            painter: _TimerRingPainter(
                              progress: _timerRunning ? progress : 0,
                              trackColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.06),
                              progressColor: AppColors.unstuck,
                            ),
                            child: Center(
                              child: Semantics(
                                liveRegion: true,
                                excludeSemantics: true,
                                label: timerLabel,
                                child: Text(
                                  timerLabel,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: _timerRunning
                                        ? AppColors.unstuck
                                        : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: (!_timerRunning && _timerSeconds == 60)
                              ? ElevatedButton.icon(
                                  onPressed: _startTimer,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(l10n.startTimerButton),
                                )
                              : (_timerRunning
                                    ? Text(
                                        l10n.unstuckTimerHint,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: isDark
                                              ? AppColors.textMutedDark
                                              : AppColors.textMuted,
                                        ),
                                      )
                                    : const SizedBox.shrink()),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _GradientCta(
                  label: _currentStep < microSteps.length - 1
                      ? step['action']!
                      : l10n.finishUnstuckButton,
                  onPressed:
                      _currentStep == microSteps.length - 1 && _timerSeconds > 0
                      ? null
                      : () => _advance(microSteps, l10n),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantOrb extends StatelessWidget {
  const _AssistantOrb({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _orb(scale: 1, glow: 0.35);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(controller.value);
        return _orb(scale: 0.96 + (0.08 * t), glow: 0.25 + (0.2 * t));
      },
    );
  }

  Widget _orb({required double scale, required double glow}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.unstuck,
          boxShadow: [
            BoxShadow(
              color: AppColors.unstuck.withValues(alpha: glow),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.button),
              color: AppColors.unstuck,
              boxShadow: [
                BoxShadow(
                  color: AppColors.unstuck.withValues(
                    alpha: enabled ? 0.28 : 0.1,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.button),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                overlayColor: glassInkOverlay,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
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

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 6;
    const stroke = 6.0;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final active = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
