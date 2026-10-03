import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../models/user.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';
import '../../widgets/smart_table.dart';

final _searchUsersProvider = FutureProvider.autoDispose.family<Paged<UserRecord>, String>(
  (ref, query) => ref.watch(adminServiceProvider).users(search: query, limit: 20),
);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'GLOBAL SEARCH',
          title: 'Search the platform',
          subtitle: 'Find users and orders across the marketplace.',
        ),
        TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(fontSize: 14),
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Search users, emails, orders, vendors…',
            prefixIcon: Padding(
              padding: EdgeInsets.all(12),
              child: MvIcon('search', size: 18),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 0),
          ),
        ),
        const SizedBox(height: 18),
        if (query.isEmpty)
          const EmptyState(message: 'Type to search users and orders')
        else ...[
          const Text('Users', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _usersSection(query),
          const SizedBox(height: 24),
          const Text('Orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _ordersSection(query),
        ],
      ],
    );
  }

  Widget _usersSection(String query) {
    final users = ref.watch(_searchUsersProvider(query));
    return switch (users) {
      AsyncData(:final value) => _usersTable(value.items),
      AsyncError(:final error) => ErrorState(
          message: friendlyError(error),
          onRetry: () => ref.invalidate(_searchUsersProvider(query)),
        ),
      _ => const LoadingState(),
    };
  }

  Widget _ordersSection(String query) {
    final ordersAsync = ref.watch(ordersProvider);
    return switch (ordersAsync) {
      AsyncData(:final value) => _ordersTable(value, query),
      AsyncError(:final error) => ErrorState(
          message: friendlyError(error),
          onRetry: () => ref.invalidate(ordersProvider),
        ),
      _ => const LoadingState(),
    };
  }

  Widget _usersTable(List<UserRecord> users) {
    final rows = users
        .map((u) => {
              'name': u.display,
              'email': u.email ?? '-',
              'role': titleCase(u.role ?? 'User'),
              'status': (u.status ?? 'ACTIVE').toUpperCase(),
            })
        .toList();
    return SmartTable(
      columns: const [
        MvColumn('name', 'Name', flex: 2),
        MvColumn('email', 'Email', flex: 3),
        MvColumn('role', 'Role'),
      ],
      rows: rows,
      pageSize: 8,
      actionsLabel: 'Status',
      rowActions: (row) => StatusChip(
        row['status']?.toString(),
        overrideColor: row['status'] == 'ACTIVE' ? MvColors.successText : null,
      ),
    );
  }

  Widget _ordersTable(List<OrderRecord> orders, String query) {
    final q = query.toLowerCase();
    final matching = orders.where((o) {
      final haystack = '${o.orderNumber ?? ''} ${o.id ?? ''} ${o.buyer ?? ''} ${o.vendor ?? ''} ${o.status ?? ''} ${o.paymentStatus ?? ''}'.toLowerCase();
      return haystack.contains(q);
    }).toList();
    final rows = matching
        .map((o) => {
              'order': o.display,
              'buyer': o.buyer ?? '-',
              'vendor': o.vendor ?? '-',
              'total': money(o.total),
              'status': (o.status ?? 'PENDING').toUpperCase(),
            })
        .toList();
    return SmartTable(
      columns: const [
        MvColumn('order', 'Order', flex: 2),
        MvColumn('buyer', 'Buyer', flex: 2),
        MvColumn('vendor', 'Vendor', flex: 2),
        MvColumn('total', 'Total'),
      ],
      rows: rows,
      pageSize: 8,
      actionsLabel: 'Status',
      rowActions: (row) => StatusChip(row['status']?.toString()),
    );
  }
}