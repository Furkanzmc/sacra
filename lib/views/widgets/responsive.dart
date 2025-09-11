import 'package:flutter/widgets.dart';

class Responsive {
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  static double constrainedWidth(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (isPhone(context)) {
      return size.width;
    }
    return 420;
  }
}

