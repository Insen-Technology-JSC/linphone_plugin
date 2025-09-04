package com.genki.linphone.linphone_plugin
import io.flutter.embedding.engine.plugins.FlutterPlugin
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
  
  
    private val eventChannel = "com.insentecs.linphone/event_channel"
    private val methodChannel = "com.insentecs.linphone/method_channel"
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

    private lateinit var core: Core
    private val coreListener = object : CoreListenerStub() {
        override fun onAccountRegistrationStateChanged(
            core: Core,
            account: Account,
            state: RegistrationState?,
            message: String
        ) {
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
        val params = call.currentParams
        val isVideo: Boolean = params.isVideoEnabled
        when (state) {
            Call.State.OutgoingInit -> {
            }
            Call.State.OutgoingProgress -> {
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
            }

            Call.State.StreamsRunning -> {
            }

            Call.State.Paused -> {
            }

            Call.State.PausedByRemote -> {
            }

            Call.State.Updating -> {
            }

            Call.State.UpdatedByRemote -> {
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
        core.isPushNotificationEnabled = true
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

    private fun login(username: String, password: String, domain: String,fbProjectId : String,hubId : String) {
        val authInfo =
            Factory.instance().createAuthInfo(username, null, password, null, null, domain, null)
        val params = core.createAccountParams()
        val identity = Factory.instance().createAddress("sip:$username@$domain")
        params.identityAddress = identity
        val address = Factory.instance().createAddress("sip:$domain")
        address?.transport = TransportType.Tcp
        params.serverAddress = address
        params.isRegisterEnabled = true
        val push = core.pushNotificationConfig
         val editableConfig = push?.clone()
        editableConfig?.param = "$fbProjectId"
        editableConfig?.provider = "fcm"
        editableConfig?.prid = "$hubId"
        params.pushNotificationAllowed = true
        params.remotePushNotificationAllowed = true
        if (editableConfig != null) {
            params.pushNotificationConfig = editableConfig
        }
        val account = core.createAccount(params)
        core.addAuthInfo(authInfo)
        core.addAccount(account)
        val videoPolicy = Factory.instance().createVideoActivationPolicy()
        videoPolicy.automaticallyAccept = true
        videoPolicy.automaticallyInitiate = true
        core.videoActivationPolicy = videoPolicy
        core.config.setBool("video", "auto_resize_preview_to_keep_ratio", true)
        core.defaultAccount = account
        core.addListener(coreListener)
        core.start()
    }

    private fun toggleSpeaker() {
        val currentAudioDevice = core.currentCall?.outputAudioDevice
        val speakerEnabled = currentAudioDevice?.type == AudioDevice.Type.Speaker
        for (audioDevice in core.audioDevices) {
            if (speakerEnabled && audioDevice.type == AudioDevice.Type.Earpiece) {
                core.currentCall?.outputAudioDevice = audioDevice
                return
            } else if (!speakerEnabled && audioDevice.type == AudioDevice.Type.Speaker) {
                core.currentCall?.outputAudioDevice = audioDevice
                return
            }
        }
    }

    private fun outgoingCall(remoteSipUri: String) {
        val remoteAddress = Factory.instance().createAddress("sip:$remoteSipUri@$domain")
        remoteAddress
            ?: return
        val params = core.createCallParams(null)
        params ?: return // Same for params
        params.mediaEncryption = MediaEncryption.None
        core.inviteAddressWithParams(remoteAddress, params)
    }

    //
    private fun hangUp() {
        if (core.callsNb == 0) return
        val call = if (core.currentCall != null) core.currentCall else core.calls[0]
        call ?: return
        call.terminate()
    }

    //
    private fun toggleVideo() {
        if (core.callsNb == 0) return
        val call = if (core.currentCall != null) core.currentCall else core.calls[0]
        call ?: return
        val params = core.createCallParams(call)
        params?.isVideoEnabled = !call.currentParams.isVideoEnabled
        call.update(params)
    }

    //
    private fun toggleCamera() {
        val currentDevice = core.videoDevice
        for (camera in core.videoDevicesList) {
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
            call.pause()
        } else if (call.state != Call.State.Resuming) {
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
                val fbProjectId = call.argument<String>("fb_project_id")
                val hubId = call.argument<String>("hub_id")

                if (userName != null && password != null && domain != null && fbProjectId != null && hubId != null) {
                    this.domain = domain
                    login(username = userName, password = password, domain = domain,fbProjectId = fbProjectId,hubId = hubId)
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
