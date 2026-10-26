import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Privacy policy and terms. Kept close to the host portal copy so guests and
/// hosts see one consistent policy.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  static const _privacy = [
    (
      'What we collect',
      'Your name, email, phone and password (stored only as a hash). For venues: the listing details, pricing, contact numbers and photos you submit.',
    ),
    (
      'Bookings',
      'When you request a booking we store the dates, guest count, event type, notes and the contact details you provide. The venue owner sees those details so they can respond.',
    ),
    (
      'Public information',
      'Approved venues show their name, business name, description, area, capacity, facilities, pricing, photos, published contact numbers, rating and public reviews. Public reviews show your first name and last initial.',
    ),
    (
      'Private information',
      'Your Haven login email, password and account phone are not shown on a venue listing. Booking contact details are shared only with the owner of that venue for that booking.',
    ),
    (
      'Storage and providers',
      'Data is stored in a managed PostgreSQL database. Photos are hosted by Cloudinary and the apps are served by Vercel. We do not sell personal data.',
    ),
    (
      'Payments',
      'Haven does not process card or mobile-money payments. Deposit figures are estimates; payment is arranged directly with the venue.',
    ),
    (
      'Your choices',
      'Edit your name, phone and email in Edit profile, and any listing in the host portal. To delete your account or a review, email support.',
    ),
  ];

  static const _terms = [
    (
      'Using Haven',
      'Haven connects guests with venue owners in Tanzania. Provide accurate information and be at least 18 to list a venue or request a booking.',
    ),
    (
      'Listings',
      'Only list spaces you are authorised to represent. Photos, capacity and pricing must be accurate. New and edited listings are reviewed before going live; misleading or unavailable listings may be removed.',
    ),
    (
      'Booking requests',
      'A request is not a reservation. The host approves or declines it. Prices and deposits shown are estimates based on the listing; the final amount is agreed directly with the venue.',
    ),
    (
      'Reviews',
      'One review per completed, approved booking. Reviews must describe a real experience and must not contain abuse, personal data or spam.',
    ),
    (
      'Acceptable use',
      'Do not post false or copied listings, harass other users, attempt to access data you do not own, or scrape the catalogue without permission.',
    ),
    (
      'Liability',
      'Haven is a discovery and booking-request platform. The contract for a venue hire is between the guest and the venue owner. We do not guarantee availability or condition.',
    ),
    (
      'Changes',
      'We may update these pages as the product changes. The latest version is always in the app and on the host portal.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTokens.bg,
        appBar: AppBar(
          title: const Text('Terms & Privacy'),
          bottom: const TabBar(
            labelColor: AppTokens.primary,
            unselectedLabelColor: AppTokens.inkSecondary,
            indicatorColor: AppTokens.primary,
            tabs: [Tab(text: 'Privacy'), Tab(text: 'Terms')],
          ),
        ),
        body: TabBarView(
          children: [
            _LegalList(sections: _privacy, intro: 'PRIVACY POLICY'),
            _LegalList(sections: _terms, intro: 'TERMS OF SERVICE'),
          ],
        ),
      ),
    );
  }
}

class _LegalList extends StatelessWidget {
  final List<(String, String)> sections;
  final String intro;
  const _LegalList({required this.sections, required this.intro});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(intro,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: AppTokens.primary)),
        const SizedBox(height: 4),
        const Text('Last updated 26 October 2026',
            style: TextStyle(fontSize: 12, color: AppTokens.inkTertiary)),
        const SizedBox(height: 16),
        ...sections.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$1,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink)),
                const SizedBox(height: 4),
                Text(s.$2,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppTokens.inkSecondary)),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppTokens.border),
          ),
          child: const Text(
            'Questions? Use Help & Support to email us and we will respond.',
            style: TextStyle(fontSize: 12, color: AppTokens.inkSecondary),
          ),
        ),
      ],
    );
  }
}
