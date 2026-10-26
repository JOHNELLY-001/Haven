import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/booking_provider.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';

/// Deposit summary from real bookings. Haven does not process mobile money or
/// cards yet, so this screen explains exactly how payment works instead of
/// pretending there is a wallet.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>();
    final relevant = bookings.items
        .where((b) => b.status == 'requested' || b.status == 'approved')
        .toList()
      ..sort((a, b) => a.dates.start.compareTo(b.dates.start));

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('Deposits & payments')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTokens.primaryTint.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.info, color: AppTokens.primaryDeep, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Haven does not collect payment in the app. Your deposit and balance are agreed and paid directly with the venue. '
                    'Only send money after the host has confirmed your dates and you have their payment details in writing.',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTokens.primaryDeep),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Deposits due',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink)),
          const SizedBox(height: 8),
          if (relevant.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.border),
              ),
              child: const Text(
                'No active bookings. Once a host confirms a request, the agreed deposit appears here.',
                style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppTokens.inkSecondary),
              ),
            )
          else
            ...relevant.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(b.venueName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTokens.ink)),
                          ),
                          StatusBadge(
                            label:
                                b.status == 'approved' ? 'Confirmed' : 'Pending',
                            kind: b.status == 'approved'
                                ? StatusKind.success
                                : StatusKind.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('d MMM yyyy').format(b.dates.start)} · ${b.guests} guests · ${b.slot}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTokens.inkSecondary),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _Amount(
                                label: 'Deposit',
                                value:
                                    'TSh ${b.deposit.toStringAsFixed(0)}'),
                          ),
                          Expanded(
                            child: _Amount(
                                label: 'Total estimate',
                                value:
                                    'TSh ${b.total.toStringAsFixed(0)}',
                                alignEnd: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b.status == 'approved'
                            ? 'Pay the deposit directly to the host to hold your dates.'
                            : 'The host will share payment details after confirming.',
                        style: const TextStyle(
                            fontSize: 12, color: AppTokens.inkTertiary),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 20),
          AppButton(
            label: 'View my bookings',
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                Navigator.of(context).pushNamed('/bookings'),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;
  const _Amount({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppTokens.inkTertiary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTokens.ink)),
      ],
    );
  }
}
