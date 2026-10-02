import 'package:flutter_test/flutter_test.dart';
import 'package:modern_locate/modern_locate.dart';
import 'package:modern_locate/modern_locate_platform_interface.dart';
import 'package:modern_locate/modern_locate_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockModernLocatePlatform
    with MockPlatformInterfaceMixin
    implements ModernLocatePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ModernLocatePlatform initialPlatform = ModernLocatePlatform.instance;

  test('$MethodChannelModernLocate is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelModernLocate>());
  });

  test('getPlatformVersion', () async {
    ModernLocate modernLocatePlugin = ModernLocate();
    MockModernLocatePlatform fakePlatform = MockModernLocatePlatform();
    ModernLocatePlatform.instance = fakePlatform;

    expect(await modernLocatePlugin.getPlatformVersion(), '42');
  });
}
