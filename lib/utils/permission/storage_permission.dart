import 'package:permission_handler/permission_handler.dart';

Future<bool> checkStoragePermission() async {
  final isAndroid11OrAbove =
      await Permission.manageExternalStorage.status != null;

  var storageStatus = isAndroid11OrAbove
      ? await Permission.manageExternalStorage.status
      : await Permission.storage.status;

  // Request if denied
  if (storageStatus.isDenied) {
    storageStatus = isAndroid11OrAbove
        ? await Permission.manageExternalStorage.request()
        : await Permission.storage.request();
  }

  // If permanently denied, open app settings
  if (storageStatus.isPermanentlyDenied) {
    openAppSettings();
    return false;
  }

  return storageStatus.isGranted;
}
