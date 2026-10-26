import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';

/// Edit the account fields the backend owns: name, phone and email.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _client = ApiClient();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final parts = auth.displayName.split(RegExp(r'\s+'));
    _first = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _last = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _phone = TextEditingController(text: auth.profilePhone);
    _email = TextEditingController(text: auth.profileEmail);
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final data = await _client.patchJson(
        ApiConfig.me(),
        {
          'first_name': _first.text.trim(),
          'last_name': _last.text.trim(),
          'contacts': _phone.text.trim(),
          'email': _email.text.trim(),
        },
      );
      final user = data is Map ? (data['data'] ?? data) : null;
      if (user is Map && mounted) {
        await context
            .read<AuthProvider>()
            .applyProfilePatch(Map<String, dynamic>.from(user));
      }
      if (!mounted) return;
      AppSnack.success(context, 'Profile updated');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) AppSnack.error(context, e.message);
    } catch (_) {
      if (mounted) {
        AppSnack.error(context, 'Could not save your profile. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v, {int min = 2, String label = 'This field'}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return '$label is required';
    if (value.length < min) return '$label is too short';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'These details are used on booking requests so the host can reach you. Your email is never shown publicly.',
              style: TextStyle(
                  fontSize: 13, height: 1.4, color: AppTokens.inkSecondary),
            ),
            const SizedBox(height: 20),
            _field(
              controller: _first,
              label: 'First name',
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, label: 'First name'),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _last,
              label: 'Last name',
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, label: 'Last name'),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _phone,
              label: 'Phone',
              keyboardType: TextInputType.phone,
              hint: '+255…',
              validator: (v) {
                final digits =
                    (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 7) return 'Enter a reachable phone number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _field(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = (v ?? '').trim();
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Save changes',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
    );
  }
}
