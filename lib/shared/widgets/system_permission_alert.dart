import 'package:flutter/cupertino.dart';
import 'package:trip_cost/core/platform/system_permissions.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

Future<void> showSystemPermissionUnavailableAlert({
  required BuildContext context,
  required SystemPermissionUnavailable error,
  required SystemPermissionGateway gateway,
}) async {
  final l10n = AppLocalizations.of(context);
  final isCamera = error.permission == SystemPermission.camera;
  final shouldOpenSettings = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      key: const Key('system-permission-alert'),
      title: Text(
        isCamera
            ? l10n.permissionCameraUnavailableTitle
            : l10n.permissionPhotoLibraryUnavailableTitle,
      ),
      content: Text(
        isCamera
            ? l10n.permissionCameraUnavailableBody
            : l10n.permissionPhotoLibraryUnavailableBody,
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          key: const Key('system-permission-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        CupertinoDialogAction(
          key: const Key('system-permission-open-settings'),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.permissionOpenSettings),
        ),
      ],
    ),
  );
  if (shouldOpenSettings == true) {
    await gateway.openSettings();
  }
}
