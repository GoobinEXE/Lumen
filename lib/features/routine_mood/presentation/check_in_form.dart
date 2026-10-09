import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/localization/l10n_labels.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/glass_chip.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';
import '../../state_of_mind/domain/state_of_mind_labels.dart';
import '../domain/mood_entry.dart';

/// Valores do Check-in compartilhados entre a sheet da Home e a aba Dia.
class CheckInDraft {
  const CheckInDraft({
    this.valence = 3,
    this.focus = FocusState.focused,
    this.energy = EnergyLevel.balanced,
    this.tookMedication = false,
    this.sensoryOverload = false,
    this.emotionLabels = const {},
    this.note = '',
  });

  final int valence;
  final FocusState focus;
  final EnergyLevel energy;
  final bool tookMedication;
  final bool sensoryOverload;
  final Set<String> emotionLabels;
  final String note;

  CheckInDraft copyWith({
    int? valence,
    FocusState? focus,
    EnergyLevel? energy,
    bool? tookMedication,
    bool? sensoryOverload,
    Set<String>? emotionLabels,
    String? note,
  }) {
    return CheckInDraft(
      valence: valence ?? this.valence,
      focus: focus ?? this.focus,
      energy: energy ?? this.energy,
      tookMedication: tookMedication ?? this.tookMedication,
      sensoryOverload: sensoryOverload ?? this.sensoryOverload,
      emotionLabels: emotionLabels ?? this.emotionLabels,
      note: note ?? this.note,
    );
  }

  StateOfMindEntry toStateOfMind({DateTime? timestamp}) {
    return StateOfMindEntry(
      kind: StateOfMindKind.momentary,
      valence: StateOfMindEntry.checkinScaleToValence(valence),
      labels: Set<String>.from(emotionLabels),
      timestamp: timestamp ?? DateTime.now(),
      source: StateOfMindSource.lumen,
    );
  }
}

/// Formulário visual do Check-in (valência, palavras, foco, energia, chips, nota).
class CheckInForm extends ConsumerStatefulWidget {
  const CheckInForm({
    super.key,
    this.initial,
    this.showHalo = true,
    this.showFeelingHeader = true,
  });

  final CheckInDraft? initial;
  final bool showHalo;
  final bool showFeelingHeader;

  @override
  ConsumerState<CheckInForm> createState() => CheckInFormState();
}

