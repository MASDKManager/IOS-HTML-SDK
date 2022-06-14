# Uncomment the next line to define a global platform for your project
# platform :ios, '12.0'

target 'MobFlowiOS' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Test
  pod 'Adjust'
  pod 'ReachabilitySwift'
  pod 'Firebase'
  pod 'FirebaseMessaging'
  pod 'FirebaseCrashlytics'
  pod 'Branch'
  pod 'YandexMobileMetrica/Dynamic', '4.2.0'
 
 post_install do |installer|
     installer.pods_project.targets.each do |target|
         target.build_configurations.each do |config|
             config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
             config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
             config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
         end
     end
 end
   
end
