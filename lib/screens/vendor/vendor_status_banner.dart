import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/vendor.dart';
import '../../providers/vendor_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

/// Verification + account status header for the vendor dashboard.
///
/// Shows two independent states side by side, because they move separately:
///  * **verification** — `UNVERIFIED` / `PENDING` / `VERIFIED` / `REJECTED`,
///    driven by the platform reviewing the vendor's documents;
///  * **account status** — `ACTIVE` / `UNDER_REVIEW` / `SUSPENDED` / `BLOCKED`,
///    the platform's operational hold on the store.
///
/// While the store still owes the platform something, an inline alert names the
/// missing requirements and opens the document upload sheet.
class VendorStatusBanner extends ConsumerWidget {
  const VendorStatusBanner({super.key, required this.store, this.onEditProfile});

  /// `null` means the vendor has no store record yet.
  final StoreProfile? store;

  /// Tapping the store name row (the edit affordance) is delegated to the host
  /// screen so the banner stays free of navigation concerns.
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = store;
    if (s == null) {
      return DataCard(
        title: 'Your store is not set up yet',
        subtitle: 'Add your business details to start selling on MVEC.',
        trailing: const MvIcon('shop', size: 20, color: MvColors.primaryDeep),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoBox('Complete your store profile and upload your verification documents. The platform reviews every store before it can list products.'),
            const SizedBox(height: 14),
            if (onEditProfile != null)
              GradientButton(label: 'Set up my store', icon: 'edit', onPressed: onEditProfile),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _Logo(url: s.logo, name: s.display),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        VerificationBadge(status: s.verification),
                        StatusChip(s.accountStatus),
                        if (s.rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MvIcon('heart', size: 12, color: MvColors.warningText),
                              const SizedBox(width: 3),
                              Text(
                                s.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEditProfile != null)
                IconButton(
                  onPressed: onEditProfile,
                  tooltip: 'Edit store profile',
                  icon: const MvIcon('edit', size: 18, color: MvColors.primaryDeep),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _VerificationAlert(store: s),
      ],
    );
  }
}

/// Distinct badge for the verification pipeline, kept separate from
/// [StatusChip] so "PENDING" reads as "awaiting document review" rather than as
/// a generic operational state.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final (fg, bg, label) = switch (s) {
      VendorVerification.verified => (MvColors.successText, MvColors.successBg, 'Verified'),
      VendorVerification.pending => (MvColors.warningText, MvColors.warningBg, 'Pending review'),
      VendorVerification.rejected => (MvColors.errorText, MvColors.errorBg, 'Rejected'),
      _ => (MvColors.neutralText, MvColors.neutralBg, 'Unverified'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MvIcon(s == VendorVerification.verified ? 'check' : 'shield', size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg, letterSpacing: .3),
          ),
        ],
      ),
    );
  }
}

/// Inline alert shown under the banner whenever the vendor is not yet cleared
/// to trade. Names exactly what is outstanding.
class _VerificationAlert extends ConsumerWidget {
  const _VerificationAlert({required this.store});
  final StoreProfile store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejected = store.verification == VendorVerification.rejected;
    final pending = store.verification == VendorVerification.pending;
    final missing = store.missingDocuments;

    // Verified and in good standing — no alert.
    if (!rejected && !pending && missing.isEmpty) return const SizedBox.shrink();

    final (tone, title, body) = switch (store.verification) {
      VendorVerification.rejected => (
        _Tone.danger,
        'Verification rejected',
        store.rejectionReason?.trim().isNotEmpty == true
            ? store.rejectionReason!
            : 'The platform could not accept your documents. Fix the details below and upload them again.',
      ),
      VendorVerification.pending => (
        _Tone.warning,
        'Documents under review',
        'We are checking your documents. This usually takes one business day — you can keep editing your store in the meantime.',
      ),
      _ => (
        _Tone.info,
        'Verification required',
        'Upload your business documents to start selling. Your store stays hidden from buyers until the platform approves it.',
      ),
    };

