import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/api_config.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';

/// Guest review composer for a completed, host-approved booking.
/// The server re-checks eligibility, so this screen only needs the booking id.
class WriteReviewPage extends StatefulWidget {
  final int venueId;
  final String bookingId;
  final String venueName;

  const WriteReviewPage({
    super.key,
    required this.venueId,
    required this.bookingId,
    required this.venueName,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _comment = TextEditingController();
  final _client = ApiClient();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bookingId = int.tryParse(widget.bookingId);
    if (bookingId == null) {
      AppSnack.error(context, 'This booking cannot be reviewed yet.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _client.postJson(
        ApiConfig.venueReviews(widget.venueId),
        {
          'booking_id': bookingId,
          'rating': _rating,
          'comment': _comment.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) AppSnack.error(context, e.message);
    } catch (_) {
      if (mounted) {
        AppSnack.error(context, 'Could not publish your review. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('Rate your experience')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(widget.venueName,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink)),
          const SizedBox(height: 4),
          const Text(
            'Your review appears publicly as your first name and last initial.',
            style: TextStyle(fontSize: 13, color: AppTokens.inkSecondary),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              children: [
                const Text('How was the venue?',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.ink)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final value = i + 1;
                    return IconButton(
                      tooltip: '$value star${value == 1 ? '' : 's'}',
                      onPressed: () => setState(() => _rating = value),
                      icon: Icon(
                        value <= _rating
                            ? AppIcons.starActive
                            : AppIcons.star,
                        size: 34,
                        color: value <= _rating
                            ? AppTokens.primary
                            : AppTokens.border,
                      ),
                    );
                  }),
                ),
                Text(
                  ['Poor', 'Fair', 'Good', 'Great', 'Excellent'][_rating - 1],
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.inkSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tell guests what stood out',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink)),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 6,
            maxLength: 1200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  'The space, the host, the location, anything a future guest should know…',
              filled: true,
              fillColor: AppTokens.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                borderSide: const BorderSide(color: AppTokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                borderSide: const BorderSide(color: AppTokens.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Publish review',
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
          const SizedBox(height: 8),
          const Text(
            'You can review a venue once, after the event date has passed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTokens.inkTertiary),
          ),
        ],
      ),
    );
  }
}
