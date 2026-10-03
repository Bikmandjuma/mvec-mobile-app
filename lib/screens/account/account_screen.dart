import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/user.dart';
import '../../providers/admin_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

/// Account management (Platform group) — the signed-in super-admin's own
/// profile, security (change password) and app preferences.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Account',
          subtitle: 'Manage your administrator profile, security and preferences.',
        ),
        const SizedBox(height: 4),
        _ProfileCard(user: user),
        const SizedBox(height: 16),
        _SecurityCard(user: user),
        const SizedBox(height: 16),
        _PreferencesCard(),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({this.user});
  final UserRecord? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.display ?? 'Administrator';
    return DataCard(
      title: 'Administrator profile',
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(gradient: MvColors.gradient, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initials(name),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
          StatusChip('super_admin'),
        ],
      ),
    );
  }
}

class _SecurityCard extends ConsumerWidget {
  const _SecurityCard({this.user});
  final UserRecord? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DataCard(
      title: 'Security',
      subtitle: 'Keep your administrator credentials protected.',
      child: Column(
        children: [
          _RowTile(
            icon: 'settings',
            label: 'Change password',
            subtitle: 'Enter your current password to set a new one',
            onTap: () => _openChangePassword(context, ref),
          ),
          const Divider(height: 22),
          _RowTile(
            icon: 'logout',
            label: 'Sign out',
            subtitle: 'End this session and return to the login screen',
            danger: true,
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  void _openChangePassword(BuildContext context, WidgetRef ref) {
    final cur = TextEditingController();
    final neo = TextEditingController();
    bool saving = false;
    BuildContext? sheetContext;
    showMvDetailModal(
      context,
      title: 'CHANGE PASSWORD',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Current password', cur, obscure: true),
            const SizedBox(height: 12),
            _field('New password (min 6 characters)', neo, obscure: true),
          ],
        ),
      ],
      footer: StatefulBuilder(
        builder: (ctx, setModal) {
          sheetContext = ctx;
          return SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: saving ? 'Updating…' : 'Update password',
              expanded: true,
              onPressed: saving
                  ? null
                  : () async {
                      final outer = context;
                      if (cur.text.isEmpty || neo.text.length < 6) {
                        showMvSnack(ctx, 'Enter your current and a new password (min 6 characters)');
                        return;
                      }
                      setModal(() => saving = true);
                      try {
                        await ref
                            .read(adminServiceProvider)
                            .changePassword(currentPassword: cur.text, newPassword: neo.text);
                        final sc = sheetContext;
                        if (sc != null && sc.mounted) Navigator.pop(sc);
                        if (outer.mounted) showMvSnack(outer, 'Password updated', success: true);
                      } catch (e) {
                        setModal(() => saving = false);
                        if (outer.mounted) showMvSnack(outer, friendlyError(e));
                      }
                    },
            ),
          );
        },
      ),
    );
  }
}

class _PreferencesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DataCard(
      title: 'Preferences',
      child: Column(
        children: [
          SwitchListTile(
            value: isDark,
            onChanged:
                (v) => ref
                    .read(themeModeProvider.notifier)
                    .set(v ? ThemeMode.dark : ThemeMode.light),
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark mode', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Switch between light and dark admin console'),
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: MvColors.metricIconBg, borderRadius: BorderRadius.circular(9)),
              child: const Center(child: MvIcon('moon', size: 18, color: MvColors.primaryDeep)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.icon, required this.label, required this.subtitle, this.onTap, this.danger = false});
  final String icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? MvColors.dangerIcon : MvColors.primaryDeep;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: danger ? MvColors.errorBg : MvColors.metricIconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(child: MvIcon(icon, size: 17, color: fg)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            MvIcon('arrow', size: 16, color: Theme.of(context).hintColor),
          ],
        ),
      ),
    );
  }
}

Widget _field(String label, TextEditingController c, {bool obscure = false}) {
  return TextField(
    controller: c,
    obscureText: obscure,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.lock_outline, size: 20)),
  );
}