import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../widgets/common.dart';
import '../../../widgets/mv_icon.dart';
import '../models/vendor_finance.dart';
import '../models/vendor_order.dart';

/// Scannable order summary row, shared by the list and overview shortcuts.
class VendorOrderCard extends StatelessWidget {
  const VendorOrderCard({super.key, required this.order, required this.onTap});

  final VendorOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.mv;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.number,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusChip(order.status.label),
                  const SizedBox(width: 8),
                  MvIcon('arrow', size: 15, color: palette.textMuted),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.buyerName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${plural(order.itemCount, 'item')} · ${shortDateTime(order.placedAt)}',
                style: TextStyle(fontSize: 11, color: palette.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.items.map((item) => item.name).take(2).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    money(order.grandTotal),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (order.disputeOpen) ...[
                const SizedBox(height: 10),
                const InfoBox(
                  'Status changes are paused while MVEC reviews the open dispute.',
                  icon: 'bell',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One signed, dated movement on the vendor's reconciliable money ledger.
class VendorLedgerTile extends StatelessWidget {
  const VendorLedgerTile({super.key, required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.mv;
    final credit = entry.isCredit;
    final tone = credit ? MvColors.successText : MvColors.errorText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: MvIcon(entry.kind.icon, size: 17, color: tone),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.orderNumber == null ? entry.kind.label : '${entry.kind.label} · ${entry.orderNumber}'} · ${shortDateTime(entry.at)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${credit ? '+' : '−'}${money(entry.amount)}',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small finance metric with a consistent icon and headline amount.
class VendorFinanceMetric extends StatelessWidget {
  const VendorFinanceMetric({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    this.emphasis = false,
  });

  final String label;
  final num amount;
  final String icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final palette = context.mv;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.soft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: MvIcon(icon, size: 18, color: palette.accentDeep),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: emphasis ? palette.accentDeep : palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
