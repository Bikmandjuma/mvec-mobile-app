import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(supportCasesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'MVEC Support',
          subtitle: 'Support cases from users.',
        ),
        switch (support) {
          AsyncData(:final value) => _table(context, value),
          AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(supportCasesProvider),
            ),
          _ => const LoadingState(),
        },
        const SizedBox(height: 18),
        const _NewSupportCard(),
      ],
    );
  }

  Widget _table(BuildContext context, List<SupportCase> list) {
    final rows = list
        .map((c) => {
              'id': c.id ?? '-',
              'subject': c.subject ?? '—',
              'requester': c.requester ?? '-',
              'order': c.order ?? '-',
              'status': (c.status ?? 'OPEN').toUpperCase(),
            })
        .toList();
    return SmartTable(
      columns: const [
        MvColumn('id', 'Case'),
        MvColumn('subject', 'Subject', flex: 2),
        MvColumn('requester', 'Requester', flex: 2),
        MvColumn('order', 'Order'),
      ],
      rows: rows,
      pageSize: 8,
      filterKey: 'status',
      filterLabel: 'Status',
      filterOptions: const ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'],
      actionsLabel: 'Status · Actions',
      rowActions: (row) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusChip(row['status']?.toString()),
          const SizedBox(width: 6),
          TableActionBtn(icon: 'eye', tooltip: 'View case', onPressed: () => _view(context, row)),
        ],
      ),
    );
  }

  void _view(BuildContext context, Map<String, dynamic> row) {
    showMvDetailModal(
      context,
      title: 'Support case',
      children: [
        KeyValueGrid(entries: [
          MapEntry('Case', row['id']?.toString() ?? '-'),
          MapEntry('Subject', row['subject']?.toString() ?? '-'),
          MapEntry('Requester', row['requester']?.toString() ?? '-'),
          MapEntry('Order', row['order']?.toString() ?? '-'),
          MapEntry('Status', row['status']?.toString() ?? '-'),
        ]),
      ],
      footer: _StatusFooter(caseId: row['id']?.toString() ?? ''),
    );
  }
}

class _StatusFooter extends ConsumerStatefulWidget {
  const _StatusFooter({required this.caseId});

  final String caseId;

  @override
  ConsumerState<_StatusFooter> createState() => _StatusFooterState();
}

class _StatusFooterState extends ConsumerState<_StatusFooter> {
  static const _options = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
  String _status = _options.first;
  bool _saving = false;

  Future<void> _update() async {
    setState(() => _saving = true);
    try {
      await ref.read(platformServiceProvider).patchSupportCase(widget.caseId, _status);
      ref.invalidate(supportCasesProvider);
      if (mounted) {
        showMvSnack(context, 'Support case updated to ${titleCase(_status)}.', success: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _status,
          isExpanded: true,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(labelText: 'Set status'),
          items: [
            for (final option in _options)
              DropdownMenuItem(value: option, child: Text(option, style: const TextStyle(fontSize: 13))),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _status = v);
          },
        ),
        const SizedBox(height: 12),
        GradientButton(
          label: _saving ? 'Updating…' : 'Update status',
          icon: 'check',
          expanded: true,
          onPressed: _saving ? null : _update,
        ),
      ],
    );
  }
}

class _NewSupportCard extends ConsumerStatefulWidget {
  const _NewSupportCard();

  @override
  ConsumerState<_NewSupportCard> createState() => _NewSupportCardState();
}

class _NewSupportCardState extends ConsumerState<_NewSupportCard> {
  final _subject = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  void _send() {
    showMvSnack(context, 'Support request sent to MVEC.', success: true);
    _subject.clear();
    _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DataCard(
      title: 'Open a support request',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _subject,
            style: const TextStyle(fontSize: 13.5),
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _message,
            maxLines: 4,
            style: const TextStyle(fontSize: 13.5),
            decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true),
          ),
          const SizedBox(height: 14),
          GradientButton(label: 'Send to MVEC', icon: 'arrow', expanded: true, onPressed: _send),
        ],
      ),
    );
  }
}