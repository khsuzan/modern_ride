import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'modern_locate_platform_interface.dart';

/// An implementation of [ModernLocatePlatform] that uses method channels.
class MethodChannelModernLocate extends ModernLocatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('modern_locate');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
