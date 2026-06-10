import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

enum AppPlatform {
  mac,
  windows,
  unsupported,
}

AppPlatform get currentPlatform {
  if (kIsWeb) return AppPlatform.unsupported;
  if (Platform.isMacOS) return AppPlatform.mac;
  if (Platform.isWindows) return AppPlatform.windows;
  return AppPlatform.unsupported;
}

bool get isMacOS => currentPlatform == AppPlatform.mac;

bool get isWindows => currentPlatform == AppPlatform.windows;
