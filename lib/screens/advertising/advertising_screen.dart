import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

String _shortId(String? id) {
  if (id == null || id.isEmpty) return '—';
  return id.length <= 8 ? id.toUpperCase() : '${id.substring(0, 8).toUpperCase()}…';
}

class AdvertisingScreen extends ConsumerStatefulWidget {
  const AdvertisingScreen({super.key});

  @override
  ConsumerState<AdvertisingScreen> createState() => _AdvertisingScreenState();
}

class _AdvertisingScreenState extends ConsumerState<AdvertisingScreen> {
  final _busy = <String>{};

  Future<void> _toggle(AdvertisementRecord ad) async {
    final id = ad.id ?? '';
    if (id.isEmpty || _busy.contains(id)) return;
    final active = (ad.status ?? '').toUpperCase() == 'ACTIVE';
    final target = active ? 'PAUSED' : 'ACTIVE';
    setState(() => _busy.add(id));
    try {
      await ref.read(financeServiceProvider).patchAdvertisement(id, target);
      if (!mounted) return;
      ref.invalidate(advertisementsProvider);
      showMvSnack(context, 'Ad ${_shortId(id)} ${target == 'ACTIVE' ? 'activated' : 'paused'}', success: true);
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Widget _statusToggle(AdvertisementRecord ad) {
    final id = ad.id ?? '';
    final active = (ad.status ?? '').toUpperCase() == 'ACTIVE';
    final busy = _busy.contains(id);
    final fg = active ? MvColors.successText : MvColors.errorText;
    return InkWell(
      onTap: busy ? null : () => _toggle(ad),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? MvColors.successBg : MvColors.errorBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fg.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: busy
                  ? CircularProgressIndicator(strokeWidth: 1.5, color: fg)
                  : Icon(active ? Icons.pause : Icons.play_arrow, size: 13, color: fg),
            ),
            const SizedBox(width: 5),
            Text(active ? 'Pause' : 'Activate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(advertisementsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN · MARKETING',
          title: 'Advertising',
          subtitle: 'Manage sponsored placements across the marketplace.',
        ),
        adsAsync.when(
          data: (ads) => SmartTable(
            columns: const [
              MvColumn('Ad', 'Ad', bold: true),
              MvColumn('Vendor', 'Vendor'),
              MvColumn('Product', 'Product'),
              MvColumn('Placement', 'Placement'),
              MvColumn('Budget', 'Budget'),
              MvColumn('CTR', 'CTR'),
              MvColumn('Status', 'Status'),
            ],
            rows: [
              for (final ad in ads)
                {
                  'Ad': _shortId(ad.id),
                  'Vendor': ad.vendor ?? '—',
                  'Product': ad.product ?? '—',
                  'Placement': ad.placement ?? '—',
                  'Budget': money(ad.budget),
                  'CTR': '${(ad.ctr ?? 0).toStringAsFixed(2)}%',
                  'Status': StatusChip(ad.status),
                  '_ad': ad,
                },
            ],
            actionsLabel: 'Status',
            pageSize: 8,
            rowActions: (row) => _statusToggle(row['_ad'] as AdvertisementRecord),
          ),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(advertisementsProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }
}