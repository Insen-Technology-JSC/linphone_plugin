package com.genki.linphone.linphone_plugin

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import com.genki.linphone.linphone_plugin.R
import org.linphone.core.Core
import org.linphone.core.CoreListenerStub

class LinPhoneFactory(
                      private val core: Core,
                      private val coreListener : CoreListenerStub,
                      private val onHangUp: (()->Unit),
                      private val onPauseOrResume: (()->Unit),
                      private val onToggleVideo: (()->Unit),
                      private val onToggleCamera: (()->Unit),
                      private val onToggleSpeaker: (()->Unit),
    ) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, o: Any?): PlatformView {
        return LinPhoneWidget(context = context,
            id = id,
            core = core,
            coreListener = coreListener,
            onHangUp=onHangUp,
            onPauseOrResume=onPauseOrResume,
            onToggleVideo=onToggleVideo,
            onToggleCamera=onToggleCamera,
            onToggleSpeaker=onToggleSpeaker
            )
    }
}

class LinPhoneWidget internal constructor(context: Context, id: Int,
                                          core: Core, coreListener : CoreListenerStub,
                                          onHangUp: (()->Unit),
                                          onPauseOrResume: (()->Unit),
                                          onToggleVideo: (()->Unit)
                                          ,onToggleCamera: (()->Unit)
                                          ,onToggleSpeaker: (()->Unit)) : PlatformView {
    private val view: View
    private val core: Core
    private val coreListener : CoreListenerStub
    override fun getView(): View {
        return view
    }

    init {
        view = LayoutInflater.from(context).inflate(R.layout.linphone_widget, null)
        this.core = core
        this.coreListener = coreListener
        this.core.nativeVideoWindowId =view.findViewById(R.id.remote_video_surface)
        this.core.nativePreviewWindowId = view.findViewById(R.id.local_preview_video_surface)
    }

    override fun dispose() {
    }
}