
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
    @Published var fbProjectId : String = ""
     @Published var hubId : String = ""
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
    
func initCore(onRegisterCallback: @escaping (Bool) -> Void,
              onIncomingReceived: @escaping (String) -> Void,
              onReleased: @escaping () -> Void,
              onConnected: @escaping (String) -> Void,
              onOutgoingProgress: @escaping (String) -> Void
)
    {
        LoggingService.Instance.logLevel = LogLevel.Debug
        try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
        if let nat = try? mCore.createNatPolicy() {
                nat.iceEnabled = true
                nat.stunEnabled = true
                nat.stunServer = "stun.linphone.org"
                mCore.natPolicy = nat
            }

        mCore.videoCaptureEnabled = true
        mCore.videoDisplayEnabled = true
        mCore.videoActivationPolicy!.automaticallyAccept = true
        mCore.videoActivationPolicy!.automaticallyInitiate = true
        mCore.pushNotificationEnabled = true
        try? mCore.start()

        mCoreDelegate = CoreDelegateStub( onCallStateChanged: { (core: Core, call: Call, state: Call.State, message: String) in
            self.callMsg = message
            if (state == .OutgoingInit) {
                NSLog("OutgoingCallTutorialContext, OutgoingInit.....")
            } else if (state == .OutgoingProgress) {
                NSLog("OutgoingCallTutorialContext, OutgoingProgress.....")
                let newRemoteAddress  = "sip:\(self.remoteAddress)@\(self.domain)"
                onOutgoingProgress(newRemoteAddress)
            }
            else if (state == .OutgoingEarlyMedia) {
                NSLog("OutgoingCallTutorialContext, OutgoingEarlyMedia.....")
            }else if (state == .OutgoingRinging) {
                NSLog("OutgoingCallTutorialContext, OutgoingRinging.....")
            } else if (state == .StreamsRunning) {
                self.isCallRunning = true
                self.isMicrophoneEnabled = true
                core.micEnabled = true
                if let speaker = core.audioDevices.first(where: { $0.type == .Speaker }) {
                    call.outputAudioDevice = speaker
                }    
                self.canChangeCamera = core.videoDevicesList.count > 2
            } else if (state == .Paused) {
                self.canChangeCamera = false
            } else if (state == .PausedByRemote) {
            } else if (state == .Updating) {
                NSLog("OutgoingCallTutorialContext, Updating.....")
            } else if (state == .UpdatedByRemote) {
                NSLog("OutgoingCallTutorialContext, UpdatedByRemote.....")
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
                onConnected(self.remoteAddress)
            } else if (state == .Released || state == .Error) { // When a call is over
                self.isCallIncoming = false
                self.isCallRunning = false
                self.remoteAddress = ""
                self.canChangeCamera = false
                onReleased()
            }
        }, onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
            NSLog("New registration state is \(state) for user id \( String(describing: account.params))\n")
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
            accountParams.natPolicy = mCore.natPolicy 
            accountParams.avpfMode = .Enabled
            accountParams.expires = 1209600
            accountParams.avpfRrInterval = 5
            if let push = mCore.pushNotificationConfig {
            push.provider = "fcm"
            push.param = String(fbProjectId)
            
            push.prid = "genki" 
            // push.prid = String(hubId)

            accountParams.pushNotificationConfig = push
            accountParams.pushNotificationAllowed = true   // BẮT BUỘC
            accountParams.remotePushNotificationAllowed = true
            print("⚠️ set_push_notification")
            } else {
                print("⚠️ failed_to_set_push_notification")
            }
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
            var newRemoteAddress: String =  "sip:\(remoteAddress)@\(domain)"
            if remoteAddress.contains("sip") {
             newRemoteAddress =   remoteAddress
            }
            let remoteAddress = try Factory.Instance.createAddress(addr: newRemoteAddress)
            let params = try mCore.createCallParams(call: nil)
            params.mediaEncryption = MediaEncryption.None
            params.videoEnabled = true
            let _ = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
        } catch { NSLog(error.localizedDescription) }
        
    }
    
    func acceptCall() {
    do {
        if let call = mCore.currentCall {
            let params = try mCore.createCallParams(call: call)
            params.audioEnabled = true
            params.videoEnabled = true
            if let videoPolicy = mCore.videoActivationPolicy {
                videoPolicy.automaticallyAccept = true
                videoPolicy.automaticallyInitiate = true
            }
            mCore.videoCaptureEnabled = true
            mCore.videoDisplayEnabled = true
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
            let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
            if let call = coreCall {
                try call.terminate()
            }
        } catch { NSLog(error.localizedDescription) }
    }
    
    func toggleVideo() {
        do {
            if (mCore.callsNb == 0) { return }
            let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
            if let call = coreCall {
                let params = try mCore.createCallParams(call: call)
                params.videoEnabled = !(call.currentParams!.videoEnabled)
                isVideoEnabled = params.videoEnabled
                try call.update(params: params)
            }
        } catch { NSLog(error.localizedDescription) }
    }
    
    func toggleCamera() {
        do {
            let currentDevice = mCore.videoDevice
            for camera in mCore.videoDevicesList {
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
                    try call.pause()
                } else if (call.state != Call.State.Resuming) {
                    try call.resume()
                }
            }
        } catch { NSLog(error.localizedDescription) }
    }
}
