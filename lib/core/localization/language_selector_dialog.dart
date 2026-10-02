import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import 'locale_provider.dart';

class LanguageSelectorDialog extends ConsumerWidget {
  const LanguageSelectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const LanguageSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPref = ref.watch(userLocalePreferenceProvider);
    final l10n = ref.watch(appLocalizationsProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.language_rounded),
          const SizedBox(width: 10),
          Text(
            l10n.languageSelectorTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context: context,
            title: l10n.systemDefault,
            icon: AppIcons.langSystem,
            isSelected: currentPref == null,
            onTap: () {
              ref.read(userLocalePreferenceProvider.notifier).setLocale('system');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          _buildOption(
            context: context,
            title: l10n.portuguese,
            icon: AppIcons.langPt,
            isSelected: currentPref?.languageCode == 'pt',
            onTap: () {
              ref.read(userLocalePreferenceProvider.notifier).setLocale('pt');
              Navigator.pop(context);
            },
          ),
          _buildOption(
            context: context,
            title: l10n.english,
            icon: AppIcons.langEn,
            isSelected: currentPref?.languageCode == 'en',
            onTap: () {
              ref.read(userLocalePreferenceProvider.notifier).setLocale('en');
              Navigator.pop(context);
            },
          ),
          _buildOption(
            context: context,
            title: l10n.japanese,
            icon: AppIcons.langJa,
            isSelected: currentPref?.languageCode == 'ja',
            onTap: () {
              ref.read(userLocalePreferenceProvider.notifier).setLocale('ja');
              Navigator.pop(context);
            },
          ),
          _buildOption(
            context: context,
            title: l10n.spanish,
            icon: AppIcons.langEs,
            isSelected: currentPref?.languageCode == 'es',
            onTap: () {
              ref.read(userLocalePreferenceProvider.notifier).setLocale('es');
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.okButton),
        ),
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.success) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
    );
  }
}
