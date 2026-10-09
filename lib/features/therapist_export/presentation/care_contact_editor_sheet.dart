import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../data/therapist_contact_repository.dart';
import '../domain/care_contact.dart';
import 'care_contact_labels.dart';
import '../../../core/widgets/glass_toast.dart';

/// Sheet para criar ou editar um contato da rede de apoio.
class CareContactEditorSheet extends ConsumerStatefulWidget {
  const CareContactEditorSheet({super.key, this.existing});

  final CareContact? existing;

  static Future<void> show(BuildContext context, {CareContact? existing}) {
    return showLumenSheet<void>(
      context: context,
      builder: (context) => CareContactEditorSheet(existing: existing),
    );
  }

  @override
  ConsumerState<CareContactEditorSheet> createState() =>
      _CareContactEditorSheetState();
}

class _CareContactEditorSheetState
    extends ConsumerState<CareContactEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  late CareContactRole _role;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    for (final node in [_nameFocus, _phoneFocus]) {
      node.addListener(() {
        if (!node.hasFocus) return;
        final ctx = node.context;
        if (ctx != null) lumenEnsureSheetFieldVisible(ctx);
      });
    }
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.displayName ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _role = existing?.role ?? CareContactRole.therapist;
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty && phone.isEmpty) {
      showGlassToast(context, l10n.careContactEmptyError);
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final existing = widget.existing;
    final contact = CareContact(
      id: existing?.id ?? const Uuid().v4(),
      role: _role,
      displayName: name.isEmpty ? null : name,
      phone: phone,
      updatedAt: DateTime.now(),
    );
    await ref.read(careContactsProvider.notifier).upsert(contact);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete(AppLocalizations l10n) async {
    final existing = widget.existing;
    if (existing == null || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.careContactDeleteConfirmTitle(
            careContactDisplayName(l10n, existing),
          ),
        ),
        content: Text(l10n.careContactDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.careContactDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    await ref.read(careContactsProvider.notifier).delete(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(bool isDark, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);

    return GlassSheet(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sheetTop,
        AppSpacing.screenH,
        AppSpacing.sheetBottom,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing
                  ? l10n.careContactEditorTitleEdit
                  : l10n.careContactEditorTitleNew,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.careContactRoleLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            DropdownButtonFormField<CareContactRole>(
              initialValue: _role,
              decoration: _decoration(isDark),
              borderRadius: BorderRadius.circular(AppRadii.input),
              items: [
                for (final role in CareContactRole.values)
                  DropdownMenuItem<CareContactRole>(
                    value: role,
                    child: Text(careContactRoleLabel(l10n, role)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = value);
              },
            ),
            const SizedBox(height: 16),
            Text(l10n.careContactNameLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              scrollPadding: lumenSheetFieldScrollPadding,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: _decoration(isDark, hint: l10n.careContactNameHint),
            ),
            const SizedBox(height: 16),
            Text(l10n.careContactPhoneLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              scrollPadding: lumenSheetFieldScrollPadding,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: _decoration(isDark, hint: l10n.careContactPhoneHint),
              onSubmitted: (_) => _save(l10n),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _saving ? null : () => _save(l10n),
                child: Text(l10n.saveButton),
              ),
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving ? null : () => _delete(l10n),
                  child: Text(l10n.careContactDeleteButton),
                ),
              ),
            ],
          ],
        ),
    );
  }
}
