
import 'modern_locate_platform_interface.dart';

class ModernLocate {
  Future<String?> getPlatformVersion() {
    return ModernLocatePlatform.instance.getPlatformVersion();
  }
}
