import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestPrinterPermissions() async {
    if (Platform.isAndroid) {
      final permissions = <Permission>[
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.locationWhenInUse,
        Permission.photos,
        Permission.storage,
      ];

      final statuses = await permissions.request();

      // Some permissions are ignored depending on Android version. The printer can
      // continue if at least one relevant runtime permission is granted/limited.
      return statuses.values.any((status) => status.isGranted || status.isLimited);
    }

    if (Platform.isIOS) {
      final statuses = await <Permission>[
        Permission.bluetooth,
        Permission.photos,
      ].request();

      final bluetoothOk = statuses[Permission.bluetooth]?.isGranted ?? true;
      final photosStatus = statuses[Permission.photos];
      final photosOk = photosStatus == null || photosStatus.isGranted || photosStatus.isLimited;
      return bluetoothOk && photosOk;
    }

    return true;
  }
}
