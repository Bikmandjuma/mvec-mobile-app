import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import 'auth_validation.dart';
import 'auth_widgets.dart';

class VerificationCodeScreen extends ConsumerStatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  ConsumerState<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends ConsumerState<VerificationCodeScreen> {
  final _otpKey = GlobalKey<OtpFieldState>();
  String _code = '';
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    // Entering this screen directly makes no sense without a pending reset.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(authControllerProvider).hasPendingReset && mounted) {
        context.go('/forgot-password');
      }
    });
  }

  Future<void> _verify() async {
    final message = validateOtp(_code);
    if (message != null) {
      showAuthSnack(context, message);
      return;
    }
    FocusScope.of(context).unfocus();
    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.verifyResetOtp(_code);
    if (!mounted) return;
    if (ok) {
      context.pushReplacement('/reset-password');
    } else {
      // Wrong or expired code: stay here and let the user retry.
      _otpKey.currentState?.clear();
      setState(() => _code = '');
    }
  }

  Future<void> _resend() async {
    final email = ref.read(authControllerProvider).resetEmail;
    if (email == null || _resending) return;
    setState(() => _resending = true);
    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.forgotPassword(email);
    if (!mounted) return;
    setState(() => _resending = false);
    _otpKey.currentState?.clear();
    if (ok) {
      showAuthSnack(
        context,
        'A new verification code has been sent to $email.',
        success: true,
      );
    }
  }

  void _changeEmail() {
    ref.read(authControllerProvider.notifier).clearResetFlow();
    context.go('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.loading;
    final error = auth.error;
    final target = auth.resetEmail ?? 'your account';
    return AuthShell(
      title: 'Verify your identity',
      subtitle: 'Enter the 6-digit code sent to $target.',
      compact: true,
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Back',
          onPressed: loading ? null : () => context.go('/forgot-password'),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
      ),
      footer: authLinkFooter(
        context,
        'Entered the wrong address?',
        'Change email address',
        loading ? () {} : _changeEmail,
      ),
      children: [
        const ResetStepIndicator(current: 2),
        const SizedBox(height: 22),
        if (error != null) ...[
          AuthBanner.error(error),
          const SizedBox(height: 14),
        ],
        if (auth.devCode != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MvColors.infoBoxBg,
              border: Border.all(color: MvColors.infoBoxBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, size: 16, color: MvColors.infoBoxText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 12, color: MvColors.infoBoxText),
                      children: [
                        const TextSpan(text: 'Development code: '),
                        TextSpan(
                          text: auth.devCode!,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        OtpField(
          key: _otpKey,
          enabled: !loading,
          onChanged: (code) => setState(() => _code = code),
        ),
        const SizedBox(height: 18),
        authSubmitButton(
          context,
          label: loading ? 'Verifying…' : 'Verify code',
          enabled: !loading,
          onPressed: _verify,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: (_resending || loading) ? null : _resend,
          child: Text(
            _resending
                ? 'Sending again…'
                : "Didn't receive the code? Send again",
            style: const TextStyle(fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}