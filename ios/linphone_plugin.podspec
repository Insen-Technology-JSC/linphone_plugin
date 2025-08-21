Pod::Spec.new do |s|
  s.name             = 'linphone_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*','linphone-sdk/include/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.dependency 'linphone-sdk', '~> 5.2.114' 
  # s.dependency 'linphone-sdk', '~> 5.3.0' 
  s.pod_target_xcconfig = {
   'DEFINES_MODULE' => 'YES',
   'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386', 
   'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
   'CLANG_CXX_LIBRARY' => 'libc++'
  }
  s.compiler_flags = '-std=c++17'
  s.swift_version = '5.0'
end
