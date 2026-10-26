import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';

/// Real settings only: account, cache, support links and app version.
/// No placeholder toggles that do nothing.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  void _clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    AppSnack.success(context, 'Image cache cleared');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _SectionLabel('Account'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.profile,
                      color: AppTokens.inkSecondary),
                  title: Text(
                    auth.displayName.isEmpty ? 'Haven guest' : auth.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(auth.profileEmail.isEmpty
                      ? 'Not signed in'
                      : auth.profileEmail),
                  trailing: const Icon(AppIcons.chevron,
                      size: 18, color: AppTokens.inkTertiary),
                  onTap: auth.isLoggedIn
                      ? () =>
                          Navigator.of(context).pushNamed('/profile/edit')
                      : null,
                ),
                const Divider(height: 1),
                _SettingTile(
                  icon: AppIcons.notifications,
                  title: 'Notifications',
                  subtitle: 'Booking status changes',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('App'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SettingTile(
                  icon: AppIcons.gallery,
                  title: 'Clear image cache',
                  subtitle: 'Frees photos kept in memory',
                  onTap: _clearCache,
                ),
                _SettingTile(
                  icon: AppIcons.help,
                  title: 'Help & Support',
                  onTap: () => Navigator.of(context).pushNamed('/help'),
                ),
                _SettingTile(
                  icon: AppIcons.verified,
                  title: 'Terms & Privacy',
                  onTap: () => Navigator.of(context).pushNamed('/legal'),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('About'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Haven',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink)),
                const SizedBox(height: 2),
                Text(
                  _version.isEmpty ? 'Dar es Salaam' : 'Version $_version',
                  style: const TextStyle(
                      fontSize: 13, color: AppTokens.inkSecondary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find and request event venues across Dar es Salaam. '
                  'Every listing is reviewed before it appears in the app.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTokens.inkSecondary),
                ),
              ],
            ),
          ),
          if (auth.isLoggedIn) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.error,
                  side: const BorderSide(color: AppTokens.border),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusButton),
                  ),
                ),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login', (_) => false);
                  }
                },
                icon: const Icon(AppIcons.logout, size: 18),
                label: const Text('Log out'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTokens.inkTertiary)),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool last;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppTokens.inkSecondary),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!,
                  style: const TextStyle(fontSize: 12)),
          trailing: const Icon(AppIcons.chevron,
              size: 18, color: AppTokens.inkTertiary),
          onTap: onTap,
        ),
        if (!last) const Divider(height: 1),
      ],
    );
  }
}

