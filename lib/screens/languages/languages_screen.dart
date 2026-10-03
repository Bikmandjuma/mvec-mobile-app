import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

class LanguagesScreen extends ConsumerWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Languages',
          subtitle: 'Manage marketplace translations (English · Kinyarwanda · Français).',
        ),
        const _LanguageChips(),
        const SizedBox(height: 16),
        DataCard(
          title: 'Translation keys',
          trailing: switch (translations) {
            AsyncData(:final value) => Text(
                '${value.length} keys',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).hintColor),
              ),
            _ => null,
          },
          child: switch (translations) {
            AsyncData(:final value) => _rows(context, value),
            AsyncError(:final error) => ErrorState(
                message: friendlyError(error),
                onRetry: () => ref.invalidate(translationsProvider),
              ),
            _ => const LoadingState(),
          },
        ),
      ],
    );
  }

  Widget _rows(BuildContext context, List<TranslationRecord> list) {
    final records = list.take(10).toList();
    return Column(
      children: [
        for (var i = 0; i < records.length; i++) ...[
          _TranslationRow(record: records[i]),
          if (i != records.length - 1)
            Divider(height: 24, color: Theme.of(context).dividerColor),
        ],
      ],
    );
  }
}

class _LanguageChips extends ConsumerStatefulWidget {
  const _LanguageChips();

  @override
  ConsumerState<_LanguageChips> createState() => _LanguageChipsState();
}

class _LanguageChipsState extends ConsumerState<_LanguageChips> {
  static const _languages = ['EN', 'RW', 'FR'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: MvColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MvColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _languages.length; i++)
              InkWell(
                onTap: () => setState(() => _selected = i),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: _selected == i ? MvColors.metricIconBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    _languages[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                      color: _selected == i ? MvColors.primaryDeep : MvColors.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TranslationRow extends ConsumerStatefulWidget {
  const _TranslationRow({required this.record});

  final TranslationRecord record;

  @override
  ConsumerState<_TranslationRow> createState() => _TranslationRowState();
}

class _TranslationRowState extends ConsumerState<_TranslationRow> {
  late final TextEditingController _en = TextEditingController(text: widget.record.en ?? '');
  late final TextEditingController _rw = TextEditingController(text: widget.record.rw ?? '');
  late final TextEditingController _fr = TextEditingController(text: widget.record.fr ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _en.dispose();
    _rw.dispose();
    _fr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(platformServiceProvider).upsertTranslation(
            widget.record.key ?? 'key',
            widget.record.module ?? '',
            {'en': _en.text, 'rw': _rw.text, 'fr': _fr.text},
          );
      ref.invalidate(translationsProvider);
      if (mounted) showMvSnack(context, 'Translation saved.', success: true);
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final children = [
          _field('English', _en),
          const SizedBox(height: 10),
          _field('Kinyarwanda', _rw),
          const SizedBox(height: 10),
          _field('Français', _fr),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.record.key ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : _save,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Save translation',
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const MvIcon('check', color: MvColors.primaryDeep),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (narrow)
              ...children
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Expanded(child: children[i]),
                    if (i != 2) const SizedBox(width: 10),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12.5),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}