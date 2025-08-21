import Flutter
import UIKit

public class LinphonePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var linPhoneController = LinPhoneController()

    // Tên channel phải khớp với bên Dart
    private static let eventChannelName = "com.example.flutter/event_channel"
    private static let methodChannelName = "com.example.flutter/method_channel"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = LinphonePlugin()

        // Method channel
        let methodChannel = FlutterMethodChannel(name: methodChannelName,
                                                 binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        // Event channel
        let eventChannel = FlutterEventChannel(name: eventChannelName,
                                               binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)

        // Register native view nếu có
        let viewFactory = LinPhoneFactory(messenger: registrar.messenger(),
                                          linPhoneController: instance.linPhoneController)
        registrar.register(viewFactory, withId: "ios_native_view_integration")

        // Init Linphone core
        instance.initLinphone()
    }

    private func initLinphone() {
        linPhoneController.initCore(
            onRegisterCallback: { isSuccess in
                let baseResponse = BaseResponse(funcName: "onRegisterCallback",
                                                isRegister: isSuccess,
                                                remoteAddress: "")
                self.eventSink?(baseResponse.toString())
            },
            onIncomingReceived: { remoteAddress in
                let baseResponse = BaseResponse(funcName: "onIncomingReceived",
                                                isRegister: true,
                                                remoteAddress: remoteAddress)
                self.eventSink?(baseResponse.toString())
            },
            onReleased: {
                let baseResponse = BaseResponse(funcName: "onReleased",
                                                isRegister: true,
                                                remoteAddress: "")
                self.eventSink?(baseResponse.toString())
            },
            onConnected: { remoteAddress in
                let baseResponse = BaseResponse(funcName: "onConnected",
                                                isRegister: true,
                                                remoteAddress: remoteAddress)
                self.eventSink?(baseResponse.toString())
            },
            onOutgoingProgress: { remoteAddress in
                let baseResponse = BaseResponse(funcName: "onOutgoingProgress",
                                                isRegister: true,
                                                remoteAddress: remoteAddress)
                self.eventSink?(baseResponse.toString())
            }
        )
    }

    // MARK: - MethodChannel
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "register":
            let arguments = call.arguments as? [String: Any]
            let userName = arguments?["user_name"] as? String
            let password = arguments?["password"] as? String
            let domain = arguments?["domain"] as? String

            linPhoneController.domain = domain ?? ""
            linPhoneController.username = userName ?? ""
            linPhoneController.passwd = password ?? ""
            linPhoneController.login()
            result(nil)

        case "make_call":
            let arguments = call.arguments as? [String: Any]
            let dest = arguments?["dest"] as? String
            linPhoneController.remoteAddress = dest ?? ""
            linPhoneController.outgoingCall()
            result(nil)

        case "accept_call":
            linPhoneController.acceptCall()
            result(nil)

        case "terminate_call":
            linPhoneController.terminateCall()
            result(nil)

        case "switch_camera":
            linPhoneController.toggleCamera()
            result(nil)

        case "toggle_speaker":
            linPhoneController.toggleSpeaker()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - EventChannel
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
