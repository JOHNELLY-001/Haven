import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';

/// Honest, self-serve support: how bookings/payments work plus a real email
/// route and the host portal.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'How does booking work?',
      'You send a request with your dates and guest count. The venue owner reviews it and approves or declines. '
          'The booking is only confirmed once the status says Confirmed — until then the dates are not held.',
    ),
    (
      'When and how do I pay?',
      'Haven does not take payments in the app. After a host confirms, you agree the deposit and balance directly with them. '
          'Never send money before the host confirms and shares payment details in writing.',
    ),
    (
      'Can I cancel a request?',
      'Yes — while it is still awaiting the host. Open My bookings and tap the cancel icon. Once a host confirms, contact them directly to change or cancel.',
    ),
    (
      'How do reviews work?',
      'After a confirmed booking and the event date has passed, you can rate the venue once from My bookings. '
          'Reviews show your first name and last initial only.',
    ),
    (
      'How do I list my venue?',
      'Use “Host a Venue” on your profile. It opens the Haven host portal, where you use the same email and password as this app. '
          'New and edited listings are reviewed before they appear in the app.',
    ),
  ];

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: ApiConfig.supportEmail,
      query: 'subject=Haven app support',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppSnack.error(context, 'No email app found.');
      }
    } catch (_) {
      if (context.mounted) AppSnack.error(context, 'No email app found.');
    }
  }

  Future<void> _openPortal(BuildContext context, String email) async {
    try {
      final ok = await launchUrl(ApiConfig.hostOnboarding(email: email),
          mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppSnack.error(context, 'Could not open the host portal.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.error(context, 'Could not open the host portal.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text('Common questions',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink)),
          const SizedBox(height: 8),
          ..._faqs.map(
            (f) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.border),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 14),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: AppTokens.primary,
                title: Text(f.$1,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.ink)),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(f.$2,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppTokens.inkSecondary)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Still need a hand?',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink)),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact support and we will reply as soon as we can. Include the venue name and your booking dates so we can help faster.',
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppTokens.inkSecondary),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Contact support',
                  height: 44,
                  onPressed: () => _emailSupport(context),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Open host portal',
                  height: 44,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      _openPortal(context, auth.profileEmail),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
