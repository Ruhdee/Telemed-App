import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/theme/app_colors.dart';

/// Language selector widget for choosing app language
class LanguageSelector extends ConsumerWidget {
  final bool showAsDialog;

  const LanguageSelector({
    super.key,
    this.showAsDialog = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);

    if (showAsDialog) {
      return _buildDialogSelector(context, ref, currentLocale);
    }

    return _buildListSelector(context, ref, currentLocale);
  }

  Widget _buildDialogSelector(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    return IconButton(
      icon: const Icon(Icons.language),
      onPressed: () => _showLanguageDialog(context, ref, currentLocale),
    );
  }

  Widget _buildListSelector(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    return Column(
      children: [
        _buildLanguageTile(
          context,
          ref,
          'en',
          'English',
          '🇬🇧',
          currentLocale.languageCode == 'en',
        ),
        _buildLanguageTile(
          context,
          ref,
          'hi',
          'हिन्दी',
          '🇮🇳',
          currentLocale.languageCode == 'hi',
        ),
        _buildLanguageTile(
          context,
          ref,
          'mr',
          'मराठी',
          '🇮🇳',
          currentLocale.languageCode == 'mr',
        ),
      ],
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref,
    String languageCode,
    String languageName,
    String flag,
    bool isSelected,
  ) {
    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 32),
      ),
      title: Text(
        languageName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.goldPrimary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.goldPrimary)
          : null,
      onTap: () async {
        await ref.read(languageProvider.notifier).changeLanguage(languageCode);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to $languageName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogLanguageOption(
                context,
                ref,
                'en',
                'English',
                '🇬🇧',
                currentLocale.languageCode == 'en',
              ),
              _buildDialogLanguageOption(
                context,
                ref,
                'hi',
                'हिन्दी',
                '🇮🇳',
                currentLocale.languageCode == 'hi',
              ),
              _buildDialogLanguageOption(
                context,
                ref,
                'mr',
                'मराठी',
                '🇮🇳',
                currentLocale.languageCode == 'mr',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String languageCode,
    String languageName,
    String flag,
    bool isSelected,
  ) {
    return RadioListTile<String>(
      value: languageCode,
      groupValue: isSelected ? languageCode : null,
      onChanged: (value) async {
        if (value != null) {
          await ref.read(languageProvider.notifier).changeLanguage(value);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Language changed to $languageName'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      title: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(languageName),
        ],
      ),
      activeColor: AppColors.goldPrimary,
    );
  }
}
