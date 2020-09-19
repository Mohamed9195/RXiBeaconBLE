
Pod::Spec.new do |spec|


spec.name         = "RXiBeaconBLE"
spec.version      = "0.0.1"

spec.summary      = "Take all permission, and get any change to happen in it."
spec.description  = "using push protocol to get any update in permissions when calling framework object one time, and can use Push RXPermission View to show all permission."
spec.homepage     = "https://github.com/Mohamed9195/RXiBeaconBLE"
spec.license      = "MIT"
spec.authors      = { "Mohamed Hashem" => "mohamedabdalwahab588@gmail.com" }
spec.platform     = :ios, "12.0"
spec.ios.deployment_target = "12.0"
spec.source       = { :git => "https://github.com/Mohamed9195/RXiBeaconBLE.git", :tag => "#{spec.version}" }
spec.source_files  = "RXiBeaconBLE"
spec.exclude_files = "Classes/Exclude"
spec.resources  = "RXiBeaconBLE/*.{xib,png}"
#spec.resources = "RXiBeaconBLE/location.png"
#spec.resources = "RXiBeaconBLE/i-camera.png"
#spec.resources = "RXiBeaconBLE/notification.png"
#spec.resources = "RXiBeaconBLE/bluetooth.png"

spec.subspec 'App' do |app|
app.source_files = 'PushPermission/**/*.swift'
#app.resource_bundles = {'PushPermission' => ['PushPermission/Resources/**/*']}
end

spec.swift_version = "4.2"

spec.dependency 'RxSwift', '~> 5.1'
spec.dependency "RxCocoa", "~> 5.1"
spec.dependency "RxBluetoothKit", "~> 6.0"
end
