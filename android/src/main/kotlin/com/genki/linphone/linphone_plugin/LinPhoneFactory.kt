package com.genki.linphone.linphone_plugin

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import android.view.LayoutInflater
import android.view.TextureView
import android.view.View
import com.genki.linphone.linphone_plugin.R
import org.linphone.core.Call
import org.linphone.core.Core
import org.linphone.core.CoreListenerStub
import org.linphone.mediastream.video.capture.CaptureTextureView

class LinPhoneFactory(
                      private val core: Core,
                      private val coreListener : CoreListenerStub,
    ) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, o: Any?): PlatformView {
        return LinPhoneWidget(context = context,
            id = id,
            core = core,
            coreListener = coreListener,
            )
    }
}

class LinPhoneWidget internal constructor(context: Context, id: Int,
                                          private val core: Core, coreListener : CoreListenerStub,
                                         ) : PlatformView,CoreListenerStub() {
    private val view: View = LayoutInflater.from(context).inflate(R.layout.linphone_widget, null)
    private val remoteVideoView: TextureView = view.findViewById(R.id.remote_video_surface)
    private val localPreviewView: CaptureTextureView = view.findViewById(R.id.local_preview_video_surface)

    override fun getView(): View {
        return view
    }

    init {
        core.addListener(this)
        println("✅ LinPhoneWidget listener added")
        core.nativeVideoWindowId =this.remoteVideoView
        core.nativePreviewWindowId = this.localPreviewView
    }
    override fun dispose() {
        core.removeListener(this)
    }
    override fun onCallStateChanged(core: Core, call: Call, state: Call.State, message: String) {
        print("LinPhoneWidget, onCallStateChanged_state:$state");
        if (state == Call.State.StreamsRunning) {
            core.nativeVideoWindowId = remoteVideoView
            core.nativePreviewWindowId = localPreviewView
        }
    }
}