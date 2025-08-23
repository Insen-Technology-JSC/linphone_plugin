
import linphonesw

class LinPhoneController : ObservableObject
{
    var mCore: Core!
    @Published var coreVersion: String = Core.getVersion
    
    var mAccount: Account?
    var mCoreDelegate : CoreDelegate!
    @Published var username : String = "7000"
    @Published var passwd : String = "7000"
    @Published var domain : String = "10.10.1.100"
    @Published var loggedIn: Bool = false//for test default false
   
    // Outgoing call related variables
    @Published var callMsg : String = ""
    @Published var isCallRunning : Bool = false //for test default false
    @Published var isVideoEnabled : Bool = false
    @Published var canChangeCamera : Bool = false
    @Published var remoteAddress : String = "7100" ///sip:7100@10.10.1.100
    @Published var isCallIncoming : Bool = false
    @Published var isSpeakerEnabled : Bool = false
    @Published var isMicrophoneEnabled : Bool = false
    
    
    // callback
//    private var doSomething : ()->()
//    var onEmit: (Bool) -> Void
    //completion: @escaping (Result<Data, Error>) -> Void
func initCore(onRegisterCallback: @escaping (Bool) -> Void,
              onIncomingReceived: @escaping (String) -> Void,
              onReleased: @escaping () -> Void,
              onConnected: @escaping (String) -> Void,
              onOutgoingProgress: @escaping (String) -> Void
)
    {
        LoggingService.Instance.logLevel = LogLevel.Warning
        
        try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
        
        if let nat = try? mCore.createNatPolicy() {
    nat.iceEnabled = true
    nat.stunEnabled = true
    nat.stunServer = "stun.linphone.org"
    mCore.natPolicy = nat
}

        // Here we enable the video capture & display at Core level
        // It doesn't mean calls will be made with video automatically,
        // But it allows to use it later
        mCore.videoCaptureEnabled = true
        mCore.videoDisplayEnabled = true
        // When enabling the video, the remote will either automatically answer the update request
        // or it will ask it's user depending on it's policy.
        // Here we have configured the policy to always automatically accept video requests
        mCore.videoActivationPolicy!.automaticallyAccept = true
        // If you don't want to automatically accept,
        // you'll have to use a code similar to the one in toggleVideo to answer a received request
        

        // If the following property is enabled, it will automatically configure created call params with video enabled
        mCore.videoActivationPolicy!.automaticallyInitiate = true
        
        try? mCore.start()
        
        mCoreDelegate = CoreDelegateStub( onCallStateChanged: { (core: Core, call: Call, state: Call.State, message: String) in
            // This function will be called each time a call state changes,
            // which includes new incoming/outgoing calls
            self.callMsg = message
                //OutgoingEarlyMedia
            if (state == .OutgoingInit) {
                NSLog("OutgoingCallTutorialContext, OutgoingInit.....")
                // First state an outgoing call will go through
            } else if (state == .OutgoingProgress) {
                // Right after outgoing init
                NSLog("OutgoingCallTutorialContext, OutgoingProgress.....")
                let newRemoteAddress  = "sip:\(self.remoteAddress)@\(self.domain)"
                onOutgoingProgress(newRemoteAddress)
            }
            else if (state == .OutgoingEarlyMedia) {
                // Right after outgoing init
                NSLog("OutgoingCallTutorialContext, OutgoingEarlyMedia.....")
            }else if (state == .OutgoingRinging) {
                NSLog("OutgoingCallTutorialContext, OutgoingRinging.....")
              
                // This state will be reached upon reception of the 180 RINGING
            } else if (state == .StreamsRunning) {
                // This state indicates the call is active.
                // You may reach this state multiple times, for example after a pause/resume
                // or after the ICE negotiation completes
                // Wait for the call to be connected before allowing a call update
                self.isCallRunning = true

                 self.isMicrophoneEnabled = true
    core.micEnabled = true
    if let speaker = core.audioDevices.first(where: { $0.type == .Speaker }) {
        call.outputAudioDevice = speaker
    }    

                // Only enable toggle camera button if there is more than 1 camera
                // We check if core.videoDevicesList.size > 2 because of the fake camera with static image created by our SDK (see below)
                self.canChangeCamera = core.videoDevicesList.count > 2
            } else if (state == .Paused) {
                // When you put a call in pause, it will became Paused
                self.canChangeCamera = false
            } else if (state == .PausedByRemote) {
                // When the remote end of the call pauses it, it will be PausedByRemote
            } else if (state == .Updating) {
                NSLog("OutgoingCallTutorialContext, Updating.....")
                // When we request a call update, for example when toggling video
            } else if (state == .UpdatedByRemote) {
                NSLog("OutgoingCallTutorialContext, UpdatedByRemote.....")
                // When the remote requests a call update
            }else if (state == .IncomingReceived) { // When a call is received

                 if let remoteParams = call.remoteParams {
            if remoteParams.videoEnabled {
                NSLog("📹 Incoming call WITH VIDEO offer")
            } else {
                NSLog("🎧 Incoming call AUDIO only")
            }
        } else {
            NSLog("⚠️ No remoteParams found")
        }

                self.isCallIncoming = true
                self.isCallRunning = false
                self.remoteAddress = call.remoteAddress!.asStringUriOnly()
                onIncomingReceived(self.remoteAddress)
            } else if (state == .Connected) { // When a call is over
               
                if let currentParams = call.currentParams {
            if currentParams.videoEnabled {
                NSLog("✅ Connected with VIDEO")
            } else {
                NSLog("✅ Connected with AUDIO only")
            }
        }

                self.isCallIncoming = false
                self.isCallRunning = true
                // Enable accept video call
                onConnected(self.remoteAddress)
            } else if (state == .Released || state == .Error) { // When a call is over
                self.isCallIncoming = false
                self.isCallRunning = false
                self.remoteAddress = ""
                self.canChangeCamera = false
                onReleased()
            }
        }, onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
            NSLog("New registration state is \(state) for user id \( String(describing: account.params?.identityAddress?.asString()))\n")
            if (state == .Ok) {
                onRegisterCallback(true)
                self.loggedIn = true
            } else if (state == .Cleared) {
                self.loggedIn = false
                onRegisterCallback(false)
            }
        })
        mCore.addDelegate(delegate: mCoreDelegate)
    }

    
    func muteMicrophone() {
        mCore.micEnabled = !mCore.micEnabled
        isMicrophoneEnabled = !isMicrophoneEnabled
    }
    
  
    
    func toggleSpeaker() {
    guard let call = mCore.currentCall else {
        NSLog("⚠️ No active call to toggle speaker")
        return
    }
    
    let currentAudioDevice = call.outputAudioDevice
    let speakerEnabled = currentAudioDevice?.type == AudioDevice.Kind.Speaker
    
    for audioDevice in mCore.audioDevices {
        if speakerEnabled && audioDevice.type == .Microphone {
            call.outputAudioDevice = audioDevice
            isSpeakerEnabled = false
            NSLog("🔈 Switched to Earpiece")
            return
        } else if !speakerEnabled && audioDevice.type == .Speaker {
            call.outputAudioDevice = audioDevice
            isSpeakerEnabled = true
            NSLog("🔊 Switched to Speaker")
            return
        }
        // Bluetooth sample
        // else if audioDevice.type == .Bluetooth {
        //     call.outputAudioDevice = audioDevice
        // }
    }
}

    
    func login() {
        
        do {
            let transport = TransportType.Tcp
            let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: "", passwd: passwd, ha1: "", realm: "", domain: domain)
            
            let accountParams = try mCore.createAccountParams()
            let identity = try Factory.Instance.createAddress(addr: String("sip:" + username + "@" + domain))
            try! accountParams.setIdentityaddress(newValue: identity)
            let address = try Factory.Instance.createAddress(addr: String("sip:" + domain))
            try address.setTransport(newValue: transport)
            try accountParams.setServeraddress(newValue: address)
            // 🔑 quan trọng: gán NAT policy cho account

            accountParams.natPolicy = mCore.natPolicy 
            // 🔑 Bật AVPF
            // accountParams.avpfMode = AVPFMode.enabled
        //  accountParams.avpfMode = AVPFMode.Default
         accountParams.avpfMode = .Enabled
accountParams.avpfRrInterval = 5
            // Enable register
            accountParams.registerEnabled = true

            mAccount = try mCore.createAccount(params: accountParams)
            mCore.addAuthInfo(info: authInfo)
            try mCore.addAccount(account: mAccount!)
            mCore.defaultAccount = mAccount

            
        } catch { NSLog(error.localizedDescription) }
    }
    
    
    func unregister()
    {
        if let account = mCore.defaultAccount {
            let params = account.params
            let clonedParams = params?.clone()
            clonedParams?.registerEnabled = false
            account.params = clonedParams
        }
    }
    func delete() {
        if let account = mCore.defaultAccount {
            mCore.removeAccount(account: account)
            mCore.clearAccounts()
            mCore.clearAllAuthInfo()
        }
    }
    
    func outgoingCall() {
        do {
            NSLog("OutgoingCallTutorialContext, Outgoing call.....\(remoteAddress)")
            let newRemoteAddress  = "sip:\(remoteAddress)@\(domain)"
            // As for everything we need to get the SIP URI of the remote and convert it to an Address
            let remoteAddress = try Factory.Instance.createAddress(addr: newRemoteAddress)
            
            // We also need a CallParams object
            // Create call params expects a Call object for incoming calls, but for outgoing we must use null safely
            let params = try mCore.createCallParams(call: nil)
            
            // We can now configure it
            // Here we ask for no encryption but we could ask for ZRTP/SRTP/DTLS
            params.mediaEncryption = MediaEncryption.None
            
//            //Todo test force call video.
//            params.videoEnabled = true // Todo for test
//            isVideoEnabled = params.videoEnabled
//            //End todo test force call video.
          
            // If we wanted to start the call with video directly
           params.videoEnabled = true
            
            // Finally we start the call
            let _ = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
            // Call process can be followed in onCallStateChanged callback from core listener
        } catch { NSLog(error.localizedDescription) }
        
    }
    
    func acceptCall() {
    do {
        if let call = mCore.currentCall {
            // 🔧 Tạo CallParams cho cuộc gọi hiện tại
            let params = try mCore.createCallParams(call: call)

            // 🔑 Force bật audio + video
            params.audioEnabled = true
            params.videoEnabled = true

            // 🔑 Bật video policy từ Core (luôn luôn bật video)
            if let videoPolicy = mCore.videoActivationPolicy {
                videoPolicy.automaticallyAccept = true
                videoPolicy.automaticallyInitiate = true
            }

            // 🔑 Bật video capture & display
            mCore.videoCaptureEnabled = true
            mCore.videoDisplayEnabled = true

            // ✅ Accept call với params đã set
            try call.acceptWithParams(params: params)
            NSLog("Accepting call with forced video...")
        }
    } catch {
        NSLog("acceptCall error: \(error.localizedDescription)")
    }
}

    
    func terminateCall() {
        do {
            if (mCore.callsNb == 0) { return }
            
            // If the call state isn't paused, we can get it using core.currentCall
            let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
            
            // Terminating a call is quite simple
            if let call = coreCall {
                try call.terminate()
            }
        } catch { NSLog(error.localizedDescription) }
    }
    
    func toggleVideo() {
        do {
            if (mCore.callsNb == 0) { return }
            let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
            // We will need the CAMERA permission for video call
            
            if let call = coreCall {
                // To update the call, we need to create a new call params, from the call object this time
                let params = try mCore.createCallParams(call: call)
                // Here we toggle the video state (disable it if enabled, enable it if disabled)
                // Note that we are using currentParams and not params or remoteParams
                // params is the object you configured when the call was started
                // remote params is the same but for the remote
                // current params is the real params of the call, resulting of the mix of local & remote params
                params.videoEnabled = !(call.currentParams!.videoEnabled)
                isVideoEnabled = params.videoEnabled
                // Finally we request the call update
                try call.update(params: params)
                // Note that when toggling off the video, TextureViews will keep showing the latest frame displayed
            }
        } catch { NSLog(error.localizedDescription) }
    }
    
    func toggleCamera() {
        do {
            // Currently used camera
            let currentDevice = mCore.videoDevice
            
            // Let's iterate over all camera available and choose another one
            for camera in mCore.videoDevicesList {
                // All devices will have a "Static picture" fake camera, and we don't want to use it
                if (camera != currentDevice && camera != "StaticImage: Static picture") {
                    try mCore.setVideodevice(newValue: camera)
                    break
                }
            }
        } catch { NSLog(error.localizedDescription) }
    }
    
    func pauseOrResume() {
        do {
            if (mCore.callsNb == 0) { return }
            let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
            
            if let call = coreCall {
                if (call.state != Call.State.Paused && call.state != Call.State.Pausing) {
                    // If our call isn't paused, let's pause it
                    try call.pause()
                } else if (call.state != Call.State.Resuming) {
                    // Otherwise let's resume it
                    try call.resume()
                }
            }
        } catch { NSLog(error.localizedDescription) }
    }
}
