platform :ios, '17.2'

target 'WoolWallet' do
  use_frameworks!

  # Pods for WoolWallet
  pod 'OpenCV2'
  pod 'Sweetercolor', :git => 'https://github.com/lwerner18/Sweetercolor.git'
  pod 'UIImageColors'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '5.0'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.2'
      end
    end

    # OpenCV 4.3.0 lacks an arm64 simulator slice; keep x86_64 sims (Rosetta) working.
    installer.pods_project.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end

  target 'WoolWalletTests' do
    inherit! :search_paths
  end

  target 'WoolWalletUITests' do
  end
end
