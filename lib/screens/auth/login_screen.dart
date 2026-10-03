import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_config.dart';
import '../../providers/auth_provider.dart';
import 'auth_validation.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.login(_identity.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      final user = ref.read(currentUserProvider);
      if (user != null) context.go(roleHome(user));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.loading;
    final error = auth.error;
    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Log in to continue shopping or managing your store.',
      footer: authLinkFooter(
        context,
        "Don't have an account?",
        'Create one',
        () => context.go('/signup'),
      ),
      children: [
        if (error != null) ...[
          AuthBanner.error(error),
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
                icon: Icons.person_outline,
                hint: 'you@example.com or +2507…',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                onSubmitted: (_) => _submit(),
                validator: validateEmailOrPhone,
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Password',
                controller: _password,
                icon: Icons.lock_outline,
                hint: '••••••••',
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 32,
                    child: Checkbox(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? true),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Remember me', style: TextStyle(fontSize: 12.5)),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        loading ? null : () => context.push('/forgot-password'),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              authSubmitButton(
                context,
                label: loading ? 'Logging in…' : 'Log in',
                enabled: !loading,
                onPressed: _submit,
              ),
              if (!kReleaseMode) ...[
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 6),
                Text(
                  'Dev quick login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : () {
                            _identity.text = kAdminEmail;
                            _password.text = kAdminPassword;
                            _submit();
                          },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Fill admin credentials'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
