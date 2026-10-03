import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/vendor.dart';
import '../../providers/vendor_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';
import 'vendor_status_banner.dart';

/// Vendor store profile: business information, contact details, social links
/// and the address / delivery block. Persists with `PUT /stores`.
///
/// Seeded from `GET /stores/mine`. Re-seeding is suppressed while the form is
/// dirty, so a verification decision landing mid-edit cannot silently discard
/// what the vendor typed.
class VendorProfileScreen extends ConsumerStatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  ConsumerState<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends ConsumerState<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};

  /// Unsaved-changes flag. A [ValueNotifier] rather than `setState` so typing
  /// repaints only the save bar instead of rebuilding the whole form (which
  /// would fight the focused text field's cursor).
  final _dirty = ValueNotifier<bool>(false);

  /// The record the form was last seeded from; `null` forces a re-seed.
  StoreProfile? _seededFrom;

  static const _fieldKeys = <String>[
    'storeName', 'logo', 'description',
    'email', 'phone',
    'facebook', 'instagram', 'twitter', 'website',
    'street', 'city', 'state', 'country', 'postalCode',
    'deliveryNote', 'deliveryTime', 'deliveryFee',
  ];

  @override
  void initState() {
    super.initState();
    for (final key in _fieldKeys) {
      _controllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _dirty.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(String key) => _controllers[key]!;

  void _markDirty() => _dirty.value = true;

  /// Copies [store] into the form, but only when the record actually changed
  /// and nothing is pending a save.
  void _seed(StoreProfile? store) {
    if (_dirty.value || identical(store, _seededFrom)) return;
    _seededFrom = store;
    _c('storeName').text = store?.name ?? '';
    _c('logo').text = store?.logo ?? '';
    _c('description').text = store?.description ?? '';
    _c('email').text = store?.email ?? '';
    _c('phone').text = store?.phone ?? '';
    _c('facebook').text = store?.facebook ?? '';
    _c('instagram').text = store?.instagram ?? '';
    _c('twitter').text = store?.twitter ?? '';
    _c('website').text = store?.website ?? '';
    _c('street').text = store?.street ?? '';
    _c('city').text = store?.city ?? '';
    _c('state').text = store?.state ?? '';
    _c('country').text = store?.country ?? '';
    _c('postalCode').text = store?.postalCode ?? '';
    _c('deliveryNote').text = store?.deliveryNote ?? '';
    _c('deliveryTime').text = store?.deliveryTime ?? '';
    _c('deliveryFee').text = store?.deliveryFee?.toString() ?? '';
  }

  /// Form values as the `PUT /stores` payload. Blank inputs are dropped so an
  /// untouched field is never written back as an empty string.
  Map<String, dynamic> _body() {
    String? v(String key) {
      final t = _c(key).text.trim();
      return t.isEmpty ? null : t;
    }

    final fee = num.tryParse(_c('deliveryFee').text.trim());
    return {
      if (v('storeName') != null) 'storeName': v('storeName'),
      if (v('logo') != null) 'logo': v('logo'),
      if (v('description') != null) 'description': v('description'),
      if (v('email') != null) 'email': v('email'),
      if (v('phone') != null) 'phone': v('phone'),
      if (v('facebook') != null) 'facebook': v('facebook'),
      if (v('instagram') != null) 'instagram': v('instagram'),
      if (v('twitter') != null) 'twitter': v('twitter'),
      if (v('website') != null) 'website': v('website'),
      if (v('street') != null) 'street': v('street'),
      if (v('city') != null) 'city': v('city'),
      if (v('state') != null) 'state': v('state'),
      if (v('country') != null) 'country': v('country'),
      if (v('postalCode') != null) 'postalCode': v('postalCode'),
      if (v('deliveryNote') != null) 'deliveryNote': v('deliveryNote'),
      if (v('deliveryTime') != null) 'deliveryTime': v('deliveryTime'),
      if (fee != null) 'deliveryFee': fee,
    };
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final body = _body();
    if (body.isEmpty) {
      showMvSnack(context, 'Nothing to save yet');
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await ref.read(vendorStoreControllerProvider.notifier).saveProfile(body);
    if (!mounted) return;
    final state = ref.read(vendorStoreControllerProvider);
    if (ok) {
      _dirty.value = false;
      // Let the refreshed record re-seed the form.
      _seededFrom = null;
      showMvSnack(context, state.success ?? 'Store profile updated', success: true);
    } else {
      showMvSnack(context, state.error ?? 'Could not save your profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fires after the record resolves; seeding here (rather than during build)
    // keeps controller mutation out of the build phase.
    ref.listen<AsyncValue<StoreProfile?>>(myStoreProvider, (_, next) => _seed(next.valueOrNull));

    final storeAsync = ref.watch(myStoreProvider);
    final mutation = ref.watch(vendorStoreControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'VENDOR PORTAL',
          title: 'Store Profile',
          subtitle: 'Keep your business details accurate so buyers and couriers can reach you.',
        ),
        switch (storeAsync) {
          AsyncLoading() => const SizedBox(height: 140, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(myStoreProvider),
            ),
          AsyncData(:final value) => VendorStatusBanner(store: value),
          _ => const SizedBox(height: 140, child: LoadingState()),
        },
        const SizedBox(height: 18),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _businessSection(),
              const SizedBox(height: 16),
              _contactSection(),
              const SizedBox(height: 16),
              _addressSection(),
              const SizedBox(height: 20),
              _saveBar(mutation),
            ],
          ),
        ),
      ],
    );
  }

  Widget _saveBar(VendorMutationState mutation) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GradientButton(
          label: mutation.busy ? 'Saving…' : 'Save changes',
          icon: 'check',
          onPressed: mutation.busy ? null : _save,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _dirty,
          builder: (context, dirty, _) => dirty
              ? const Text(
                  'Unsaved changes',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: MvColors.warningText),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ─── BUSINESS INFORMATION ───────────────────────────────────────────────
  Widget _businessSection() {
    return DataCard(
      title: 'Business information',
      subtitle: 'How your store appears across the marketplace.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LogoField(controller: _c('logo'), nameController: _c('storeName'), onChanged: _markDirty),
          const SizedBox(height: 16),
          _field('storeName', 'Store name *', required: true, maxLength: 80),
          const SizedBox(height: 12),
          _field('description', 'Description', hint: 'Tell buyers what your store sells', maxLines: 4, maxLength: 500),
        ],
      ),
    );
  }

  // ─── CONTACT DETAILS ────────────────────────────────────────────────────
  Widget _contactSection() {
    return DataCard(
      title: 'Contact details',
      subtitle: 'Used for order questions and delivery coordination.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field('email', 'Email', keyboardType: TextInputType.emailAddress)),
              const SizedBox(width: 12),
              Expanded(child: _field('phone', 'Phone', keyboardType: TextInputType.phone)),
            ],
          ),
          const SizedBox(height: 12),
          _field('website', 'Website', hint: 'https://…', keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          const _SubsectionLabel('Social links'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field('facebook', 'Facebook', hint: 'https://facebook.com/…', keyboardType: TextInputType.url)),
              const SizedBox(width: 12),
              Expanded(child: _field('instagram', 'Instagram', hint: 'https://instagram.com/…', keyboardType: TextInputType.url)),
            ],
          ),
          const SizedBox(height: 12),
          _field('twitter', 'X / Twitter', hint: 'https://x.com/…', keyboardType: TextInputType.url),
        ],
      ),
    );
  }

  // ─── ADDRESS & DELIVERY ─────────────────────────────────────────────────
  Widget _addressSection() {
    return DataCard(
      title: 'Address & delivery',
      subtitle: 'Where your store is based and how you fulfil orders.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field('street', 'Street address *', required: true, maxLength: 160),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field('city', 'City *', required: true)),
              const SizedBox(width: 12),
              Expanded(child: _field('state', 'State / Province')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field('country', 'Country')),
              const SizedBox(width: 12),
              Expanded(child: _field('postalCode', 'Postal code', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          const _SubsectionLabel('Delivery'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field('deliveryTime', 'Delivery time', hint: 'e.g. 2–3 days')),
              const SizedBox(width: 12),
              Expanded(child: _field('deliveryFee', 'Delivery fee', hint: '0', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),
          _field('deliveryNote', 'Delivery instructions', hint: 'Where to hand over orders, opening hours…', maxLines: 3, maxLength: 240),
        ],
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    String? hint,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: _c(key),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: (_) => _markDirty(),
      validator: (value) {
        final v = (value ?? '').trim();
        if (required && v.isEmpty) return '$label is required';
        if (key == 'email' && v.isNotEmpty && !_looksLikeEmail(v)) return 'Enter a valid email address';
        if (key == 'deliveryFee' && v.isNotEmpty && num.tryParse(v) == null) return 'Enter a number';
        return null;
      },
    );
  }

  static bool _looksLikeEmail(String v) {
    final at = v.indexOf('@');
    if (at <= 0 || at == v.length - 1) return false;
    final domain = v.substring(at + 1);
    return domain.contains('.') && !domain.endsWith('.') && !domain.startsWith('.');
  }
}

/// Store logo field: a live preview above the URL input.
class _LogoField extends StatelessWidget {
  const _LogoField({required this.controller, required this.nameController, required this.onChanged});
  final TextEditingController controller;
  final TextEditingController nameController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    // Both the URL and the store name feed the preview (as URL or initials),
    // so listen to the two controllers together.
    return ListenableBuilder(
      listenable: Listenable.merge([controller, nameController]),
      builder: (context, _) {
        final url = controller.text.trim();
        return Row(
          children: [
            Container(
              width: 62,
              height: 62,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: url.isEmpty ? MvColors.gradient : null,
                borderRadius: BorderRadius.circular(12),
                border: url.isEmpty ? null : Border.all(color: Theme.of(context).dividerColor),
              ),
              child: url.isEmpty
                  ? Center(child: Text(_initials(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)))
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: MvIcon('shop', size: 20, color: MvColors.muted)),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.url,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Logo URL', hintText: 'https://…'),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        );
      },
    );
  }

  String _initials() {
    final name = nameController.text.trim();
    return name.isEmpty ? 'MV' : initials(name);
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .6,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}
