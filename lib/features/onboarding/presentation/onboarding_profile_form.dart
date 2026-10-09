import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/widgets/glass_chip.dart';
import '../../profile/domain/voice_tone_profile.dart';
import '../../profile/presentation/profile_labels.dart';
import '../domain/onboarding_profile_draft.dart';

/// Formulário do perfil na primeira abertura. Estado de seleção e texto fica
/// aqui; a cada mudança o rascunho completo sobe por [onChanged].
class OnboardingProfileForm extends StatefulWidget {
  const OnboardingProfileForm({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.l10n,
  });

  final OnboardingProfileDraft draft;
  final ValueChanged<OnboardingProfileDraft> onChanged;
  final AppLocalizations l10n;

  @override
  State<OnboardingProfileForm> createState() => _OnboardingProfileFormState();
}

class _OnboardingProfileFormState extends State<OnboardingProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late OnboardingProfileDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _name = TextEditingController(text: _draft.name ?? '');
    _height = TextEditingController(text: _metricText(_draft.heightCm));
    _weight = TextEditingController(text: _metricText(_draft.weightKg));
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  static String _metricText(double? value) {
    if (value == null) return '';
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  void _update(OnboardingProfileDraft next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _draft.birthDate ?? DateTime(now.year - 25, now.month, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    HapticFeedback.selectionClick();
    _update(_draft.copyWith(birthDate: picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = widget.l10n;
    final muted = AppColors.mutedText(isDark);
    final missing = _draft.missingFields;
    final heightText = _height.text.trim();
    final weightText = _weight.text.trim();
    final heightInvalid = heightText.isNotEmpty &&
        !OnboardingProfileDraft.isValidHeight(_draft.heightCm);
    final weightInvalid = weightText.isNotEmpty &&
        !OnboardingProfileDraft.isValidWeight(_draft.weightKg);
    final dateFormat = DateFormat.yMMMMd(l10n.localeName);

    InputDecoration decoration(String label, {String? hint, String? error}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.givenName],
          decoration: decoration(
            l10n.profileNameLabel,
            hint: l10n.profileNameHint,
          ),
          onChanged: (value) => _update(_draft.copyWith(name: value)),
        ),
        const SizedBox(height: AppSpacing.section),
        _FieldLabel(
          text: l10n.onboardingBirthDateLabel,
          fromHealth:
              _draft.healthFilled.contains(OnboardingProfileField.birthDate),
          l10n: l10n,
        ),
        const SizedBox(height: 8),
        GlassSurface(
          borderRadius: AppRadii.input,
          onTap: _pickBirthDate,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(AppIcons.calendar, size: 20, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _draft.birthDate == null
                      ? l10n.onboardingBirthDatePick
                      : dateFormat.format(_draft.birthDate!),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _draft.birthDate == null ? muted : null,
                  ),
                ),
              ),
              Icon(AppIcons.edit, size: 18, color: muted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        _FieldLabel(text: l10n.onboardingVoiceToneLabel, l10n: l10n),
        const SizedBox(height: 4),
        Text(
          l10n.onboardingVoiceToneHint,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tone in VoiceToneProfile.values)
              GlassChip(
                label: voiceToneLabel(l10n, tone),
                selected: _draft.voiceToneProfile == tone,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _update(_draft.copyWith(voiceToneProfile: tone));
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _height,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: decoration(
                      l10n.onboardingHeightLabel,
                      error: heightInvalid ? l10n.onboardingInvalidNumber : null,
                    ),
                    onChanged: (value) {
                      final parsed = OnboardingProfileDraft.parseMetric(value);
                      _update(
                        _draft.copyWith(
                          heightCm: parsed,
                          clearHeightCm: parsed == null,
                        ),
                      );
                    },
                  ),
                  if (_draft.healthFilled
                      .contains(OnboardingProfileField.heightCm))
                    _HealthTag(l10n: l10n),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: decoration(
                      l10n.onboardingWeightLabel,
                      error: weightInvalid ? l10n.onboardingInvalidNumber : null,
                    ),
                    onChanged: (value) {
                      final parsed = OnboardingProfileDraft.parseMetric(value);
                      _update(
                        _draft.copyWith(
                          weightKg: parsed,
                          clearWeightKg: parsed == null,
                        ),
                      );
                    },
                  ),
                  if (_draft.healthFilled
                      .contains(OnboardingProfileField.weightKg))
                    _HealthTag(l10n: l10n),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        _FieldLabel(
          text: l10n.onboardingBiologicalSexLabel,
          fromHealth: _draft.healthFilled
              .contains(OnboardingProfileField.biologicalSex),
          l10n: l10n,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in biologicalSexCodes)
              GlassChip(
                label: biologicalSexLabel(l10n, code),
                selected: _draft.biologicalSex == code,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _update(_draft.copyWith(biologicalSex: code));
                },
              ),
          ],
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.onboardingMissingFields(
                missing.map((f) => _fieldLabel(l10n, f)).join(' · '),
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ],
    );
  }

  static String _fieldLabel(AppLocalizations l10n, OnboardingProfileField f) {
    switch (f) {
      case OnboardingProfileField.name:
        return l10n.profileNameLabel;
      case OnboardingProfileField.birthDate:
        return l10n.onboardingBirthDateLabel;
      case OnboardingProfileField.voiceTone:
        return l10n.onboardingVoiceToneLabel;
      case OnboardingProfileField.heightCm:
        return l10n.onboardingHeightLabel;
      case OnboardingProfileField.weightKg:
        return l10n.onboardingWeightLabel;
      case OnboardingProfileField.biologicalSex:
        return l10n.onboardingBiologicalSexLabel;
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.l10n,
    this.fromHealth = false,
  });

  final String text;
  final AppLocalizations l10n;
  final bool fromHealth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (fromHealth) _HealthTag(l10n: l10n),
      ],
    );
  }
}

class _HealthTag extends StatelessWidget {
  const _HealthTag({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.primaryLight : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.favorite, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.onboardingFromHealthTag,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
