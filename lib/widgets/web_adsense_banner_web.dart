// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

int _adCounter = 0;
final Set<String> _registeredViewTypes = <String>{};

Widget buildWebAdSenseBanner({
  required String adSlot,
  EdgeInsetsGeometry? margin,
  double height = 100,
}) {
  final normalizedSlot = adSlot.trim();
  if (normalizedSlot.isEmpty || normalizedSlot == '0000000000') {
    return const SizedBox.shrink();
  }

  final viewType = 'adsense-banner-$normalizedSlot-${_adCounter++}';
  if (!_registeredViewTypes.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final wrapper = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..setAttribute('style', 'display:block;width:100%;')
        ..setAttribute('data-ad-client', 'ca-pub-8561144837504825')
        ..setAttribute('data-ad-slot', normalizedSlot)
        ..setAttribute('data-ad-format', 'auto')
        ..setAttribute('data-full-width-responsive', 'true');

      wrapper.append(ins);

      Future<void>.microtask(() {
        try {
          final trigger = html.ScriptElement()
            ..type = 'text/javascript'
            ..text = '(adsbygoogle = window.adsbygoogle || []).push({});';
          wrapper.append(trigger);
        } catch (_) {}
      });

      return wrapper;
    });
    _registeredViewTypes.add(viewType);
  }

  return Container(
    margin: margin,
    constraints: BoxConstraints(minHeight: height),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: HtmlElementView(viewType: viewType),
    ),
  );
}
