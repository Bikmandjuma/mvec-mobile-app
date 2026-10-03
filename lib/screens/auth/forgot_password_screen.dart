import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_validation.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identity = TextEditingController();

  @override
  void dispose() {
    _identity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.forgotPassword(_identity.text.trim());
    if (!mounted) return;
    if (ok) {
      context.pushReplacement('/verify-code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return AuthShell(
      title: 'Forgot your password?',
      subtitle:
          'Enter the email or telephone linked to your MVEC account and we will send you a verification code.',
      compact: true,
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Back',
          onPressed: auth.loading ? null : () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
      ),
      footer: authLinkFooter(
        context,
        'Remember your password?',
        'Back to login',
        () => context.go('/login'),
      ),
      children: [
        if (auth.error != null) ...[
          AuthBanner.error(auth.error!),
          const SizedBox(height: 14),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Email or telephone',
                controller: _identity,
                icon: Icons.mail_outline,
                hint: 'you@example.com or +2507…',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: validateEmailOrPhone,
              ),
              const SizedBox(height: 14),
              const InfoBox(
                'MVEC emails or texts a one-time verification code to make sure you own the account before allowing a password change.',
                icon: 'shield',
              ),
              const SizedBox(height: 18),
              authSubmitButton(
                context,
                label: auth.loading ? 'Sending code…' : 'Send code',
                enabled: !auth.loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}