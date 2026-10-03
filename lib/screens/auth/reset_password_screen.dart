import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_validation.dart';
import 'auth_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Guard: the code must have been verified before reaching this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authControllerProvider).resetToken ?? '';
      if (token.isEmpty && mounted) {
        context.go('/forgot-password');
      }
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.resetPassword(_password.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _done = true);
      showAuthSnack(
        context,
        'Password reset complete. You can now log in with your new password.',
        success: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.loading;
    return AuthShell(
      title: 'Create a new password',
      subtitle:
          'Choose a strong password that you have not used before for this account.',
      compact: true,
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Back',
          onPressed: loading ? null : () => context.go('/verify-code'),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
      ),
      footer: authLinkFooter(
        context,
        'Remember your password?',
        'Back to login',
        loading ? () {} : () => context.go('/login'),
      ),
      children: [
        const ResetStepIndicator(current: 3),
        const SizedBox(height: 22),
        if (auth.error != null) ...[
          AuthBanner.error(auth.error!),
          const SizedBox(height: 14),
        ],
        if (_done) ...[
          const AuthBanner.success(
            'Your password has been updated. Redirecting to login…',
          ),
          const SizedBox(height: 14),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'New password',
                controller: _password,
                icon: Icons.lock_open_outlined,
                hint: 'At least 6 characters',
                obscure: _obscure,
                textInputAction: TextInputAction.next,
                validator: validatePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Confirm new password',
                controller: _confirmPassword,
                icon: Icons.lock_reset_outlined,
                obscure: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) => validateConfirmPassword(v, _password.text),
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 16),
              const InfoBox(
                'Your new password must be at least 6 characters and should use a mix of letters and numbers.',
                icon: 'shield',
              ),
              const SizedBox(height: 18),
              authSubmitButton(
                context,
                label: loading ? 'Resetting…' : 'Reset password',
                enabled: !loading && !_done,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}