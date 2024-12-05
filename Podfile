# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'WoolWallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WoolWallet
  pod 'OpenCV2'
  pod 'Sweetercolor', :git => 'https://github.com/lwerner18/Sweetercolor.git'
  pod 'UIImageColors'

  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '5.0'
      end
    end
    
    installer.pods_project.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
  
  target 'WoolWalletTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'WoolWalletUITests' do
    # Pods for testing
  end

end
