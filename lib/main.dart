import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/app.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        localDataChangeCoordinatorProvider.overrideWith(
          (ref) => ref.watch(productionLocalDataChangeCoordinatorProvider),
        ),
      ],
      child: const _ProductionAppBootstrap(),
    ),
  );
}

final class _ProductionAppBootstrap extends ConsumerStatefulWidget {
  const _ProductionAppBootstrap();

  @override
  ConsumerState<_ProductionAppBootstrap> createState() =>
      _ProductionAppBootstrapState();
}

final class _ProductionAppBootstrapState
    extends ConsumerState<_ProductionAppBootstrap> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(localDataChangeCoordinatorProvider).notify());
  }

  @override
  Widget build(BuildContext context) => const TripCostApp();
}
