import 'package:flutter/material.dart';
import 'package:noa/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/glass_chip.dart';
import '../domain/state_of_mind_associations.dart';
import '../domain/state_of_mind_entry.dart';
import '../domain/state_of_mind_labels.dart';

/// Fluxo clone do Estado Emocional do Apple Health (valência + labels + associações).
class StateOfMindEditor extends StatefulWidget {
  final StateOfMindEntry? initial;
  final String languageCode;
  final ValueChanged<StateOfMindEntry> onChanged;
  final bool showAssociations;

  const StateOfMindEditor({
    super.key,
    this.initial,
    required this.languageCode,
    required this.onChanged,
    this.showAssociations = true,
  });

  @override
  State<StateOfMindEditor> createState() => _StateOfMindEditorState();
}

class _StateOfMindEditorState extends State<StateOfMindEditor> {
  static const int _collapsedLabelCount = 12;

  late StateOfMindKind _kind;
  late double _valence;
  late Set<String> _labels;
  late Set<String> _associations;
  String _labelQuery = '';
  bool _showAllLabels = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _kind = initial?.kind ?? StateOfMindKind.dailyMood;
    _valence = initial?.valence ?? 0.0;
    _labels = Set<String>.from(initial?.labels ?? {});
    _associations = Set<String>.from(initial?.associations ?? {});
  }

  void _emit() {
    widget.onChanged(
      StateOfMindEntry(
        kind: _kind,
        valence: _valence,
        labels: Set<String>.from(_labels),
        associations: Set<String>.from(_associations),
        timestamp: DateTime.now(),
      ),
    );
  }

  String _valenceCaption(AppLocalizations l10n) {
    if (_valence <= -0.6) return l10n.somValenceVeryUnpleasant;
    if (_valence <= -0.2) return l10n.somValenceUnpleasant;
    if (_valence < 0.2) return l10n.somValenceNeutral;
    if (_valence < 0.6) return l10n.somValencePleasant;
    return l10n.somValenceVeryPleasant;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = widget.languageCode;
    final caption = _valenceCaption(l10n);
    final filteredLabels = StateOfMindLabels.ids.where((id) {
      if (_labelQuery.trim().isEmpty) return true;
      final q = _labelQuery.toLowerCase();
      return id.contains(q) ||
          StateOfMindLabels.label(id, lang).toLowerCase().contains(q);
    }).toList();
    final visibleLabels =
        (_showAllLabels ||
            filteredLabels.length <= _collapsedLabelCount ||
            _labelQuery.trim().isNotEmpty)
        ? filteredLabels
        : filteredLabels.take(_collapsedLabelCount).toList();
    final canToggleLabels =
        filteredLabels.length > _collapsedLabelCount &&
        _labelQuery.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.somKindTitle,
          style: TextStyle(
            fontSize: kMinBodySecondary,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            GlassChip(
              label: l10n.somKindMomentary,
              selected: _kind == StateOfMindKind.momentary,
              onTap: () {
                setState(() => _kind = StateOfMindKind.momentary);
                _emit();
              },
            ),
            GlassChip(
              label: l10n.somKindDaily,
              selected: _kind == StateOfMindKind.dailyMood,
              onTap: () {
                setState(() => _kind = StateOfMindKind.dailyMood);
                _emit();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.somFeelingLabel(caption),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Slider(
          value: _valence,
          min: -1,
          max: 1,
          divisions: 20,
          label: caption,
          activeColor: AppColors.primary,
          onChanged: (v) {
            setState(() => _valence = v);
            _emit();
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.somValenceVeryUnpleasant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: kMinBodySecondary,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            ),
            Flexible(
              child: Text(
                l10n.somValenceVeryPleasant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: kMinBodySecondary,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.somWordsPrompt,
          style: TextStyle(
            fontSize: kMinBodySecondary,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
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
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: visibleLabels.map((id) {
            final selected = _labels.contains(id);
            return GlassChip(
              label: StateOfMindLabels.label(id, lang),
              selected: selected,
              selectedColor: AppColors.accent,
              onTap: () {
                setState(() {
                  if (selected) {
                    _labels.remove(id);
                  } else {
                    _labels.add(id);
                  }
                });
                _emit();
              },
            );
          }).toList(),
        ),
        if (canToggleLabels)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, kMinTapTarget),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => setState(() => _showAllLabels = !_showAllLabels),
              child: Text(
                _showAllLabels ? l10n.showFewerLabels : l10n.showAllLabels,
              ),
            ),
          ),
        if (widget.showAssociations) ...[
          const SizedBox(height: 16),
          Text(
            l10n.somAssociationsPrompt,
            style: TextStyle(
              fontSize: kMinBodySecondary,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: StateOfMindAssociations.ids.map((id) {
              final selected = _associations.contains(id);
              return GlassChip(
                label: StateOfMindAssociations.label(id, lang),
                selected: selected,
                selectedColor: AppColors.accent,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _associations.remove(id);
                    } else {
                      _associations.add(id);
                    }
                  });
                  _emit();
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
