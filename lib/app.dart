import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

class KidsFinanceApp extends ConsumerWidget {
  const KidsFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'KidsFinance',
      theme: AppTheme.parentTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
