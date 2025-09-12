import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linphone_plugin/linphone_plugin.dart';
import 'package:linphone_plugin_example/storage.dart';

import 'circular_button.dart';

class LinPhonePage extends StatefulWidget {
  const LinPhonePage({super.key, required this.title});

  final String title;
  @override
  State<LinPhonePage> createState() => _LinPhonePageState();
}

class _LinPhonePageState extends State<LinPhonePage> {
  String remoteDest = '';
  var isRegistered = false;
  var isCallRunning = false;
  var isOutgoingCall = false;
  var isIncomingReceived = false;
  final textController = TextEditingController(text: '100');
  final _usernameController = TextEditingController(text: '5004');
  final _passwordController = TextEditingController(text: '4913b02c5fc4a4d9');
  final _domainController = TextEditingController(
    text: 'IST-GWH-2102-0001C031E907-L003032300001-dev.sip.insentecs.cloud',
  );

  @override
  void initState() {
    // isRegistered = true;
    // isIncomingReceived = true;
    // isRegistered = true;
    // isCallRunning = true;
    if (Storage.instance.dest.isNotEmpty == true) {
      textController.text = Storage.instance.dest;
    }
    if (Storage.instance.userName.isNotEmpty == true) {
      _usernameController.text = Storage.instance.userName;
      _passwordController.text = Storage.instance.password;
      _domainController.text = Storage.instance.domain;
    }
    ChannelHelper.instance.registerEventCallback(
      eventCallback: (data) {
        final funcName = jsonDecode(data)['funcName'];
        final isRegister = jsonDecode(data)['isRegister'];
        final remoteAddress = jsonDecode(data)['remoteAddress'];

        log(
          '$runtimeType, register_callback | data: $data, funtion: $funcName',
        );
        switch (funcName) {
          case 'onRegisterCallback':
            if (isRegister) {
              Storage.instance.storeUser(value: _usernameController.text);
              Storage.instance.storePassword(value: _passwordController.text);
              Storage.instance.storeDomain(value: _domainController.text);
              setState(() {
                isRegistered = true;
                isCallRunning = false;
                isIncomingReceived = false;
                isOutgoingCall = false;
              });
            }
            break;
          case 'onIncomingReceived':
            setState(() {
              isIncomingReceived = true;
              isOutgoingCall = false;
              remoteDest = remoteAddress;
            });
            break;
          case 'onReleased':
            setState(() {
              isCallRunning = false;
              isIncomingReceived = false;
              isOutgoingCall = false;
            });

          case 'onConnected':
            setState(() {
              isCallRunning = true;
              isOutgoingCall = false;
            });
            ChannelHelper.instance.toggleSpeaker();
            break;
          case 'onOutgoingProgress':
            setState(() {
              isOutgoingCall = true;
              remoteDest = remoteAddress;
            });
            break;
          default:
            break;
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          alignment: Alignment.center,
          // color: Colors.redAccent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isRegistered == true) ...[
                // UI incall
                if (isCallRunning == true) ...[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          color: Colors.white,
                          child:
                              (Platform.isIOS == true)
                                  ? UiKitView(
                                    viewType:
                                        'ios_native_view_integration', // Identifier for the native view.
                                    creationParams:
                                        const {}, // To send data from Flutter view to SwiftUI view
                                    creationParamsCodec:
                                        const StandardMessageCodec(),
                                    onPlatformViewCreated: (id) {},
                                  )
                                  : const AndroidView(
                                    viewType: 'android_native_view_integration',
                                    layoutDirection: TextDirection.ltr,
                                    creationParams: {},
                                    creationParamsCodec: StandardMessageCodec(),
                                  ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              height: 56,
                              width: 500,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _circleButton(
                                    bgColor: Colors.black.withOpacity(0.8),
                                    assetName:
                                        'assets/icons/ic_switch_camera.png',
                                    onPressed: () {
                                      ChannelHelper.instance.switchCamera();
                                    },
                                  ),
                                  _circleButton(
                                    assetName: 'assets/icons/ic_end_call.png',
                                    onPressed: () {
                                      ChannelHelper.instance.terminateCall();
                                    },
                                    bgColor: Colors.red,
                                  ),
                                  _circleButton(
                                    assetName:
                                        'assets/icons/ic_enable_speaker.png',
                                    bgColor: Colors.black.withOpacity(0.8),
                                    onPressed: () {
                                      ChannelHelper.instance.toggleSpeaker();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (isIncomingReceived == true) ...[
                    // UI incoming
                    Container(
                      height: MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        // crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width,
                            height: 48,
                            child: Text(
                              remoteDest,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 3,
                          ),
                          Container(
                            height: 72,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 40,
                            ),
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _circleButton(
                                  assetName: 'assets/icons/ic_end_call.png',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    ChannelHelper.instance.terminateCall();
                                  },
                                  bgColor: Colors.red,
                                ),
                                _circleButton(
                                  assetName: 'assets/icons/ic_accept_call.png',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    ChannelHelper.instance.acceptCall();
                                  },
                                  bgColor: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // UI out going call
                    if (isOutgoingCall == true) ...[
                      Container(
                        height: MediaQuery.of(context).size.height,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: 48,
                              child: Text(
                                remoteDest,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 3,
                            ),
                            Container(
                              height: 64,
                              margin: const EdgeInsets.symmetric(vertical: 40),
                              width: MediaQuery.of(context).size.width,
                              child: _circleButton(
                                assetName: 'assets/icons/ic_accept_call.png',
                                bgColor: Colors.red,
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ChannelHelper.instance.terminateCall();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        height: MediaQuery.of(context).size.height,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: TextField(
                                controller: textController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Dest',
                                ),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 3,
                            ),
                            Container(
                              height: 64,
                              margin: const EdgeInsets.symmetric(vertical: 40),
                              width: MediaQuery.of(context).size.width,
                              child: _circleButton(
                                assetName: 'assets/icons/ic_accept_call.png',
                                bgColor: Colors.green,
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ChannelHelper.instance.makeCall(
                                    dest: textController.text,
                                  );
                                  Storage.instance.storeDest(
                                    value: textController.text,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ] else ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Nhập thông tin kết nối:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          labelText: 'UserName',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _domainController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          labelText: 'Domain',
                          prefixIcon: Icon(Icons.public),
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () {
                          final userName = _usernameController.text;
                          final password = _passwordController.text;
                          final domain = _domainController.text;
                          log(
                            '$runtimeType,register_info |  userName: ${userName},password:$password, domain:$domain',
                          );

                          ChannelHelper.instance.register(
                            userName: userName,
                            password: password,
                            domain: domain,
                            fbProjectId: 'dev-genki-notification',
                            hubId: '',
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required String assetName,
    required VoidCallback onPressed,
    Color? bgColor,
  }) {
    return CircularButton(
      color: bgColor,
      onPressed: onPressed,
      size: 56,
      child: Image.asset(width: 28, height: 28, assetName, color: Colors.white),
    );
  }
}
