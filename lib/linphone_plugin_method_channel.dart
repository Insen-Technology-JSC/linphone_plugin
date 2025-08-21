import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'linphone_plugin_platform_interface.dart';

/// An implementation of [LinphonePluginPlatform] that uses method channels.
class MethodChannelLinphonePlugin extends LinphonePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('linphone_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
