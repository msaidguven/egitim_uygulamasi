import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'ad_banner_widget.dart';
import 'web_adsense_banner.dart';

class AdaptiveAdBanner extends StatelessWidget {
  const AdaptiveAdBanner({
    super.key,
    required this.adSlot,
    this.margin,
    this.webHeight = 100,
  });

  final String adSlot;
  final EdgeInsetsGeometry? margin;
  final double webHeight;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebAdSenseBanner(
        adSlot: adSlot,
        margin: margin,
        height: webHeight,
      );
    }
    return AdBannerWidget(margin: margin);
  }
}
