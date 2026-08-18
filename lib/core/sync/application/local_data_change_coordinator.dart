import 'dart:async';
import 'dart:developer' as developer;

import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/sync/application/sync_orchestrator.dart';
import 'package:trip_cost/core/widget/widget_snapshot_service.dart';

abstract interface class LocalDataChangeNotifier {
  Future<void> notify();
}

final class NoopLocalDataChangeNotifier implements LocalDataChangeNotifier {
  const NoopLocalDataChangeNotifier();

  @override
  Future<void> notify() => Future<void>.value();
}

final class LocalDataChangeCoordinator implements LocalDataChangeNotifier {
  const LocalDataChangeCoordinator({
    required SettingsRepository settingsRepository,
    required SyncOrchestrator syncOrchestrator,
    required WidgetSnapshotService widgetSnapshotService,
  }) : _settingsRepository = settingsRepository,
       _syncOrchestrator = syncOrchestrator,
       _widgetSnapshotService = widgetSnapshotService;

  final SettingsRepository _settingsRepository;
  final SyncOrchestrator _syncOrchestrator;
  final WidgetSnapshotService _widgetSnapshotService;

  @override
  Future<void> notify() async {
    await _refreshWidget();
    unawaited(_requestSyncIfEnabled());
  }

  Future<void> _refreshWidget() async {
    try {
      await _widgetSnapshotService.refresh();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Widget snapshot refresh failed.',
        name: 'trip_cost.widget',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      // App Group availability never changes the success of the local write.
    }
  }

  Future<void> _requestSyncIfEnabled() async {
    try {
      if ((await _settingsRepository.load())?.syncEnabled == true) {
        _syncOrchestrator.requestBackgroundSync();
      }
    } on Object {
      // Local data is already committed; a later manual sync can retry.
    }
  }
}
