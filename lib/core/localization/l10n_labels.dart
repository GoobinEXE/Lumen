import 'package:noa/l10n/app_localizations.dart';

import '../../features/routine_mood/domain/mood_entry.dart';
import '../../features/state_of_mind/domain/state_of_mind_entry.dart';

extension FocusStateLabels on FocusState {
  String label(AppLocalizations l10n) {
    switch (this) {
      case FocusState.focused:
        return l10n.focusFocused;
      case FocusState.hyperfocus:
        return l10n.focusHyperfocus;
      case FocusState.scattered:
        return l10n.focusScattered;
      case FocusState.paralyzed:
        return l10n.focusParalyzed;
    }
  }

  String description(AppLocalizations l10n) {
    switch (this) {
      case FocusState.focused:
        return l10n.focusFocusedDesc;
      case FocusState.hyperfocus:
        return l10n.focusHyperfocusDesc;
      case FocusState.scattered:
        return l10n.focusScatteredDesc;
      case FocusState.paralyzed:
        return l10n.focusParalyzedDesc;
    }
  }
}

extension EnergyLevelLabels on EnergyLevel {
  String label(AppLocalizations l10n) {
    switch (this) {
      case EnergyLevel.drained:
        return l10n.energyDrained;
      case EnergyLevel.low:
        return l10n.energyLow;
      case EnergyLevel.balanced:
        return l10n.energyBalanced;
      case EnergyLevel.energized:
        return l10n.energyEnergized;
      case EnergyLevel.hyper:
        return l10n.energyHyper;
    }
  }

  String description(AppLocalizations l10n) {
    switch (this) {
      case EnergyLevel.drained:
        return l10n.energyDrainedDesc;
      case EnergyLevel.low:
        return l10n.energyLowDesc;
      case EnergyLevel.balanced:
        return l10n.energyBalancedDesc;
      case EnergyLevel.energized:
        return l10n.energyEnergizedDesc;
      case EnergyLevel.hyper:
        return l10n.energyHyperDesc;
    }
  }
}

extension MoodEntryLabels on MoodEntry {
  String valenceLabel(AppLocalizations l10n) {
    switch (valence) {
      case 1:
        return l10n.valenceVeryDifficult;
      case 2:
        return l10n.valenceHeavy;
      case 3:
        return l10n.valenceNeutral;
      case 4:
        return l10n.valenceBom;
      case 5:
        return l10n.valenceExcellent;
      default:
        return l10n.valenceNeutral;
    }
  }
}

extension StateOfMindEntryLabels on StateOfMindEntry {
  String valenceLabel(AppLocalizations l10n) {
    if (valence <= -0.6) return l10n.somValenceVeryUnpleasant;
    if (valence <= -0.2) return l10n.somValenceUnpleasant;
    if (valence < 0.2) return l10n.somValenceNeutral;
    if (valence < 0.6) return l10n.somValencePleasant;
    return l10n.somValenceVeryPleasant;
  }
}
