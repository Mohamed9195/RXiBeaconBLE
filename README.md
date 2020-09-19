# RXiBeaconBLE
RXiBeaconBLE is a Bluetooth and iBeacon library that makes interaction with BLE and location beacon devices much more pleasant. 

# Installation
pod 'RXiBeaconBLE', :git => 'https://github.com/Mohamed9195/RXiBeaconBLE.git', :tag => '0.0.1'

# authors     
 Mohamed Hashem mohamedabdalwahab588@gmail.com
 
# example
```swift

// in AppDelegate  func application(_ application: UIApplication, didFinishLaunchingWithOptions 
RXiBeaconBLE.configure()

// where you need use.
  RXiBeaconBLE.default.start()
  RXiBeaconBLE.default.stop()
  RXiBeaconBLE.default.scan()
