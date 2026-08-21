import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/app/app_surface_controller.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/features/future_invest/presentation/future_invest_page.dart';
import 'package:trip_cost/features/scanner/application/scan_flow.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appSurfaceControllerProvider) ==
        AppSurfaceMode.futureInvest) {
      return const FutureInvestPage();
    }

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: Column(
        children: <Widget>[
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: navigationShell,
            ),
          ),
          _AppNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            onScanPressed: () => context.push(
              AppRoutes.scan,
              extra: ScanPageArguments(
                initialPurpose:
                    navigationShell.currentIndex == 1 ||
                        navigationShell.currentIndex == 2
                    ? ScanPurpose.record
                    : ScanPurpose.compare,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppNavigationBar extends StatelessWidget {
  const _AppNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onScanPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onScanPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final borderColor = CupertinoDynamicColor.resolve(
      CupertinoColors.separator,
      context,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemBackground,
          context,
        ),
      ),
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: SizedBox(
          height: 58,
          child: Row(
            children: <Widget>[
              _Destination(
                icon: CupertinoIcons.house,
                index: 0,
                label: localizations.homeTab,
                selectedIndex: currentIndex,
                onTap: onDestinationSelected,
              ),
              _Destination(
                icon: CupertinoIcons.airplane,
                index: 1,
                label: localizations.tripsTab,
                selectedIndex: currentIndex,
                onTap: onDestinationSelected,
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: localizations.scanAction,
                  child: CupertinoButton(
                    minimumSize: const Size.square(48),
                    padding: EdgeInsets.zero,
                    onPressed: onScanPressed,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        height: 48,
                        width: 48,
                        child: Icon(
                          CupertinoIcons.viewfinder,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _Destination(
                icon: CupertinoIcons.book,
                index: 2,
                label: localizations.ledgerTab,
                selectedIndex: currentIndex,
                onTap: onDestinationSelected,
              ),
              _Destination(
                icon: CupertinoIcons.settings,
                index: 3,
                label: localizations.settingsTab,
                selectedIndex: currentIndex,
                onTap: onDestinationSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.icon,
    required this.index,
    required this.label,
    required this.onTap,
    required this.selectedIndex,
  });

  final IconData icon;
  final int index;
  final String label;
  final ValueChanged<int> onTap;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final color = isSelected
        ? AppColors.primary
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: CupertinoButton(
          minimumSize: const Size.fromHeight(58),
          padding: EdgeInsets.zero,
          onPressed: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
