import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/l10n_labels.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/responsive.dart';
import '../../state_of_mind/domain/state_of_mind_labels.dart';
import '../domain/mood_entry.dart';

class QuickCheckinModal extends ConsumerStatefulWidget {
  const QuickCheckinModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        // GlassSheet também lê o inset; zera o de baixo para o teclado não somar duas vezes.
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: MediaQuery.removeViewInsets(
            context: ctx,
            removeBottom: true,
            child: const QuickCheckinModal(),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<QuickCheckinModal> createState() => _QuickCheckinModalState();
}

class _QuickCheckinModalState extends ConsumerState<QuickCheckinModal> {
  int _valence = 3;
  FocusState _focus = FocusState.focused;
  EnergyLevel _energy = EnergyLevel.balanced;
  bool _tookMedication = false;
  bool _sensoryOverload = false;
  final Set<String> _emotionLabels = {};
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _labelQueryController = TextEditingController();
  bool _isSaving = false;
  String _labelQuery = '';

  @override
  void dispose() {
    _noteController.dispose();
    _labelQueryController.dispose();
    super.dispose();
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

    return GlassSheet(
      expandChild: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(AppIcons.back, size: 18),
                ),
                Expanded(
                  child: Text(
                    l10n.checkinModalTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const Center(child: _CheckinHalo()),
            const SizedBox(height: 8),
            Text(l10n.howAreYouFeeling, style: theme.textTheme.headlineMedium),
            Text(l10n.checkinModalSubtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
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
                return FilterChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text(
                    StateOfMindLabels.label(id, languageCode),
                    style: const TextStyle(fontSize: kMinBodySecondary),
                  ),
                  selected: selected,
                  selectedColor: isDark
                      ? AppColors.accent.withValues(alpha: 0.35)
                      : AppColors.accentSoft,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _emotionLabels.add(id);
                      } else {
                        _emotionLabels.remove(id);
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
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.accent,
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _energy == el
                                      ? AppColors.accent
                                      : AppColors.accent.withValues(
                                          alpha: 0.25,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
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
                FilterChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  avatar: const Icon(AppIcons.medication, size: 16),
                  label: Text(l10n.tookMedicationChip),
                  selected: _tookMedication,
                  onSelected: (val) => setState(() => _tookMedication = val),
                ),
                FilterChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  avatar: const Icon(Icons.volume_up_outlined, size: 16),
                  label: Text(l10n.sensoryOverloadChip),
                  selected: _sensoryOverload,
                  onSelected: (val) => setState(() => _sensoryOverload = val),
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? () {}
                    : () async {
                        HapticFeedback.lightImpact();
                        setState(() => _isSaving = true);
                        await ref
                            .read(moodEntriesProvider.notifier)
                            .addEntry(
                              valence: _valence,
                              energy: _energy,
                              focus: _focus,
                              tookMedication: _tookMedication,
                              sensoryOverload: _sensoryOverload,
                              note: _noteController.text.trim().isEmpty
                                  ? null
                                  : _noteController.text.trim(),
                              emotionLabels: Set<String>.from(_emotionLabels),
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.checkinSavedSuccess),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Theme.of(context)
                                  .elevatedButtonTheme
                                  .style
                                  ?.foregroundColor
                                  ?.resolve({}) ??
                              Colors.white,
                        ),
                      )
                    : Text(l10n.saveCheckinButton),
              ),
            ),
          ],
        ),
      ),
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

class _CheckinHalo extends StatelessWidget {
  const _CheckinHalo();

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
