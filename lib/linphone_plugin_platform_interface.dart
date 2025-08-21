import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'linphone_plugin_method_channel.dart';

abstract class LinphonePluginPlatform extends PlatformInterface {
  /// Constructs a LinphonePluginPlatform.
  LinphonePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static LinphonePluginPlatform _instance = MethodChannelLinphonePlugin();

  /// The default instance of [LinphonePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelLinphonePlugin].
  static LinphonePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LinphonePluginPlatform] when
  /// they register themselves.
  static set instance(LinphonePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
