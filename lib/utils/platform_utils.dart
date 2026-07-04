import 'dart:io';

class PlatformUtils {
  PlatformUtils._();

  static bool get isWindows => Platform.isWindows;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
}
