import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class CommissionRulesScreen extends ConsumerStatefulWidget {
  const CommissionRulesScreen({super.key});

  @override
  ConsumerState<CommissionRulesScreen> createState() => _CommissionRulesScreenState();
}

class _CommissionRulesScreenState extends ConsumerState<CommissionRulesScreen> {
  final Map<String, bool> _overrides = {};

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(commissionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Commission Rules',
          subtitle: 'Configure platform commission rules.',
          actions: [
            OutlineMvButton(label: 'Add rule', icon: 'plus', onPressed: () => _showAddRuleModal(context, ref)),
            GradientButton(label: 'Save rules', icon: 'check', onPressed: () {
              showMvSnack(context, 'Commission rules saved.', success: true);
            }),
          ],
        ),
        rulesAsync.when(
          data: (rules) => SmartTable(
            columns: const [
              MvColumn('Rule', 'Rule', bold: true),
              MvColumn('Scope', 'Scope'),
              MvColumn('Target', 'Target'),
              MvColumn('Rate', 'Rate'),
            ],
            rows: [
              for (final r in rules)
                {
                  'Rule': r.name ?? '—',
                  'Scope': r.ruleType ?? '—',
                  'Target': r.target ?? '—',
                  'Rate': r.rateLabel,
                  '_rule': r,
                },
            ],
            actionsLabel: 'Status',
            pageSize: 8,
            rowActions: (row) => _toggleChip(row['_rule'] as CommissionRule),
          ),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(commissionsProvider)),
          loading: () => const LoadingState(),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DataCard(
                title: 'Customer-facing price',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1,250,000 RWF',
                      style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: MvColors.ink, letterSpacing: -.4),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Recommended retail price across all product categories.',
                      style: TextStyle(fontSize: 12.5, color: MvColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DataCard(
                title: 'Internal settlement',
                child: Column(
                  children: [
                    _settlementRow('Vendor share', '95%'),
                    _settlementRow('Platform', '5%'),
                    _settlementRow('Developer', '1%'),
                    _settlementRow('Affiliate', '0.5%'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _toggleChip(CommissionRule rule) {
    final id = rule.id;
    final active = id != null && _overrides.containsKey(id) ? _overrides[id]! : (rule.active ?? true);
    return GestureDetector(
      onTap: id == null
          ? null
          : () => setState(() {
                _overrides[id] = !active;
              }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? MvColors.successBg : MvColors.neutralBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? MvColors.successText.withValues(alpha: .35) : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: active ? MvColors.successText : MvColors.neutralText, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              active ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
                color: active ? MvColors.successText : MvColors.neutralText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settlementRow(String label, String pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Text(pct, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Future<void> _showAddRuleModal(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (_) => const _NewRuleSheet(),
    );
  }
}

class _NewRuleSheet extends ConsumerStatefulWidget {
  const _NewRuleSheet();

  @override
  ConsumerState<_NewRuleSheet> createState() => _NewRuleSheetState();
}

class _NewRuleSheetState extends ConsumerState<_NewRuleSheet> {
  static const _ruleTypes = ['GLOBAL', 'CATEGORY', 'VENDOR', 'PRODUCT'];
  static const _rateTypes = ['PERCENTAGE', 'FIXED'];

  final TextEditingController _name = TextEditingController();
  final TextEditingController _rateValue = TextEditingController();
  String _ruleType = 'GLOBAL';
  String _rateType = 'PERCENTAGE';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _rateValue.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _rateValue.text.trim().isEmpty) {
      showMvSnack(context, 'Enter a rule name and rate');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(financeServiceProvider).createCommission({
        'name': _name.text.trim(),
        'ruleType': _ruleType,
        'rateType': _rateType,
        'rateValue': num.tryParse(_rateValue.text.trim()),
      });
      if (mounted) {
        Navigator.pop(context);
        showMvSnack(context, 'Commission rule added', success: true);
      }
      ref.invalidate(commissionsProvider);
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _dropdown(String value, List<String> options, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).canvasColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(titleCase(o)))],
          onChanged: _busy ? null : (v) => onChanged(v ?? value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add commission rule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _rateValue, decoration: const InputDecoration(labelText: 'Rate value')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _dropdown(_ruleType, _ruleTypes, (v) => setState(() => _ruleType = v))),
                const SizedBox(width: 12),
                Expanded(child: _dropdown(_rateType, _rateTypes, (v) => setState(() => _rateType = v))),
              ],
            ),
            const SizedBox(height: 18),
            GradientButton(label: 'Save rule', icon: 'check', expanded: true, onPressed: _busy ? null : _save),
          ],
        ),
      ),
    );
  }
}