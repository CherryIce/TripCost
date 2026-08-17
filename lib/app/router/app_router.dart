import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/shell/app_shell.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/converter/presentation/home_page.dart';
import 'package:trip_cost/features/dcc/presentation/dcc_page.dart';
import 'package:trip_cost/features/expense/application/expense_draft.dart';
import 'package:trip_cost/features/expense/presentation/ledger_page.dart';
import 'package:trip_cost/features/onboarding/presentation/onboarding_page.dart';
import 'package:trip_cost/features/payment_method/presentation/payment_comparison_page.dart';
import 'package:trip_cost/features/payment_method/presentation/payment_methods_page.dart';
import 'package:trip_cost/features/scanner/presentation/scan_page.dart';
import 'package:trip_cost/features/settings/presentation/settings_page.dart';
import 'package:trip_cost/features/startup/presentation/startup_page.dart';
import 'package:trip_cost/features/trip/presentation/trips_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = _createRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter _createRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.startup,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.startup,
        builder: (context, state) => const StartupPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.paymentMethods,
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.paymentComparison,
        builder: (context, state) => PaymentComparisonPage(
          draft: state.extra is ConversionDraft
              ? state.extra! as ConversionDraft
              : null,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.dcc,
        builder: (context, state) => DccPage(
          draft: state.extra is ConversionDraft
              ? state.extra! as ConversionDraft
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.scan,
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.tripCreate,
        builder: (context, state) => const TripEditorPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/trips/:tripId/edit',
        builder: (context, state) => TripEditorLoaderPage(
          tripId: state.pathParameters['tripId']!,
          initial: state.extra is TripModel ? state.extra! as TripModel : null,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/trips/:tripId',
        builder: (context, state) => TripDashboardPage(
          tripId: state.pathParameters['tripId']!,
          initial: state.extra is TripModel ? state.extra! as TripModel : null,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.expenseCreate,
        builder: (context, state) {
          final extra = state.extra;
          return ExpenseEditorPage(
            arguments: extra is ExpenseEditorArguments
                ? extra
                : extra is TripModel
                ? ExpenseEditorArguments(trip: extra)
                : null,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/ledger/:expenseId',
        builder: (context, state) => ExpenseDetailPage(
          expenseId: state.pathParameters['expenseId']!,
          initial: state.extra is ExpenseModel
              ? state.extra! as ExpenseModel
              : null,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.trips,
                builder: (context, state) => const TripsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.ledger,
                builder: (context, state) => const LedgerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
