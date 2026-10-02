import 'package:flutter/material.dart';
import '../../features/routine_mood/domain/mood_entry.dart';

/// Ícones do app via Material Icons (Apache 2.0 / open source).
/// Sem emojis — apenas IconData renderizáveis em qualquer plataforma.
class AppIcons {
  AppIcons._();

  // Ações / navegação
  static const IconData checkin = Icons.auto_awesome_rounded;
  static const IconData unstuck = Icons.bolt_outlined;
  static const IconData medication = Icons.medication_outlined;
  static const IconData medicationFilled = Icons.medication_rounded;
  static const IconData water = Icons.water_drop_outlined;
  static const IconData routine = Icons.wb_sunny_outlined;
  static const IconData routineFilled = Icons.wb_sunny_rounded;
  static const IconData therapist = Icons.psychology_outlined;
  static const IconData spa = Icons.spa_outlined;
  static const IconData sleep = Icons.bedtime_rounded;
  static const IconData focusTarget = Icons.center_focus_strong_rounded;
  static const IconData block = Icons.block_rounded;
  static const IconData tip = Icons.tips_and_updates_outlined;
  static const IconData brain = Icons.psychology_alt_outlined;
  static const IconData headphones = Icons.headphones_rounded;
  static const IconData sprout = Icons.eco_outlined;
  static const IconData tasks = Icons.checklist_outlined;
  static const IconData sparkle = Icons.auto_awesome_rounded;
  static const IconData couch = Icons.weekend_outlined;
  static const IconData sunrise = Icons.wb_twilight_rounded;
  static const IconData anchor = Icons.anchor_rounded;
  static const IconData calendar = Icons.calendar_month_outlined;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData darkMode = Icons.dark_mode_outlined;
  static const IconData lightMode = Icons.light_mode_outlined;
  static const IconData systemMode = Icons.brightness_auto_outlined;
  static const IconData phone = Icons.smartphone_rounded;
  static const IconData home = Icons.schedule_outlined;
  static const IconData homeFilled = Icons.schedule_rounded;
  static const IconData clinic = Icons.monitor_heart_outlined;
  static const IconData clinicFilled = Icons.monitor_heart_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData delete = Icons.delete_outline;
  static const IconData edit = Icons.edit_outlined;
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData search = Icons.search;
  static const IconData forward = Icons.arrow_forward_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteOutline = Icons.favorite_outline_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData upload = Icons.upload_rounded;
  static const IconData settings = Icons.settings_outlined;
  static const IconData chat = Icons.chat_outlined;
  static const IconData copy = Icons.copy_rounded;
  static const IconData image = Icons.image_outlined;
  static const IconData pdf = Icons.picture_as_pdf_outlined;
  static const IconData health = Icons.health_and_safety_outlined;
  static const IconData language = Icons.language_rounded;

  // Idiomas (sem bandeira emoji)
  static const IconData langSystem = Icons.smartphone_rounded;
  static const IconData langPt = Icons.translate_rounded;
  static const IconData langEn = Icons.translate_rounded;
  static const IconData langJa = Icons.translate_rounded;
  static const IconData langEs = Icons.translate_rounded;

  static IconData forFocus(FocusState state) {
    switch (state) {
      case FocusState.focused:
        return Icons.center_focus_strong_rounded;
      case FocusState.hyperfocus:
        return Icons.bolt_rounded;
      case FocusState.scattered:
        return Icons.blur_on_rounded;
      case FocusState.paralyzed:
        return Icons.pause_circle_outline_rounded;
    }
  }

  static IconData forEnergy(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.drained:
        return Icons.battery_0_bar_rounded;
      case EnergyLevel.low:
        return Icons.battery_2_bar_rounded;
      case EnergyLevel.balanced:
        return Icons.battery_full_rounded;
      case EnergyLevel.energized:
        return Icons.rocket_launch_outlined;
      case EnergyLevel.hyper:
        return Icons.flash_on_rounded;
    }
  }

  static IconData forValence(int valence) {
    switch (valence) {
      case 1:
        return Icons.sentiment_very_dissatisfied_rounded;
      case 2:
        return Icons.sentiment_dissatisfied_rounded;
      case 3:
        return Icons.sentiment_neutral_rounded;
      case 4:
        return Icons.sentiment_satisfied_rounded;
      case 5:
        return Icons.sentiment_very_satisfied_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }

  /// Chaves persistidas: capsule | tablet | liquid | drop
  static IconData forMedicationShape(String? key) {
    switch (key) {
      case 'tablet':
        return Icons.circle_outlined;
      case 'liquid':
        return Icons.science_outlined;
      case 'drop':
        return Icons.water_drop_outlined;
      case 'capsule':
      default:
        return Icons.medication_rounded;
    }
  }

  static IconData forInsight(String key) {
    switch (key) {
      case 'sprout':
        return sprout;
      case 'brain':
        return brain;
      case 'sparkle':
        return sparkle;
      case 'headphones':
        return headphones;
      default:
        return tip;
    }
  }

  static IconData forMorningFeeling(String feeling) {
    final lower = feeling.toLowerCase();
    if (lower.contains('névoa') ||
        lower.contains('grogue') ||
        lower.contains('fog')) {
      return Icons.cloud_outlined;
    }
    if (lower.contains('calmo') ||
        lower.contains('calm') ||
        lower.contains('centrado')) {
      return Icons.self_improvement_rounded;
    }
    if (lower.contains('acelerado') ||
        lower.contains('inquieto') ||
        lower.contains('restless')) {
      return Icons.bolt_rounded;
    }
    if (lower.contains('disposto') ||
        lower.contains('leve') ||
        lower.contains('ready')) {
      return Icons.rocket_launch_outlined;
    }
    if (lower.contains('cansaço') ||
        lower.contains('tired') ||
        lower.contains('residual')) {
      return Icons.sentiment_dissatisfied_rounded;
    }
    return Icons.wb_twilight_rounded;
  }
}
