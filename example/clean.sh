rm -rf ios/Pods
rm -rf ios/Runner.xcworkspace
rm -rf ios/Runner.xcodeproj/xcuserdata
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/*
flutter pub cache clean || true
flutter pub get
cd ios
pod deintegrate
pod cache clean --all
pod install --repo-update
cd ..