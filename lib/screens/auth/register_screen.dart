import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import 'auth_validation.dart';
import 'auth_widgets.dart';

/// Registration form supporting the four MVEC user types:
/// buyer, vendor, supplier and affiliate.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _telephone = TextEditingController();
  final _email = TextEditingController();
  final _companyName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String _role = 'buyer';
  String? _gender;

  static const _roles = <_RoleOption>[
    _RoleOption(
      value: 'buyer',
      icon: Icons.shopping_bag_outlined,
      title: 'Buyer',
      description: 'Browse products, place orders and manage purchases.',
    ),
    _RoleOption(
      value: 'vendor',
      icon: Icons.storefront_outlined,
      title: 'Vendor',
      description: 'Create a store, sell products and reach customers.',
    ),
    _RoleOption(
      value: 'supplier',
      icon: Icons.warehouse_outlined,
      title: 'Supplier',
      description: 'List wholesale products and supply verified MVEC vendors.',
    ),
    _RoleOption(
      value: 'affiliate',
      icon: Icons.campaign_outlined,
      title: 'Affiliate',
      description: 'Promote products and earn commission on qualifying sales.',
    ),
  ];

  @override
  void dispose() {
    _fullName.dispose();
    _telephone.dispose();
    _email.dispose();
    _companyName.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.register(
      fullName: _fullName.text.trim(),
      telephone: _telephone.text.trim(),
      email: _email.text.trim(),
      gender: _gender,
      role: _role,
      companyName: _companyName.text.trim().isEmpty ? null : _companyName.text.trim(),
      password: _password.text,
    );
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
    final needsCompany = _role == 'vendor' || _role == 'supplier';
    return AuthShell(
      title: 'Create your account',
      subtitle:
          'Join MVEC with your phone number, then choose how you want to participate on the marketplace.',
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Back',
          onPressed: loading ? null : () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
      ),
      footer: authLinkFooter(
        context,
        'Already have an account?',
        'Log in',
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
              Text(
                'Choose your account type',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 8),
              _RoleGrid(
                roles: _roles,
                selected: _role,
                onSelected: (v) => setState(() => _role = v),
              ),
              const SizedBox(height: 18),
              AuthField(
                label: 'Full name',
                controller: _fullName,
                icon: Icons.badge_outlined,
                hint: 'Enter your full name',
                textInputAction: TextInputAction.next,
                validator: validateFullName,
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Telephone',
                controller: _telephone,
                icon: Icons.phone_outlined,
                hint: '+250 7xx xxx xxx',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: validatePhone,
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Email (optional)',
                controller: _email,
                icon: Icons.mail_outline,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: validateEmail,
              ),
              if (needsCompany) ...[
                const SizedBox(height: 14),
                AuthField(
                  label: 'Company name',
                  controller: _companyName,
                  icon: Icons.business_outlined,
                  hint: 'Your $_role business / store name',
                  textInputAction: TextInputAction.next,
                ),
              ],
              const SizedBox(height: 14),
              _GenderSelector(
                value: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 18),
              AuthField(
                label: 'Password',
                controller: _password,
                icon: Icons.lock_outline,
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
                label: 'Confirm password',
                controller: _confirmPassword,
                icon: Icons.lock_reset_outlined,
                obscure: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    validateConfirmPassword(v, _password.text),
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
              const SizedBox(height: 20),
              authSubmitButton(
                context,
                label: loading
                    ? 'Creating your account…'
                    : 'Create account',
                enabled: !loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleOption {
  const _RoleOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String value;
  final IconData icon;
  final String title;
  final String description;
}

class _RoleGrid extends StatelessWidget {
  const _RoleGrid({
    required this.roles,
    required this.selected,
    required this.onSelected,
  });

  final List<_RoleOption> roles;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: roles
          .map(
            (role) => _RoleCard(
              role: role,
              active: selected == role.value,
              onTap: () => onSelected(role.value),
            ),
          )
          .toList(),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.active,
    required this.onTap,
  });

  final _RoleOption role;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: active ? theme.colorScheme.primaryContainer : theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? theme.colorScheme.primary : theme.dividerColor,
          width: active ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    role.icon,
                    size: 20,
                    color: active
                        ? theme.colorScheme.primary
                        : theme.hintColor,
                  ),
                  const Spacer(),
                  if (active)
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF168DB8)),
                ],
              ),
              const Spacer(),
              Text(
                role.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                role.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.3,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <(String, String)>[
      ('male', 'Male'),
      ('female', 'Female'),
      ('other', 'Prefer not to say'),
    ];
    final selected = value ?? 'other';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final active = selected == o.$1;
            return ChoiceChip(
              label: Text(o.$2),
              selected: active,
              onSelected: (_) => onChanged(o.$1),
              showCheckmark: false,
              side: BorderSide(
                color: active
                    ? const Color(0xFF168DB8)
                    : Theme.of(context).dividerColor,
              ),
              backgroundColor: active
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? const Color(0xFF168DB8) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}