    final (fg, bg, border, icon) = switch (tone) {
      _Tone.danger => (MvColors.errorText, MvColors.errorBg, MvColors.errorText, 'bell'),
      _Tone.warning => (MvColors.warningText, MvColors.warningBg, MvColors.warningText, 'shield'),
      _Tone.info => (MvColors.infoBoxText, MvColors.infoBoxBg, MvColors.infoBoxBorder, 'shield'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MvIcon(icon, size: 18, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(body, style: TextStyle(fontSize: 12.5, color: fg, height: 1.45)),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in missing) _RequirementChip(label: titleCase(d)),
              ],
            ),
          ],
          if (store.documents?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              'Uploaded: ${(store.documents ?? []).map((d) => d.display).join(', ')}',
              style: TextStyle(fontSize: 11.5, color: fg.withValues(alpha: .8), fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openUploadSheet(context, ref, store),
                  icon: const MvIcon('plus', size: 14),
                  label: Text(rejected ? 'Resubmit documents' : 'Upload documents'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fg,
                    side: BorderSide(color: border.withValues(alpha: .5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Document upload sheet: one row per required type, each a type + file URL.
  Future<void> _openUploadSheet(BuildContext context, WidgetRef ref, StoreProfile store) {
    final controllers = <String, TextEditingController>{
      for (final type in StoreProfile.requiredDocumentTypes) type: TextEditingController(text: _existingUrl(store, type)),
    };
    return showMvDetailModal(
      context,
      title: 'VERIFICATION DOCUMENTS',
      children: [
        const InfoBox('Paste a public link to each document (PDF or image). Every required document must have a link before you submit.'),
        const SizedBox(height: 14),
        for (final entry in controllers.entries) ...[
          _DocumentField(
            label: titleCase(entry.key),
            controller: entry.value,
            required: StoreProfile.requiredDocumentTypes.contains(entry.key),
          ),
          const SizedBox(height: 12),
        ],
      ],
      footer: Consumer(
        builder: (ctx, sheetRef, _) {
          final mutation = sheetRef.watch(vendorStoreControllerProvider);
          return Row(
            children: [
              Expanded(
                child: OutlineMvButton(
                  label: 'Cancel',
                  onPressed: mutation.busy ? null : () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: mutation.busy ? 'Uploading…' : 'Submit for review',
                  icon: 'check',
                  expanded: true,
                  onPressed: mutation.busy ? null : () => _submit(ctx, ref, controllers),
                ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      for (final c in controllers.values) {
        c.dispose();
      }
    });
  }

  String? _existingUrl(StoreProfile store, String type) {
    final match = (store.documents ?? const <VerificationDocument>[]).where(
      (d) => (d.type ?? '').toUpperCase().replaceAll('-', '_') == type,
    );
    return match.isEmpty ? null : match.first.url;
  }

  Future<void> _submit(
    BuildContext sheetContext,
    WidgetRef ref,
    Map<String, TextEditingController> controllers,
  ) async {
    final docs = <Map<String, String>>[];
    for (final entry in controllers.entries) {
      final url = entry.value.text.trim();
      if (url.isEmpty) {
        showMvSnack(sheetContext, 'Add a link for ${titleCase(entry.key)}');
        return;
      }
      docs.add({'type': entry.key, 'url': url});
    }
    final ok = await ref.read(vendorStoreControllerProvider.notifier).submitDocuments(docs);
    if (!sheetContext.mounted) return;
    final state = ref.read(vendorStoreControllerProvider);
    if (ok) {
      Navigator.pop(sheetContext);
      showMvSnack(sheetContext, state.success ?? 'Documents submitted', success: true);
    } else {
      showMvSnack(sheetContext, state.error ?? 'Could not submit the documents');
    }
  }
}

enum _Tone { info, warning, danger }

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MvIcon('bell', size: 10, color: MvColors.warningText),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: MvColors.ink)),
        ],
      ),
    );
  }
}

class _DocumentField extends StatelessWidget {
  const _DocumentField({required this.label, required this.controller, this.required = false});
  final String label;
  final TextEditingController controller;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'https://…',
        helperText: required ? 'Required' : 'Optional',
      ),
    );
  }
}

/// Store logo, falling back to the store's initials on the brand gradient.
class _Logo extends StatelessWidget {
  const _Logo({required this.url, required this.name});
  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.trim().isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: hasImage ? null : MvColors.gradient,
        borderRadius: BorderRadius.circular(12),
        border: hasImage ? Border.all(color: Theme.of(context).dividerColor) : null,
      ),
      child: hasImage
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() => Center(
        child: Text(
          initials(name),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      );
}
