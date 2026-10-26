import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/booking_provider.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';

/// Real notification feed derived from booking status changes. The backend
/// updates `bookings.updated_at` whenever a host approves or declines, so no
/// invented events or unread counters are needed.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>();
    final items = [...bookings.items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh updates',
            onPressed: () => context.read<BookingProvider>().refresh(),
            icon: const Icon(AppIcons.refresh,
                color: AppTokens.inkSecondary, size: 22),
          ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: AppIcons.notifications,
              title: 'No updates yet',
              subtitle:
                  'Booking status changes from hosts will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = items[i];
                final meta = _metaFor(b);
                return InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/bookings'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTokens.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: AppTokens.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: meta.bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(meta.icon,
                              size: 19, color: meta.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meta.title(b),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTokens.ink)),
                              const SizedBox(height: 2),
                              Text(
                                '${b.venueName} · ${DateFormat('d MMM yyyy').format(b.dates.start)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTokens.inkSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d MMM · HH:mm')
                                    .format(b.updatedAt.toLocal()),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTokens.inkTertiary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(AppIcons.chevron,
                            size: 18, color: AppTokens.inkTertiary),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  _UpdateMeta _metaFor(Booking b) {
    switch (b.status.toLowerCase()) {
      case 'approved':
        return _UpdateMeta(
          title: (b) => '${b.venueName} confirmed your booking',
          icon: AppIcons.checkCircle,
          color: AppTokens.success,
          bg: const Color(0xFFE8F5EF),
        );
      case 'declined':
        return _UpdateMeta(
          title: (b) => '${b.venueName} declined your request',
          icon: AppIcons.cancel,
          color: AppTokens.error,
          bg: const Color(0xFFFDECEC),
        );
      case 'cancelled':
        return _UpdateMeta(
          title: (b) => 'You cancelled your request for ${b.venueName}',
          icon: AppIcons.cancel,
          color: AppTokens.inkSecondary,
          bg: AppTokens.surfaceSecondary,
        );
      default:
        return _UpdateMeta(
          title: (b) => 'Request sent to ${b.venueName}',
          icon: AppIcons.clock,
          color: AppTokens.warning,
          bg: const Color(0xFFFFF4E5),
        );
    }
  }
}

class _UpdateMeta {
  final String Function(Booking) title;
  final IconData icon;
  final Color color;
  final Color bg;
  const _UpdateMeta({
    required this.title,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

