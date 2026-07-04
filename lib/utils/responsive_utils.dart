import 'package:flutter/material.dart';

class ResponsiveUtils {
  ResponsiveUtils._();

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 700;
  }

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 700 && width < 1100;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1100;
  }

  static double pagePadding(BuildContext context) {
    if (isWide(context)) return 32;
    if (isMedium(context)) return 24;
    return 16;
  }

  static int gridColumns(BuildContext context) {
    if (isWide(context)) return 3;
    if (isMedium(context)) return 2;
    return 1;
  }
}
