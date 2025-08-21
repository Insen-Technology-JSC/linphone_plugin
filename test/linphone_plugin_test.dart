import 'package:flutter_test/flutter_test.dart';
import 'package:linphone_plugin/linphone_plugin.dart';
import 'package:linphone_plugin/linphone_plugin_platform_interface.dart';
import 'package:linphone_plugin/linphone_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLinphonePluginPlatform
    with MockPlatformInterfaceMixin
    implements LinphonePluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LinphonePluginPlatform initialPlatform = LinphonePluginPlatform.instance;

  test('$MethodChannelLinphonePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLinphonePlugin>());
  });

  test('getPlatformVersion', () async {
    LinphonePlugin linphonePlugin = LinphonePlugin();
    MockLinphonePluginPlatform fakePlatform = MockLinphonePluginPlatform();
    LinphonePluginPlatform.instance = fakePlatform;

    expect(await linphonePlugin.getPlatformVersion(), '42');
  });
}
