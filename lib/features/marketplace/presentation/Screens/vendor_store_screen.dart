import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/app_theme.dart';

/// Temporary destination for marketplace storefronts that are not live yet.
class VendorStoreScreen extends StatelessWidget {
  const VendorStoreScreen({super.key, this.storeName});

  final String? storeName;

  @override
  Widget build(BuildContext context) {
    final mv = context.mv;
    return Scaffold(
      backgroundColor: mv.page,
      appBar: AppBar(
        backgroundColor: mv.surface,
        title: Text(storeName == null ? 'Store' : '$storeName Store'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: mv.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 48,
                  color: mv.accentDeep,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Store Page Coming Soon',
                textAlign: TextAlign.center,
                style: AppTextStyles.title(context).copyWith(fontSize: 21),
              ),
              const SizedBox(height: 8),
              Text(
                'Vendor storefronts are launching shortly. Please check back soon.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
