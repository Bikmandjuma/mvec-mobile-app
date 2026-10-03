import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../widgets/common.dart';
import '../models/vendor_settings.dart';
import '../vendor_dependencies.dart';

enum _SettingsSection { general, delivery, security, team }

/// Store profile, fulfilment defaults, account security and team permissions.
class VendorSettingsScreen extends ConsumerWidget {
  const VendorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(vendorStoreSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'STORE ADMIN',
          title: 'Account settings',
          subtitle:
              'Keep your store details, fulfilment rules and access current.',
        ),
        switch (settingsAsync) {
          AsyncLoading() => const SizedBox(height: 220, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(vendorStoreSettingsProvider),
          ),
          AsyncData(:final value) => _SettingsEditor(settings: value),
          _ => const SizedBox(height: 220, child: LoadingState()),
        },
      ],
    );
  }
}

class _SettingsEditor extends ConsumerStatefulWidget {
  const _SettingsEditor({required this.settings});
  final VendorStoreSettings settings;

  @override
  ConsumerState<_SettingsEditor> createState() => _SettingsEditorState();
}

class _SettingsEditorState extends ConsumerState<_SettingsEditor> {
  late VendorStoreSettings _settings;
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _logo;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _businessPhone;
  late final TextEditingController _tin;
  _SettingsSection _section = _SettingsSection.general;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _name = TextEditingController(text: _settings.storeName);
    _slug = TextEditingController(text: _settings.storeSlug);
    _logo = TextEditingController(text: _settings.logoUrl ?? '');
    _phone = TextEditingController(text: _settings.phone);
    _email = TextEditingController(text: _settings.supportEmail);
    _description = TextEditingController(text: _settings.description);
    _address = TextEditingController(text: _settings.businessAddress);
    _businessPhone = TextEditingController(text: _settings.businessPhone);
    _tin = TextEditingController(text: _settings.taxId);
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _logo.dispose();
    _phone.dispose();
    _email.dispose();
    _description.dispose();
    _address.dispose();
    _businessPhone.dispose();
    _tin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_SettingsSection>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _SettingsSection.general,
                label: Text('General'),
              ),
              ButtonSegment(
                value: _SettingsSection.delivery,
                label: Text('Business & delivery'),
              ),
              ButtonSegment(
                value: _SettingsSection.security,
                label: Text('Security'),
              ),
              ButtonSegment(value: _SettingsSection.team, label: Text('Team')),
            ],
            selected: {_section},
            onSelectionChanged:
                (selected) => setState(() => _section = selected.first),
          ),
        ),
        const SizedBox(height: 14),
        switch (_section) {
          _SettingsSection.general => _general(),
          _SettingsSection.delivery => _delivery(),
          _SettingsSection.security => _security(),
          _SettingsSection.team => _team(),
        },
      ],
    );
  }

  Widget _general() => DataCard(
    title: 'General store details',
    subtitle: 'Shown to buyers on your marketplace storefront.',
    child: Column(
      children: [
        _field(_name, 'Store name'),
        _field(_slug, 'Store URL slug'),
        _field(_logo, 'Logo image URL', keyboard: TextInputType.url),
        _field(_phone, 'Contact phone', keyboard: TextInputType.phone),
        _field(_email, 'Support email', keyboard: TextInputType.emailAddress),
        _field(_description, 'Store description', lines: 3),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Accepting marketplace orders'),
          value: _settings.marketplaceLive,
          onChanged:
              (value) => setState(
                () => _settings = _settings.copyWith(marketplaceLive: value),
              ),
        ),
        _saveButton(
          () => _persist(
            _settings.copyWith(
              storeName: _name.text.trim(),
              storeSlug: _slug.text.trim(),
              logoUrl: _logo.text.trim(),
              phone: _phone.text.trim(),
              supportEmail: _email.text.trim(),
              description: _description.text.trim(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _delivery() => Column(
    children: [
      DataCard(
        title: 'Business & delivery information',
        subtitle: 'Used for fulfilment and checkout estimates.',
        child: Column(
          children: [
            _field(_address, 'Business address', lines: 2),
            _field(
              _businessPhone,
              'Business phone',
              keyboard: TextInputType.phone,
            ),
            _field(_tin, 'Tax identification number'),
            if (_settings.shippingRules.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _settings.defaultShippingRule?.id,
                decoration: const InputDecoration(
                  labelText: 'Default shipping rule',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final rule in _settings.shippingRules)
                    DropdownMenuItem(
                      value: rule.id,
                      child: Text('${rule.name} · ${rule.summary}'),
                    ),
                ],
                onChanged:
                    (id) => setState(
                      () =>
                          _settings = _settings.copyWith(
                            defaultShippingRuleId: id,
                          ),
                    ),
              ),
            _saveButton(
              () => _persist(
                _settings.copyWith(
                  businessAddress: _address.text.trim(),
                  businessPhone: _businessPhone.text.trim(),
                  taxId: _tin.text.trim(),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      DataCard(
        title: 'Operating hours',
        subtitle: _settings.hours.summary,
        child: Column(
          children: [
            for (var i = 0; i < _settings.hours.days.length; i++) _hoursRow(i),
            Align(
              alignment: Alignment.centerRight,
              child: _saveButton(() => _persist(_settings)),
            ),
          ],
        ),
      ),
      if (_settings.shippingRules.isNotEmpty) ...[
        const SizedBox(height: 12),
        DataCard(
          title: 'Delivery options',
          child: Column(
            children: [
              for (final rule in _settings.shippingRules)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(rule.name),
                  subtitle: Text(rule.summary),
                  trailing: Text(
                    '${rule.etaDays} day${rule.etaDays == 1 ? '' : 's'}',
                    style: TextStyle(color: context.mv.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ],
    ],
  );

  Widget _hoursRow(int index) {
    final day = _settings.hours.days[index];
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        day.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        day.display,
        style: TextStyle(fontSize: 11, color: context.mv.textMuted),
      ),
      value: day.open,
      onChanged: (open) {
        final days = [..._settings.hours.days];
        days[index] = day.copyWith(open: open);
        setState(
          () => _settings = _settings.copyWith(hours: OperatingHours(days)),
        );
      },
    );
  }

  Widget _security() => DataCard(
    title: 'Security & password',
    subtitle: 'Manage access to your store account.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Two-factor authentication'),
          subtitle: const Text(
            'Require a second verification step at sign-in.',
          ),
          value: _settings.twoFactorEnabled,
          onChanged: (enabled) async {
            final next = _settings.copyWith(twoFactorEnabled: enabled);
            setState(() => _settings = next);
            await _persist(next);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Last password change'),
          subtitle: Text(shortDate(_settings.lastPasswordChangeAt)),
          trailing: const Icon(Icons.lock_reset),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _changePassword,
          icon: const Icon(Icons.key, size: 17),
          label: const Text('Update password'),
        ),
        const SizedBox(height: 8),
        _saveButton(() => _persist(_settings)),
      ],
    ),
  );

  Widget _team() => DataCard(
    title: 'Staff & team management',
    subtitle: '${_settings.activeStaff.length} active team members',
    trailing: IconButton(
      tooltip: 'Add team member',
      onPressed: _addStaff,
      icon: const Icon(Icons.person_add_alt_1),
    ),
    child: Column(
      children: [
        for (final member in _settings.staff) _staffTile(member),
        if (_settings.staff.isEmpty)
          const EmptyState(message: 'No team members have been invited.'),
      ],
    ),
  );

  Widget _staffTile(VendorStaffMember member) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: context.mv.soft,
      child: Text(
        member.initials,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.mv.accentDeep,
        ),
      ),
    ),
    title: Text(
      member.name,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${member.email} · ${member.role.label}${member.active ? '' : ' · Inactive'}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 10.5, color: context.mv.textMuted),
    ),
    children: [
      for (final permission in VendorPermission.values)
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(permission.label, style: const TextStyle(fontSize: 11)),
          value: member.permissions.contains(permission),
          onChanged:
              member.isOwner
                  ? null
                  : (granted) =>
                      _setPermission(member, permission, granted == true),
        ),
      if (!member.isOwner)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _toggleStaff(member),
            icon: Icon(
              member.active
                  ? Icons.person_off_outlined
                  : Icons.person_add_alt_1,
              size: 16,
            ),
            label: Text(member.active ? 'Revoke access' : 'Restore access'),
          ),
        ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _saveButton(Future<void> Function() onSave) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton.icon(
      onPressed: _busy ? null : onSave,
      icon: const Icon(Icons.save_outlined, size: 17),
      label: Text(_busy ? 'Saving…' : 'Save changes'),
    ),
  );

  Future<void> _persist(VendorStoreSettings next) async {
    setState(() => _busy = true);
    try {
      final saved = await ref.read(vendorSettingsModuleProvider).save(next);
      if (mounted) {
        setState(() => _settings = saved);
        showMvSnack(context, 'Store settings saved', success: true);
      }
    } catch (error) {
      if (mounted) showMvSnack(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final change = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Update password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter your current password'
                                : null,
                  ),
                  TextFormField(
                    controller: next,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                    validator:
                        (value) =>
                            value == null || value.length < 8
                                ? 'Use at least 8 characters'
                                : null,
                  ),
                  TextFormField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    validator:
                        (value) =>
                            value != next.text
                                ? 'Passwords do not match'
                                : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
    if (change == true && mounted) {
      setState(() => _busy = true);
      try {
        await ref
            .read(vendorSettingsModuleProvider)
            .changePassword(
              currentPassword: current.text,
              newPassword: next.text,
            );
        if (mounted) showMvSnack(context, 'Password updated', success: true);
      } catch (error) {
        if (mounted) showMvSnack(context, friendlyError(error));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Future<void> _addStaff() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final confirmPassword = TextEditingController();
    var role = StaffRole.staff;
    var permissions = role.defaults;
    final formKey = GlobalKey<FormState>();
    final invite = await showDialog<(VendorStaffMember, String)>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: const Text('Invite a team member'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator:
                              (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Enter a name'
                                      : null,
                        ),
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Work email',
                          ),
                          validator:
                              (value) =>
                                  value == null || !value.contains('@')
                                      ? 'Enter a valid email'
                                      : null,
                        ),
                        TextFormField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Temporary password',
                            helperText: 'At least 8 characters',
                          ),
                          validator: (value) =>
                              value == null || value.length < 8
                                  ? 'Use at least 8 characters'
                                  : null,
                        ),
                        TextFormField(
                          controller: confirmPassword,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                          ),
                          validator: (value) => value != password.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        DropdownButtonFormField<StaffRole>(
                          initialValue: role,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: [
                            for (final option in StaffRole.assignable)
                              DropdownMenuItem(
                                value: option,
                                child: Text(option.label),
                              ),
                          ],
                          onChanged:
                              (value) => setDialogState(() {
                                role = value ?? role;
                                permissions = role.defaults;
                              }),
                        ),
                        const SizedBox(height: 8),
                        for (final permission in VendorPermission.values)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              permission.label,
                              style: const TextStyle(fontSize: 11),
                            ),
                            value: permissions.contains(permission),
                            onChanged:
                                (enabled) => setDialogState(() {
                                  permissions = {...permissions};
                                  if (enabled == true) {
                                    permissions.add(permission);
                                  } else {
                                    permissions.remove(permission);
                                  }
                                }),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() == true) {
                          final member = VendorStaffMember(
                            id:
                                'staff-${DateTime.now().microsecondsSinceEpoch}',
                            name: name.text.trim(),
                            email: email.text.trim(),
                            role: role,
                            permissions: permissions,
                            invitedAt: DateTime.now(),
                          );
                          Navigator.pop(
                            dialogContext,
                            (member, password.text),
                          );
                        }
                      },
                      child: const Text('Invite'),
                    ),
                  ],
                ),
          ),
    );
    if (invite != null && mounted) {
      setState(() => _busy = true);
      try {
        final updated = await ref.read(vendorSettingsModuleProvider).inviteStaff(
              member: invite.$1,
              password: invite.$2,
            );
        if (mounted) {
          setState(() => _settings = updated);
          showMvSnack(context, 'Team member added', success: true);
        }
      } catch (error) {
        if (mounted) showMvSnack(context, friendlyError(error));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
  }

  Future<void> _toggleStaff(VendorStaffMember member) async {
    try {
      final updated = await ref
          .read(vendorSettingsModuleProvider)
          .setStaffActive(member.id, !member.active);
      if (mounted) setState(() => _settings = updated);
    } catch (error) {
      if (mounted) showMvSnack(context, friendlyError(error));
    }
  }

  Future<void> _setPermission(
    VendorStaffMember member,
    VendorPermission permission,
    bool granted,
  ) async {
    final permissions = {...member.permissions};
    if (granted) {
      permissions.add(permission);
    } else {
      permissions.remove(permission);
    }
    final staff = [
      for (final item in _settings.staff)
        if (item.id == member.id)
          item.copyWith(permissions: permissions)
        else
          item,
    ];
    await _persist(_settings.copyWith(staff: staff));
  }
}
