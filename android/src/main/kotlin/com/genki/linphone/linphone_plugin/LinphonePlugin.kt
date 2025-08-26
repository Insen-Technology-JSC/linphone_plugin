package com.genki.linphone.linphone_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
// import io.flutter.plugin.common.MethodCall
// import io.flutter.plugin.common.MethodChannel
// import io.flutter.plugin.common.MethodChannel.MethodCallHandler
// import io.flutter.plugin.common.MethodChannel.Result

import android.Manifest
import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.genki.linphone.linphone_plugin.LinPhoneFactory
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
// import io.flutter.plugins.GeneratedPluginRegistrant
// import io.flutter.embedding.android.FlutterFragmentActivity
// import io.flutter.embedding.engine.FlutterEngine
import org.linphone.core.Account
import org.linphone.core.AudioDevice
import org.linphone.core.Call
import org.linphone.core.Core
import org.linphone.core.CoreListenerStub
import org.linphone.core.Factory
import org.linphone.core.MediaEncryption
import org.linphone.core.RegistrationState
import org.linphone.core.TransportType
import java.text.SimpleDateFormat
import java.util.Date

/** LinphonePlugin */
class LinphonePlugin: FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
  
  
    private val eventChannel = "com.example.flutter/event_channel"
    private val methodChannel = "com.example.flutter/method_channel"
    private lateinit var channel: MethodChannel
    private var messageChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var domain: String = ""
    private var handler = Handler(Looper.getMainLooper())
    private val runnable: Runnable = object : Runnable {
        @SuppressLint("SimpleDateFormat")
        override fun run() {
            handler.post {
                val dateFormat = SimpleDateFormat("HH:mm:ss")
                val time = dateFormat.format(Date())
                eventSink?.success(time)
            }
            handler.postDelayed(this, 1000)
        }
    }

    //     linphone
    private lateinit var core: Core
    private val coreListener = object : CoreListenerStub() {
        override fun onAccountRegistrationStateChanged(
            core: Core,
            account: Account,
            state: RegistrationState?,
            message: String
        ) {
//            findViewById<TextView>(R.id.registration_status).text = message
            Log.d("CoreListenerStub", "message: $message")
            if (state == RegistrationState.Failed) {
                eventSink?.success(
                    Gson().toJson(
                        BaseResponse(
                            funcName = "onRegisterCallback",
                            isRegister = false,
                            remoteAddress = ""
                        )
                    )
                )
            } else if (state == RegistrationState.Ok) {
                eventSink?.success(
                    Gson().toJson(
                        BaseResponse(
                            funcName = "onRegisterCallback",
                            isRegister = true,
                            remoteAddress = ""
                        )
                    )
                )
            }
        }

        override fun onCallStateChanged(
            core: Core,
            call: Call,
            state: Call.State?,
            message: String
        ) {
            // This function will be called each time a call state changes,
            // which includes new incoming/outgoing calls
//            findViewById<TextView>(R.id.call_status).text = message

            when (state) {
                Call.State.OutgoingInit -> {
                    // First state an outgoing call will go through
                }

                Call.State.OutgoingProgress -> {
                    // Right after outgoing init
                    eventSink?.success(
                        Gson().toJson(
                            BaseResponse(
                                funcName = "onOutgoingProgress",
                                isRegister = true,
                                remoteAddress = call.remoteAddress.asStringUriOnly()
                            )
                        )
                    )

                }

                Call.State.OutgoingRinging -> {
                    // This state will be reached upon reception of the 180 RINGING
                }

                Call.State.IncomingReceived -> {
                    eventSink?.success(
                        Gson().toJson(
                            BaseResponse(
                                funcName = "onIncomingReceived",
                                isRegister = true,
                                remoteAddress = call.remoteAddress.asStringUriOnly()
                            )
                        )
                    )
                }

                Call.State.Connected -> {
                    eventSink?.success(
                        Gson().toJson(
                            BaseResponse(
                                funcName = "onConnected",
                                isRegister = true,
                                remoteAddress = call.remoteAddress.asStringUriOnly()
                            )
                        )
                    )
                    // Handler(Looper.getMainLooper()).postDelayed({
                    //     toggleVideo()
                    // }, 1000)
                }

                Call.State.StreamsRunning -> {
                }

                Call.State.Paused -> {
                }

                Call.State.PausedByRemote -> {
                    // When the remote end of the call pauses it, it will be PausedByRemote
                }

                Call.State.Updating -> {
                    // When we request a call update, for example when toggling video
                }

                Call.State.UpdatedByRemote -> {
                    // When the remote requests a call update
                }

                Call.State.Released, Call.State.Error -> {
                    eventSink?.success(
                        Gson().toJson(
                            BaseResponse(
                                funcName = "onReleased",
                                isRegister = true,
                                remoteAddress = ""
                            )
                        )
                    )
                }

                Call.State.Idle -> {}
                Call.State.PushIncomingReceived -> {}
                Call.State.OutgoingEarlyMedia -> {}
                Call.State.Pausing -> {}
                Call.State.Resuming -> {}
                Call.State.Referred -> {}
                Call.State.End -> {}
                Call.State.IncomingEarlyMedia -> {}
                Call.State.EarlyUpdatedByRemote -> {}
                Call.State.EarlyUpdating -> {}
                null -> {}
            }
        }
    }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
     val factory = Factory.instance()
        factory.setDebugMode(true, "Hello Linphone")
        core = factory.createCore(null, null, flutterPluginBinding.applicationContext)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, methodChannel)
        channel.setMethodCallHandler(this)
        messageChannel = EventChannel(flutterPluginBinding.binaryMessenger, eventChannel)
        messageChannel?.setStreamHandler(this)
        
        flutterPluginBinding
    .platformViewRegistry.registerViewFactory(
            "android_native_view_integration",
            LinPhoneFactory(
                core = core, coreListener = coreListener,
            )
        )
  }


    //
    private fun login(username: String, password: String, domain: String) {
        val authInfo =
            Factory.instance().createAuthInfo(username, null, password, null, null, domain, null)
        val params = core.createAccountParams()
        val identity = Factory.instance().createAddress("sip:$username@$domain")
        params.identityAddress = identity
        val address = Factory.instance().createAddress("sip:$domain")
        address?.transport = TransportType.Tcp
        params.serverAddress = address
        params.isRegisterEnabled = true


        val account = core.createAccount(params)
        core.addAuthInfo(authInfo)
        core.addAccount(account)

        // ✅ cấu hình policy video trước khi start
    val videoPolicy = Factory.instance().createVideoActivationPolicy()
    videoPolicy.automaticallyAccept = true
    videoPolicy.automaticallyInitiate = true
    core.videoActivationPolicy = videoPolicy

        // Asks the CaptureTextureView to resize to match the captured video's size ratio
        core.config.setBool("video", "auto_resize_preview_to_keep_ratio", true)

        core.defaultAccount = account
        core.addListener(coreListener)
        core.start()

        // // We will need the RECORD_AUDIO permission for video call
        // if (packageManager.checkPermission(
        //         Manifest.permission.RECORD_AUDIO,
        //         packageName
        //     ) != PackageManager.PERMISSION_GRANTED
        // ) {
        //     requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 0)
        //     return
        // }
    }

    private fun toggleSpeaker() {
        // Get the currently used audio device
        val currentAudioDevice = core.currentCall?.outputAudioDevice
        val speakerEnabled = currentAudioDevice?.type == AudioDevice.Type.Speaker

        // We can get a list of all available audio devices using
        // Note that on tablets for example, there may be no Earpiece device
        for (audioDevice in core.audioDevices) {
            if (speakerEnabled && audioDevice.type == AudioDevice.Type.Earpiece) {
                core.currentCall?.outputAudioDevice = audioDevice
                return
            } else if (!speakerEnabled && audioDevice.type == AudioDevice.Type.Speaker) {
                core.currentCall?.outputAudioDevice = audioDevice
                return
            }/* If we wanted to route the audio to a bluetooth headset
            else if (audioDevice.type == AudioDevice.Type.Bluetooth) {
                core.currentCall?.outputAudioDevice = audioDevice
            }*/
        }
    }

    private fun outgoingCall(remoteSipUri: String) {
        // As for everything we need to get the SIP URI of the remote and convert it to an Address
//        val remoteSipUri = findViewById<EditText>(R.id.remote_address).text.toString()
        val remoteAddress = Factory.instance().createAddress("sip:$remoteSipUri@$domain")
        remoteAddress
            ?: return // If address parsing fails, we can't continue with outgoing call process
        // We also need a CallParams object
        // Create call params expects a Call object for incoming calls, but for outgoing we must use null safely
        val params = core.createCallParams(null)
        params ?: return // Same for params

        // We can now configure it
        // Here we ask for no encryption but we could ask for ZRTP/SRTP/DTLS
        params.mediaEncryption = MediaEncryption.None
        // If we wanted to start the call with video directly
        //params.enableVideo(true)

        // Finally we start the call
        core.inviteAddressWithParams(remoteAddress, params)
        // Call process can be followed in onCallStateChanged callback from core listener
    }

    //
    private fun hangUp() {
        if (core.callsNb == 0) return
        // If the call state isn't paused, we can get it using core.currentCall
        val call = if (core.currentCall != null) core.currentCall else core.calls[0]
        call ?: return

        // Terminating a call is quite simple
        call.terminate()
    }

    //
    private fun toggleVideo() {
        if (core.callsNb == 0) return
        val call = if (core.currentCall != null) core.currentCall else core.calls[0]
        call ?: return

        // We will need the CAMERA permission for video call
        // if (packageManager.checkPermission(
        //         Manifest.permission.CAMERA,
        //         packageName
        //     ) != PackageManager.PERMISSION_GRANTED
        // ) {
        //     requestPermissions(arrayOf(Manifest.permission.CAMERA), 0)
        //     return
        // }

        // To update the call, we need to create a new call params, from the call object this time
        val params = core.createCallParams(call)
        params?.isVideoEnabled = !call.currentParams.isVideoEnabled
        call.update(params)
    }

    //
    private fun toggleCamera() {
        // Currently used camera
        val currentDevice = core.videoDevice

        // Let's iterate over all camera available and choose another one
        for (camera in core.videoDevicesList) {
            // All devices will have a "Static picture" fake camera, and we don't want to use it
            if (camera != currentDevice && camera != "StaticImage: Static picture") {
                core.videoDevice = camera
                break
            }
        }
    }

    private fun pauseOrResume() {
        if (core.callsNb == 0) return
        val call = if (core.currentCall != null) core.currentCall else core.calls[0]
        call ?: return

        if (call.state != Call.State.Paused && call.state != Call.State.Pausing) {
            // If our call isn't paused, let's pause it
            call.pause()
        } else if (call.state != Call.State.Resuming) {
            // Otherwise let's resume it
            call.resume()
        }
    }

    fun acceptVideoCall() {
    core.currentCall?.let { call ->
        val params = core.createCallParams(call)
        params?.isVideoEnabled = true   // ✅ thay enableVideo(true)
        params?.isAudioEnabled = true
        call.acceptWithParams(params)
    }
}

 override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "register" -> {
                val userName = call.argument<String>("user_name")
                val password = call.argument<String>("password")
                val domain = call.argument<String>("domain")

                if (userName != null && password != null && domain != null) {
                    this.domain = domain
                    login(username = userName, password = password, domain = domain)
                }
            }

            "make_call" -> {
                val remoteSipUri = call.argument<String>("dest")
                remoteSipUri?.let { outgoingCall(remoteSipUri = it) }
            }

            "accept_call" -> {
                acceptVideoCall()
            }

            "terminate_call" -> {
                hangUp()
            }

            "switch_camera" -> {
                toggleCamera()
            }

            "toggle_speaker" -> {
                toggleSpeaker()
            }


            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
