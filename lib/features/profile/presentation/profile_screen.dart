import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/l10n/language_provider.dart';

/// Profile & Settings Screen
/// Shows user info and settings options including language selection
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final lang = ref.watch(languageProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        title: Text(loc.translate('myProfile')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.goldGradient,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      LucideIcons.user,
                      size: 60,
                      color: AppColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'user@telemed.com',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user?.role.name.toUpperCase() ?? 'PATIENT',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Settings Sections
            _buildSection(
              title: loc.translate('settings'),
              items: [
                _SettingsItem(
                  icon: LucideIcons.languages,
                  title: loc.translate('language'),
                  subtitle: _getLanguageName(lang.languageCode),
                  onTap: () => context.push('/dashboard/language-settings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                _SettingsItem(
                  icon: LucideIcons.user,
                  title: loc.translate('healthProfile'),
                  subtitle: loc.translate('updateHealthInfo'),
                  onTap: () => context.go('/dashboard/demographics'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildSection(
              title: loc.translate('account'),
              items: [
                _SettingsItem(
                  icon: LucideIcons.mail,
                  title: loc.translate('email'),
                  subtitle: user?.email ?? 'Not set',
                  onTap: null, // Read-only for now
                ),
                _SettingsItem(
                  icon: LucideIcons.phone,
                  title: loc.translate('phoneNumber'),
                  subtitle: user?.phone ?? 'Not set',
                  onTap: null, // Read-only for now
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildSection(
              title: loc.translate('support'),
              items: [
                _SettingsItem(
                  icon: LucideIcons.star,
                  title: loc.translate('feedback'),
                  subtitle: loc.translate('shareYourExperience'),
                  onTap: () => context.go('/dashboard/feedback'),
                ),
                _SettingsItem(
                  icon: LucideIcons.helpCircle,
                  title: loc.translate('help'),
                  subtitle: loc.translate('faqAndSupport'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('comingSoon'))),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(loc.translate('logout')),
                        content: Text(loc.translate('logoutConfirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(loc.translate('cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: Text(loc.translate('logout')),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.logOut, color: AppColors.error),
                  label: Text(
                    loc.translate('logout'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<_SettingsItem> items}) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'mr':
        return 'मराठी (Marathi)';
      default:
        return 'English';
    }
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.goldPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 24, color: AppColors.goldDark),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}
