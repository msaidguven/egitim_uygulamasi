import 'package:flutter/widgets.dart';

import 'web_adsense_banner_stub.dart'
    if (dart.library.html) 'web_adsense_banner_web.dart';

class WebAdSenseBanner extends StatelessWidget {
  const WebAdSenseBanner({
    super.key,
    required this.adSlot,
    this.margin,
    this.height = 100,
  });

  final String adSlot;
  final EdgeInsetsGeometry? margin;
  final double height;

  @override
  Widget build(BuildContext context) {
    return buildWebAdSenseBanner(
      adSlot: adSlot,
      margin: margin,
      height: height,
    );
  }
}
