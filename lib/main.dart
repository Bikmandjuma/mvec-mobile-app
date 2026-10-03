import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'features/marketplace/presentation/providers/commerce_provider.dart';
import 'features/marketplace/presentation/providers/home_provider.dart';

/// Single entrypoint for the MVEC app.
///
/// The app is one project with two audiences behind the same auth gate:
/// the super admin lands on the control-center dashboard (`/admin`) and every
/// other role lands on the marketplace home feed (`/home`).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  // Resolved before the first frame so the light/dark preference is already
  // applied on launch and the app never flashes the wrong theme.
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MvecApp(),
    ),
  );
}

class MvecApp extends ConsumerWidget {
  const MvecApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // The storefront providers sit above the router so pages pushed on top of
    // the marketplace (search, categories, vendors, orders) inherit them too.
    // Both are lazy, so nothing is fetched until the marketplace is opened.
    return p.MultiProvider(
      providers: [
        p.ChangeNotifierProvider(create: (_) => HomeProvider()..loadHomeFeed()),
        p.ChangeNotifierProvider(create: (_) => CommerceProvider()),
      ],
      child: MaterialApp.router(
        title: 'MVEC',
        debugShowCheckedModeBanner: false,
        theme: lightAppTheme,
        darkTheme: darkAppTheme,
        themeMode: themeMode,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
