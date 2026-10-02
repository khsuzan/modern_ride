import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'modern_locate_method_channel.dart';

abstract class ModernLocatePlatform extends PlatformInterface {
  /// Constructs a ModernLocatePlatform.
  ModernLocatePlatform() : super(token: _token);

  static final Object _token = Object();

  static ModernLocatePlatform _instance = MethodChannelModernLocate();

  /// The default instance of [ModernLocatePlatform] to use.
  ///
  /// Defaults to [MethodChannelModernLocate].
  static ModernLocatePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ModernLocatePlatform] when
  /// they register themselves.
  static set instance(ModernLocatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
