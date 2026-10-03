import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../features/supplier/data/supplier_workspace.dart';
import '../../widgets/common.dart';

/// Supplier self-service profile.
///
/// Only the fields the backend actually persists are shown:
/// `businessName`, `description`, `phone`, `email` and `logoUrl` — see
/// [SupplierProfile.toJson] and `PATCH /api/suppliers/me/profile`. Tax IDs,
/// registration numbers and a structured address would silently be dropped, so
/// they are not presented.
class SupplierProfileScreen extends ConsumerWidget {
  const SupplierProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(supplierWorkspaceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPPLIER PORTAL',
          title: 'Business profile',
          subtitle: 'Keep the details buyers and the MVEC team rely on up to date.',
        ),
        switch (workspace) {
          AsyncLoading() => const LoadingState(),
          AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(supplierWorkspaceProvider),
            ),
          // An empty profile means the account exists but has not been onboarded.
          AsyncData(:final value) =>
              value.profile.isOnboarded
                  ? _ProfileBody(profile: value.profile)
                  : const _OnboardingPrompt(),
          _ => const LoadingState(),
        },
      ],
    );
  }
}

class _OnboardingPrompt extends ConsumerWidget {
  const _OnboardingPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataCard(
          title: 'Finish setting up your business',
          subtitle: 'Your supplier account is ready but has no business profile yet.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add your business name, contact details and a short description. '
                'The MVEC team reviews new suppliers before their catalogue goes live.',
                style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor, height: 1.45),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Set up business profile',
                icon: 'edit',
                expanded: true,
                onPressed: () => _openForm(context, ref, null),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _openForm(BuildContext context, WidgetRef ref, SupplierProfile? initial) {
  showMvDetailModal(
    context,
    title: initial == null ? 'NEW SUPPLIER PROFILE' : 'EDIT PROFILE',
    children: [_SupplierProfileForm(initial: initial)],
    footer: const SizedBox.shrink(),
  );
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final SupplierProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VerificationPanel(profile: s),
        const SizedBox(height: 16),
        DataCard(
          title: 'Business information',
          subtitle: 'Shown to buyers once your account is verified',
          trailing: OutlineMvButton(
            label: 'Edit',
            icon: 'edit',
            onPressed: () => _openForm(context, ref, s),
          ),
          child: KeyValueGrid(
            entries: [
              MapEntry('Business name', s.businessName.isEmpty ? '—' : s.businessName),
              MapEntry('Description', _ellipsis(s.description)),
              if (s.publicId != null) MapEntry('Supplier ID', s.publicId!),
              if (s.slug != null) MapEntry('Store slug', s.slug!),
              MapEntry('Account status', titleCase(s.effectiveStatus)),
              if (s.ratingAvg != null) MapEntry('Rating', '${s.ratingAvg!.toStringAsFixed(1)} / 5'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DataCard(
          title: 'Contact details',
          subtitle: 'How the MVEC team reaches you',
          child: KeyValueGrid(
            entries: [
              MapEntry('Email', s.email.isEmpty ? '—' : s.email),
              MapEntry('Phone', s.phone.isEmpty ? '—' : s.phone),
              MapEntry('Logo URL', _ellipsis(s.logoUrl)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: 'Edit profile',
          icon: 'edit',
          expanded: true,
          onPressed: () => _openForm(context, ref, s),
        ),
      ],
    );
  }

  static String _ellipsis(String? v) {
    if (v == null || v.isEmpty) return '—';
    return v.length <= 48 ? v : '${v.substring(0, 45)}…';
  }
}

/// Read-only verification panel.
///
/// There is no supplier-facing verification endpoint: an admin sets
/// `verificationStatus` through the admin suppliers screen, so the portal
/// reports the state and explains what to do next rather than pretending to
/// submit anything.
class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({required this.profile});

  final SupplierProfile profile;

  @override
  Widget build(BuildContext context) {
    final (headline, note) = switch (profile.verificationStatusOrDefault) {
      'VERIFIED' => (
          'Verified',
          'Your business was approved. The products in your catalogue are visible to buyers.'
        ),
      'PENDING' => (
          'Under review',
          'The MVEC team is reviewing your business. This usually takes 1–2 business days.'
        ),
      'REJECTED' => (
          'Rejected',
          'Your business was not approved. Update your details below and contact support to ask for a review.'
        ),
      _ => (
          'Not verified',
          'New suppliers are reviewed by the MVEC team before their catalogue goes live. '
              'Make sure the business and contact details below are correct.'
        ),
    };

    return DataCard(
      title: 'Verification status',
      subtitle: 'Determines whether buyers can order from you',
      trailing: StatusChip(profile.effectiveStatus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(note, style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor, height: 1.45)),
        ],
      ),
    );
  }
}

/// Create/edit form for the fields the backend accepts.
class _SupplierProfileForm extends ConsumerStatefulWidget {
  const _SupplierProfileForm({required this.initial});

  /// Null when creating the profile for the first time.
  final SupplierProfile? initial;

  @override
  ConsumerState<_SupplierProfileForm> createState() => _SupplierProfileFormState();
}

class _SupplierProfileFormState extends ConsumerState<_SupplierProfileForm> {
  late final Map<String, TextEditingController> _f = {
    'businessName': TextEditingController(text: widget.initial?.businessName ?? ''),
    'description': TextEditingController(text: widget.initial?.description ?? ''),
    'email': TextEditingController(text: widget.initial?.email ?? ''),
    'phone': TextEditingController(text: widget.initial?.phone ?? ''),
    'logoUrl': TextEditingController(text: widget.initial?.logoUrl ?? ''),
  };

  bool _busy = false;

  @override
  void dispose() {
    for (final c in _f.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    if (_f['businessName']!.text.trim().isEmpty) return 'Enter a business name';
    final email = _f['email']!.text.trim();
    if (email.isEmpty) return 'Enter a contact email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid contact email';
    }
    if (_f['phone']!.text.trim().isEmpty) return 'Enter a contact phone';
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      showMvSnack(context, problem);
      return;
    }
    setState(() => _busy = true);
    final previous = widget.initial;
    final isNew = previous == null;
    try {
      await ref
          .read(supplierWorkspaceProvider.notifier)
          .saveProfile(
            SupplierProfile(
              // Carrying the id (and the fields this form does not edit)
              // forward is what tells the workspace service to PATCH the
              // existing supplier instead of re-onboarding them.
              id: previous?.id ?? '',
              publicId: previous?.publicId,
              slug: previous?.slug,
              verificationStatus: previous?.verificationStatus ?? 'UNVERIFIED',
              accountStatus: previous?.accountStatus ?? 'ACTIVE',
              ratingAvg: previous?.ratingAvg,
              address: previous?.address ?? '',
              orderNotifications: previous?.orderNotifications ?? true,
              stockNotifications: previous?.stockNotifications ?? true,
              businessName: _f['businessName']!.text.trim(),
              description: _f['description']!.text.trim(),
              email: _f['email']!.text.trim(),
              phone: _f['phone']!.text.trim(),
              logoUrl: _f['logoUrl']!.text.trim(),
            ),
          );
      if (mounted) {
        Navigator.pop(context);
        showMvSnack(context, isNew ? 'Business profile created' : 'Profile updated', success: true);
      }
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.initial == null) ...[
          Text(
            'These details identify your business to buyers and to the MVEC review team.',
            style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor, height: 1.45),
          ),
          const SizedBox(height: 18),
        ],
        _Field(_f['businessName']!, 'Business name', required: true),
        _Field(_f['description']!, 'Description', lines: 3),
        _Field(_f['email']!, 'Contact email', required: true),
        _Field(_f['phone']!, 'Contact phone', required: true),
        _Field(_f['logoUrl']!, 'Logo URL'),
        const SizedBox(height: 8),
        GradientButton(
          label: widget.initial == null ? 'Create profile' : 'Save changes',
          icon: 'check',
          expanded: true,
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.controller, this.label, {this.lines = 1, this.required = false});

  final TextEditingController controller;
  final String label;
  final int lines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: lines,
        keyboardType: label.contains('email') ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(labelText: required ? '$label *' : label),
      ),
    );
  }
}
