

import SwiftUI
import Flutter
import linphonesw


class LinPhoneFactory: NSObject, FlutterPlatformViewFactory {
  private var messenger: FlutterBinaryMessenger
private var linPhoneController: LinPhoneController

  init(messenger: FlutterBinaryMessenger,linPhoneController:LinPhoneController) {
    self.messenger = messenger
    self.linPhoneController = linPhoneController
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
    
  ) -> FlutterPlatformView {
    let channel = FlutterMethodChannel(name: "login_channel", binaryMessenger: messenger)

      return LinPhoneWrapper(
                  frame: frame,
                  viewIdentifier: viewId,
                  arguments: args,
                  binaryMessenger: messenger,
                  linPhoneController:self.linPhoneController)
  }
}


class LinPhoneWrapper: NSObject, FlutterPlatformView {
  private var _view: UIView

    init(
          frame: CGRect,
          viewIdentifier viewId: Int64,
          arguments args: Any?,
          binaryMessenger messenger: FlutterBinaryMessenger?,
          linPhoneController:LinPhoneController
      ) {
         
          _view = UIView()
          super.init()
          createNativeView(view: _view,linPhoneController:linPhoneController)
      }

      func view() -> UIView {
          return _view
      }

      func createNativeView(view _view: UIView,linPhoneController:LinPhoneController){

              let keyWindows = UIApplication.shared.windows.first(where: { $0.isKeyWindow}) ?? UIApplication.shared.windows.first
              let topController = keyWindows?.rootViewController
        //   let vc = UIHostingController(rootView: PlayerView(doSomething: self.doSomething))
        let vc = UIHostingController(rootView: LinPhoneView(linPhoneController:linPhoneController))
              let swiftUiView = vc.view!
              swiftUiView.translatesAutoresizingMaskIntoConstraints = false
              topController?.addChild(vc)
              _view.addSubview(swiftUiView)
              NSLayoutConstraint.activate(
                  [
                      swiftUiView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                      swiftUiView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                      swiftUiView.topAnchor.constraint(equalTo: _view.topAnchor),
                      swiftUiView.bottomAnchor.constraint(equalTo:  _view.bottomAnchor)
                  ])

              vc.didMove(toParent: topController)
          }
    
    func doSomething() {
            print("do something")
        }
}




struct LinPhoneView: View {
    
    @ObservedObject var linPhoneController : LinPhoneController
    
    func callStateString() -> String {
        if (linPhoneController.isCallRunning) {
            return "Call running"
        } else {
            return "No Call"
        }
    }
    
    var body: some View {
        
        ZStack(alignment: .topTrailing){
            //UI ongoing call.
            if(linPhoneController.loggedIn == true &&  linPhoneController.isCallRunning == true){
                
                ZStack(alignment: .top){
                    Text("\(linPhoneController.remoteAddress)")
                        .font(.title)
                    
                    VStack(spacing: 10){
                        LinphoneVideoViewHolder() { view in
                            self.linPhoneController.mCore.nativeVideoWindow = view
                        }
                        .background(Color.gray.opacity(0.1))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .center)
                     
                    
                    VStack(spacing: 10){
                        // My camera preview
                        LinphoneVideoViewHolder() { view in
                            self.linPhoneController.mCore.nativePreviewWindow = view
                        }
                        .frame(width: 120, height: 160.0)
//                        .background(Color.gray.opacity(0.5))
                        .padding(.leading)
                        
                    }.frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .topTrailing)
                        .padding(.top,10)
                        .padding(.trailing,10)
                    
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LinPhoneView(linPhoneController: LinPhoneController())
    }
}
