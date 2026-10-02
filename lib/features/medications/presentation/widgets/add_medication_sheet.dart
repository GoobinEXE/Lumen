import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../core/widgets/async_placeholders.dart';
import '../../domain/medication.dart';
import '../providers/medication_providers.dart';
import 'system_time_picker.dart';

class AddMedicationSheet extends ConsumerStatefulWidget {
  const AddMedicationSheet({super.key, this.existing});

  final Medication? existing;

  static Future<void> show(BuildContext context, {Medication? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: AddMedicationSheet(existing: existing),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  late final TextEditingController _instructionsController;

  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  int _durationHours = 12;
  int _keptTotalStock = 30;
  String _shapeIcon = 'capsule';
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  List<Map<String, dynamic>> _presetsFor(AppLocalizations l10n) => [
    {
      'name': l10n.presetVenvanse,
      'dosage': '30mg',
      'duration': 12,
      'icon': 'capsule',
    },
    {
      'name': l10n.presetRitalina,
      'dosage': '10mg',
      'duration': 4,
      'icon': 'tablet',
    },
    {
      'name': l10n.presetRitalinaLa,
      'dosage': '20mg',
      'duration': 8,
      'icon': 'capsule',
    },
    {
      'name': l10n.presetConcerta,
      'dosage': '36mg',
      'duration': 12,
      'icon': 'capsule',
    },
    {
      'name': l10n.presetAtentah,
      'dosage': '40mg',
      'duration': 24,
      'icon': 'capsule',
    },
    {
      'name': l10n.presetBupropiona,
      'dosage': '150mg',
      'duration': 12,
      'icon': 'tablet',
    },
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final l10n = ref.read(appLocalizationsProvider);
    if (existing == null) {
      _dosageController.text = '30mg';
      _stockController.text = '28';
      _instructionsController = TextEditingController(
        text: l10n.defaultInstructionsMorning,
      );
      return;
    }

    _nameController.text = existing.name;
    _dosageController.text = existing.dosage;
    _stockController.text = '${existing.remainingStock}';
    _durationHours = existing.durationHours.clamp(1, 24);
    _keptTotalStock = existing.totalStock;
    _shapeIcon = existing.shapeIcon;
    _times = existing.scheduledTimes.map(_parseTime).toList();
    if (_times.isEmpty) {
      _times = [const TimeOfDay(hour: 8, minute: 0)];
    }
    _instructionsController = TextEditingController(
      text: existing.instructions,
    );
  }

  TimeOfDay _parseTime(String raw) {
    final parts = raw.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'] as String;
      _dosageController.text = preset['dosage'] as String;
      _durationHours = preset['duration'] as int;
      _shapeIcon = preset['icon'] as String;
    });
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      _nameFocus.requestFocus();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final times = <String>[];
    for (final time in _times) {
      final formatted = _formatTime(time);
      if (!times.contains(formatted)) times.add(formatted);
    }
    final stock = int.tryParse(_stockController.text.trim()) ?? 30;
    final existing = widget.existing;
    final totalStock = existing == null
        ? stock
        : (stock > _keptTotalStock ? stock : _keptTotalStock);

    final saved = Medication(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      dosage: _dosageController.text.trim().isEmpty
          ? l10n.defaultDoseFallback
          : _dosageController.text.trim(),
      shapeIcon: _shapeIcon,
      scheduledTimes: times,
      totalStock: totalStock,
      remainingStock: stock,
      durationHours: _durationHours.clamp(1, 24),
      instructions: _instructionsController.text.trim().isEmpty
          ? l10n.defaultMedInstructions
          : _instructionsController.text.trim(),
      active: existing?.active ?? true,
      daysOfWeek: existing?.daysOfWeek ?? const [1, 2, 3, 4, 5, 6, 7],
      refillWarningThreshold: existing?.refillWarningThreshold ?? 5,
      appleConceptId: existing?.appleConceptId,
      rxNormCode: existing?.rxNormCode,
      source: existing?.source ?? MedicationSource.local,
    );

    try {
      await ref
          .read(todayMedicationLogsProvider.notifier)
          .saveMedication(saved);

      if (mounted) {
        Navigator.pop(context);
        final message = existing == null
            ? l10n.medRegisteredSuccess(name)
            : l10n.medUpdatedSuccess(name);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final narrow = isNarrow(context);

    final nameField = TextFormField(
      controller: _nameController,
      focusNode: _nameFocus,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.medNameRequiredError;
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: l10n.medNameLabel,
        hintText: l10n.medNameHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
    );
    final dosageField = TextField(
      controller: _dosageController,
      decoration: InputDecoration(
        labelText: l10n.medDosageLabel,
        hintText: l10n.medDosageHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
    );
    final timesEditor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _times.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(0, kMinTapTarget),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                  ),
                  onPressed: () async {
                    final picked = await showSystemTimePicker(
                      context: context,
                      initialTime: _times[i],
                    );
                    if (picked == null) return;
                    setState(() => _times[i] = picked);
                  },
                  icon: const Icon(Icons.alarm_rounded, size: 18),
                  label: Text(
                    l10n.medReminderLabel(_times[i].format(context)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (_times.length > 1)
                IconButton(
                  tooltip: l10n.medRemoveTimeTooltip,
                  onPressed: () => setState(() => _times.removeAt(i)),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              final last = _times.last;
              setState(() {
                _times = [
                  ..._times,
                  TimeOfDay(hour: (last.hour + 1) % 24, minute: last.minute),
                ];
              });
            },
            icon: const Icon(AppIcons.add, size: 18),
            label: Text(l10n.medAddTimeButton),
          ),
        ),
      ],
    );
    final durationEditor = Row(
      children: [
        IconButton(
          onPressed: _durationHours <= 1
              ? null
              : () => setState(() => _durationHours--),
          icon: const Icon(Icons.remove_rounded),
        ),
        Expanded(
          child: Text(
            l10n.medWindowHours(_durationHours),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
        ),
        IconButton(
          onPressed: _durationHours >= 24
              ? null
              : () => setState(() => _durationHours++),
          icon: const Icon(AppIcons.add),
        ),
      ],
    );
    final stockField = TextField(
      controller: _stockController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: l10n.medCapsulesInBottleLabel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
    );

    return GlassSheet(
      expandChild: true,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? l10n.editMedicationSheetTitle
                          : l10n.newMedicationSheetTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                l10n.frequentSuggestionsLabel,
                style: TextStyle(
                  fontSize: kMinBodySecondary,
                  color: AppColors.mutedText(isDark),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _presetsFor(l10n).map((p) {
                  return ActionChip(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    avatar: Icon(
                      AppIcons.forMedicationShape(p['icon'] as String),
                      size: 16,
                    ),
                    label: Text(p['name'] as String),
                    onPressed: () => _applyPreset(p),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.section),

              if (narrow) ...[
                nameField,
                const SizedBox(height: 12),
                dosageField,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: nameField),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: dosageField),
                  ],
                ),

              const SizedBox(height: AppSpacing.section),

              if (narrow) ...[
                timesEditor,
                durationEditor,
                const SizedBox(height: 12),
                stockField,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          timesEditor,
                          durationEditor,
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: stockField),
                  ],
                ),

              const SizedBox(height: AppSpacing.section),

              TextField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: l10n.medInstructionsLabel,
                  hintText: l10n.medInstructionsHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _save(l10n),
                  child: BusyButtonChild(
                    busy: _isSaving,
                    label: Text(l10n.saveMedicationButton),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
