import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_theme.dart';
import '../providers/home_provider.dart';
import '../Widgets/vendor_card.dart';
import 'vendor_store_screen.dart';

/// Vendors tab: list of marketplace stores.
class VendorsScreen extends StatelessWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final vendors = provider.vendors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Vendors', style: AppTextStyles.headline(context)),
        ),
        Expanded(
          child:
              vendors.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: vendors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final vendor = vendors[index];
                      return VendorCard(
                        width: double.infinity,
                        vendor: vendor,
                        onTap:
                            () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => VendorStoreScreen(
                                      storeName: vendor.name,
                                    ),
                              ),
                            ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
