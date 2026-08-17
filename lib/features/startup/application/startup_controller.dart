import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/features/startup/data/startup_state_store.dart';

enum StartupDestination { onboarding, home }

final startupStateStoreProvider = Provider<StartupStateStore>((ref) {
  return SharedPreferencesStartupStateStore();
});

final startupDestinationProvider = FutureProvider<StartupDestination>((
  ref,
) async {
  try {
    final isComplete = await ref
        .read(startupStateStoreProvider)
        .isOnboardingComplete();
    return isComplete ? StartupDestination.home : StartupDestination.onboarding;
  } on Object {
    // Local preference failures must never leave the app on the launch frame.
    return StartupDestination.onboarding;
  }
});
