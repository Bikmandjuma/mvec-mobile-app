import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import 'mv_icon.dart';

class MvColumn {
  const MvColumn(this.key, this.label, {this.flex = 1, this.align = TextAlign.left, this.bold = false});
  final String key;
  final String label;
  final int flex;
  final TextAlign align;
  final bool bold;
}

/// Port of the frontend `SmartTable`: toolbar (search / filter / export / count),
/// sticky uppercase header, row hover, and pagination.
class SmartTable extends StatefulWidget {
  const SmartTable({
    super.key,
    required this.columns,
    required this.rows,
    this.actionsLabel = 'Actions',
    this.rowActions,
    this.onRowTap,
    this.filterKey,
    this.filterLabel,
    this.filterOptions,
    this.showSearch = true,
    this.pageSize = 8,
    this.serverPage,
    this.serverTotalPages,
    this.onServerPageChanged,
    this.emptyMessage = 'No records found',
    this.csvFileName = 'export',
  });

  final List<MvColumn> columns;
  final List<Map<String, dynamic>> rows;
  final String actionsLabel;
  final Widget Function(Map<String, dynamic> row)? rowActions;
  final void Function(Map<String, dynamic> row)? onRowTap;

  /// When [filterKey] is set, a status/category filter dropdown is shown.
  final String? filterKey;
  final String? filterLabel;
  final List<String>? filterOptions;

  /// Set to false when the host screen supplies its own search box (e.g. a
  /// server-side search feeding a `family` provider).
  final bool showSearch;

  final int pageSize;

  /// If provided, pagination is driven by the server instead of client-side slicing.
  final int? serverPage;
  final int? serverTotalPages;
  final ValueChanged<int>? onServerPageChanged;

  final String emptyMessage;
  final String csvFileName;

  @override
  State<SmartTable> createState() => _SmartTableState();
}

class _SmartTableState extends State<SmartTable> {
  late final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _filter;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SmartTable old) {
    super.didUpdateWidget(old);
    if (old.filterKey != widget.filterKey) _filter = null;
  }

  List<Map<String, dynamic>> get _filtered {
    var rows = widget.rows;
    if (_filter != null && widget.filterKey != null) {
      rows = rows.where((r) {
        final v = (r[widget.filterKey!] ?? '').toString().toUpperCase();
        return v == _filter!.toUpperCase() || (_filter == 'OTHER' && v != 'ACTIVE' && v != 'PENDING');
      }).toList();
    }
    if (_query.isNotEmpty) {
      rows = rows.where((r) => r.values.any((v) => v.toString().toLowerCase().contains(_query))).toList();
    }
    return rows;
  }

  void _exportCsv() {
    final cols = widget.columns;
    final buf = StringBuffer();
    buf.writeln(cols.map((c) => '"${c.label}"').join(','));
    for (final row in _filtered) {
      buf.writeln(cols.map((c) {
        final v = (row[c.key] ?? '').toString().replaceAll('"', '""');
        return '"$v"';
      }).join(','));
    }
    Clipboard.setData(ClipboardData(text: '﻿${buf.toString()}'));
    showMvSnack(context, 'CSV copied to clipboard', success: true);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final serverMode = widget.serverPage != null && widget.onServerPageChanged != null;
    final total = serverMode ? rows.length : rows.length;
    final totalPages = serverMode
        ? (widget.serverTotalPages ?? 1)
        : (rows.isEmpty ? 1 : ((rows.length + widget.pageSize - 1) ~/ widget.pageSize));
    if (!serverMode && _page >= totalPages) _page = totalPages - 1;
    if (_page < 0) _page = 0;
    final visible = serverMode
        ? rows
        : rows.skip(_page * widget.pageSize).take(widget.pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(total),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).brightness == Brightness.dark ? MvColors.darkHeaderBg : MvColors.tableHeaderBg,
                    ),
                    headingRowHeight: 40,
                    dataRowMinHeight: 46,
                    dataRowMaxHeight: 56,
                    horizontalMargin: 16,
                    columnSpacing: 22,
                    dividerThickness: .6,
                    columns: [
                      ...widget.columns.map(
                        (c) => DataColumn(
                          label: Expanded(
                            child: Text(
                              c.label.toUpperCase(),
                              textAlign: c.align,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.rowActions != null)
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              widget.actionsLabel.toUpperCase(),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6, color: Theme.of(context).hintColor),
                            ),
                          ),
                        ),
                    ],
                    rows: visible
                        .map(
                          (row) => DataRow(
                            onSelectChanged: widget.onRowTap == null
                                ? null
                                : (_) => widget.onRowTap!(row),
                            cells: [
                              ...widget.columns.map(
                                (c) {
                                  final cell = row[c.key];
                                  return DataCell(
                                    cell is Widget
                                        ? cell
                                        : Text(
                                            (cell ?? '—').toString(),
                                            textAlign: c.align,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.35,
                                              fontWeight: c.bold ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                  );
                                },
                              ),
                              if (widget.rowActions != null)
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: widget.rowActions!(row),
                                  ),
                                ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  child: Text(widget.emptyMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _pagination(totalPages, rows.length),
      ],
    );
  }

  Widget _toolbar(int total) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (widget.showSearch)
          SizedBox(
            width: 240,
            height: 40,
            child: TextField(
              controller: _search,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search…',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(11),
                  child: MvIcon('search', size: 16),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 0),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        if (widget.filterKey != null && widget.filterOptions != null)
          SizedBox(
            height: 40,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filter,
                hint: Text(widget.filterLabel ?? 'Filter', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('All')),
                  ...widget.filterOptions!.map((e) => DropdownMenuItem(value: e, child: Text(titleCase(e), style: const TextStyle(fontSize: 12.5)))),
                ],
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _exportCsv,
          icon: const Icon(Icons.download_rounded, size: 15),
          label: const Text('Export CSV'),
        ),
        Text('$total record${total == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
      ],
    );
  }

  Widget _pagination(int totalPages, int count) {
    if (totalPages <= 1 && widget.serverPage == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text('Page 1 of 1', style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
      );
    }
    final current = (widget.serverPage ?? _page + 1);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Page $current of $totalPages', style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
        IconButton(
          tooltip: 'Previous',
          visualDensity: VisualDensity.compact,
          onPressed: current <= 1 ? null : () => _go(current - 1),
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        IconButton(
          tooltip: 'Next',
          visualDensity: VisualDensity.compact,
          onPressed: current >= totalPages ? null : () => _go(current + 1),
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }

  void _go(int pageOneBased) {
    if (widget.serverPage != null && widget.onServerPageChanged != null) {
      widget.onServerPageChanged!(pageOneBased);
    } else {
      setState(() => _page = pageOneBased - 1);
    }
  }
}

/// Table action icon button (31×31, radius 6) like `.table-action-btn`.
class TableActionBtn extends StatelessWidget {
  const TableActionBtn({super.key, required this.icon, this.onPressed, this.tooltip, this.danger = false});
  final String icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final w = SizedBox(
      width: 31,
      height: 31,
      child: Center(
        child: MvIcon(icon, size: 14, color: danger ? MvColors.dangerIcon : MvColors.primaryDeep),
      ),
    );
    final btn = Material(
      color: danger ? MvColors.errorBg : MvColors.metricIconBg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(6), child: w),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}