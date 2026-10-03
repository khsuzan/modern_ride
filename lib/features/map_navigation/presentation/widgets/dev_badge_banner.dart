import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';

class FlavorBanner extends StatelessWidget {
  final Widget child;
  const FlavorBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.current.showDevBanner) {
      return child;
    }
    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      color: Colors.redAccent,
      child: child,
    );
  }
}