class CheckInFormState extends ConsumerState<CheckInForm> {
  late int _valence;
  late FocusState _focus;
  late EnergyLevel _energy;
  late bool _tookMedication;
  late bool _sensoryOverload;
  late final TextEditingController _noteController;
  final GlobalKey<_EmotionLabelsSectionState> _emotionsKey =
      GlobalKey<_EmotionLabelsSectionState>();
  late Set<String> _initialEmotionLabels;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? const CheckInDraft();
    _valence = initial.valence;
    _focus = initial.focus;
    _energy = initial.energy;
    _tookMedication = initial.tookMedication;
    _sensoryOverload = initial.sensoryOverload;
    _initialEmotionLabels = Set<String>.from(initial.emotionLabels);
    _noteController = TextEditingController(text: initial.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  CheckInDraft draft() {
    final emotions =
        _emotionsKey.currentState?.selectedLabels ?? _initialEmotionLabels;
    return CheckInDraft(
      valence: _valence,
      focus: _focus,
      energy: _energy,
      tookMedication: _tookMedication,
      sensoryOverload: _sensoryOverload,
      emotionLabels: Set<String>.from(emotions),
      note: _noteController.text.trim(),
    );
  }

  void reset([CheckInDraft? next]) {
    final initial = next ?? const CheckInDraft();
    setState(() {
      _valence = initial.valence;
      _focus = initial.focus;
      _energy = initial.energy;
      _tookMedication = initial.tookMedication;
      _sensoryOverload = initial.sensoryOverload;
      _initialEmotionLabels = Set<String>.from(initial.emotionLabels);
      _noteController.text = initial.note;
    });
    _emotionsKey.currentState?.reset(initial.emotionLabels);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHalo) ...[
          const Center(child: CheckInHalo()),
          const SizedBox(height: 8),
        ],
        if (widget.showFeelingHeader) ...[
          Text(l10n.howAreYouFeeling, style: theme.textTheme.headlineMedium),
          Text(l10n.checkinModalSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
        ],
        Text(
          l10n.howAreYouFeeling,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildValenceButton(1, l10n.valenceVeryBad)),
            Expanded(child: _buildValenceButton(2, l10n.valenceHeavy)),
            Expanded(child: _buildValenceButton(3, l10n.valenceNeutral)),
            Expanded(child: _buildValenceButton(4, l10n.valenceGood)),
            Expanded(child: _buildValenceButton(5, l10n.valenceExcellent)),
          ],
        ),
        const SizedBox(height: 20),
        _EmotionLabelsSection(
          key: _emotionsKey,
          initialLabels: _initialEmotionLabels,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.mentalFocusState,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: FocusState.values.map((fs) {
            final isSelected = _focus == fs;
            return Semantics(
              button: true,
              selected: isSelected,
              label: fs.label(l10n),
              child: Material(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.cardDark : AppColors.accentSoft),
                borderRadius: BorderRadius.circular(AppRadii.input),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                  onTap: () => setState(() => _focus = fs),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.forFocus(fs),
                          color: isSelected ? Colors.white : AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fs.label(l10n),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.textLight
                                        : AppColors.textDark),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.energyBatteryState,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final el in EnergyLevel.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: _energy == el,
                  label: el.label(l10n),
                  child: InkWell(
                    onTap: () => setState(() => _energy = el),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: kMinTapTarget,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _energy == el
                                  ? AppColors.accent
                                  : AppColors.accent.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            el.label(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GlassChip(
              label: l10n.tookMedicationChip,
              selected: _tookMedication,
              avatar: const Icon(AppIcons.medication, size: 16),
              onTap: () => setState(() => _tookMedication = !_tookMedication),
            ),
            GlassChip(
              label: l10n.sensoryOverloadChip,
              selected: _sensoryOverload,
              avatar: const Icon(Icons.volume_up_outlined, size: 16),
              onTap: () => setState(() => _sensoryOverload = !_sensoryOverload),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: l10n.optionalNoteHint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildValenceButton(int val, String label) {
    final isSelected = _valence == val;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadii.input);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: ensureMinTapTarget(
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: () => setState(() => _valence = val),
            borderRadius: radius,
            overlayColor: glassInkOverlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.primarySoft)
                    : Colors.transparent,
                borderRadius: radius,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.withValues(alpha: 0.25),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.forValence(val),
                    size: 26,
                    color: isSelected
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: kMinBodySecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Busca + chips de emoção isolados — toque/digitação não rebuilda o form.
class _EmotionLabelsSection extends ConsumerStatefulWidget {
  const _EmotionLabelsSection({
    super.key,
    required this.initialLabels,
  });

  final Set<String> initialLabels;

  @override
  ConsumerState<_EmotionLabelsSection> createState() =>
      _EmotionLabelsSectionState();
}

class _EmotionLabelsSectionState
    extends ConsumerState<_EmotionLabelsSection> {
  late Set<String> _emotionLabels;
  late final TextEditingController _labelQueryController;
  String _labelQuery = '';

  Set<String> get selectedLabels => Set<String>.from(_emotionLabels);

  @override
  void initState() {
    super.initState();
    _emotionLabels = Set<String>.from(widget.initialLabels);
    _labelQueryController = TextEditingController();
  }

  @override
  void dispose() {
    _labelQueryController.dispose();
    super.dispose();
  }

  void reset(Set<String> labels) {
    setState(() {
      _emotionLabels = Set<String>.from(labels);
      _labelQuery = '';
      _labelQueryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final languageCode = ref.watch(activeLocaleProvider).languageCode;
    final filteredLabels = StateOfMindLabels.sortedIds(languageCode).where((
      id,
    ) {
      if (_labelQuery.trim().isEmpty) return true;
      final q = _labelQuery.toLowerCase();
      return id.contains(q) ||
          StateOfMindLabels.label(id, languageCode).toLowerCase().contains(q);
    }).toList();

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.checkinWordsOptional,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _labelQueryController,
            onChanged: (v) => setState(() => _labelQuery = v),
            decoration: InputDecoration(
              hintText: l10n.searchEmotionHint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              isDense: true,
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(AppIcons.search, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: filteredLabels.map((id) {
              final selected = _emotionLabels.contains(id);
              return GlassChip(
                label: StateOfMindLabels.label(id, languageCode),
                selected: selected,
                selectedColor: AppColors.accent,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _emotionLabels.remove(id);
                    } else {
                      _emotionLabels.add(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_emotionLabels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                l10n.emotionsSelectedCount(_emotionLabels.length),
                style: TextStyle(
                  fontSize: kMinBodySecondary,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CheckInHalo extends StatelessWidget {
  const CheckInHalo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            AppColors.primary,
            AppColors.accent,
            AppColors.unstuck,
            AppColors.primary,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
