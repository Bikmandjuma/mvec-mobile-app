import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../widgets/common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _marketplaceName = TextEditingController(text: 'MVEC Marketplace');
  final _commission = TextEditingController(text: '10');
  String _currency = 'RWF';
  String _vendorApproval = 'Manual';
  String _cancelWindow = '24 hours';
  String _reviewsModeration = 'Required';
  String _orderNotif = 'Enabled';
  String _shippingNotif = 'Enabled';
  String _payoutNotif = 'Disabled';

  @override
  void dispose() {
    _marketplaceName.dispose();
    _commission.dispose();
    super.dispose();
  }

  void _save() {
    showMvSnack(context, 'Platform settings saved.', success: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'ADMIN CONTROL',
          title: 'Platform Settings',
          subtitle: 'Platform-wide configuration.',
          actions: [
            GradientButton(label: 'Save changes', icon: 'check', onPressed: _save),
          ],
        ),
        DataCard(
          title: 'Marketplace',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _marketplaceName,
                style: const TextStyle(fontSize: 13.5),
                decoration: const InputDecoration(labelText: 'Marketplace name'),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dropdownField('Default currency', _currency, const ['RWF', 'USD'], (v) => setState(() => _currency = v)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdownField('Vendor approval', _vendorApproval, const ['Manual', 'Automatic'], (v) => setState(() => _vendorApproval = v)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DataCard(
          title: 'Commerce rules',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _commission,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13.5),
                decoration: const InputDecoration(labelText: 'Platform commission (%)'),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dropdownField('Order cancellation window', _cancelWindow, const ['12 hours', '24 hours', '48 hours'], (v) => setState(() => _cancelWindow = v)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdownField('Reviews moderation', _reviewsModeration, const ['Required', 'Optional'], (v) => setState(() => _reviewsModeration = v)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DataCard(
          title: 'Notifications',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _dropdownField('Order notifications', _orderNotif, const ['Enabled', 'Disabled'], (v) => setState(() => _orderNotif = v))),
              const SizedBox(width: 12),
              Expanded(child: _dropdownField('Shipping notifications', _shippingNotif, const ['Enabled', 'Disabled'], (v) => setState(() => _shippingNotif = v))),
              const SizedBox(width: 12),
              Expanded(child: _dropdownField('Payout notifications', _payoutNotif, const ['Enabled', 'Disabled'], (v) => setState(() => _payoutNotif = v))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option, style: const TextStyle(fontSize: 13))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}