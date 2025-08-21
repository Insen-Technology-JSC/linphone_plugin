import 'package:flutter/services.dart';

const eventChannel = EventChannel('com.example.flutter/event_channel');
const methodChannel = MethodChannel('com.example.flutter/method_channel');

class ChannelHelper {
  ChannelHelper._instance();
  static final ChannelHelper instance = ChannelHelper._instance();

  Future<void> register({
    required String userName,
    required String password,
    required String domain,
  }) async {
    await methodChannel.invokeMethod('register',
        {'user_name': userName, 'password': password, 'domain': domain});
  }

  Future<void> makeCall({required String dest}) async {
    await methodChannel.invokeMethod('make_call', {'dest': dest});
  }

  Future<void> terminateCall() async {
    await methodChannel.invokeMethod('terminate_call');
  }

  Future<void> acceptCall() async {
    await methodChannel.invokeMethod('accept_call');
  }

  Future<void> switchCamera() async {
    await methodChannel.invokeMethod('switch_camera');
  }

  Future<void> toggleSpeaker() async {
    await methodChannel.invokeMethod('toggle_speaker');
  }

  void registerEventCallback({required Function(dynamic) eventCallback}) {
    eventChannel.receiveBroadcastStream().listen((event) {
      eventCallback.call(event);
    });
  }
}
