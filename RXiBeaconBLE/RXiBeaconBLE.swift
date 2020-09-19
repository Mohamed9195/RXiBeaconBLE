//
//  RXiBeaconBLE.swift
//  RXiBeaconBLE
//
//  Created by mohamed hashem on 9/18/20.
//  Copyright © 2020 mohamed hashem. All rights reserved.
//

import RxSwift
import RxBluetoothKit
import CoreBluetooth

open class RXiBeaconBLE {

    private let iBeacon: IBeaconServices
    private let bluetooth: BLE

    private static var iBeaconBLE: RXiBeaconBLE?

       public static var `default`: RXiBeaconBLE {
           get {
               guard let iBeaconBLE = iBeaconBLE else {
                   fatalError("iBeaconBLE is not configured")
               }

               return iBeaconBLE
           }
       }

    // call in app Delegate
    public static func configure() {
           iBeaconBLE = RXiBeaconBLE()
       }

    internal init() {
        iBeacon = IBeaconServicesClass(iBeaconLocationDelegate: IBeaconDelegation())
        bluetooth = BLE()
    }
}

extension RXiBeaconBLE: BLEServices {
    func scan() -> Observable<ScannedPeripheral>? {
        bluetooth.scan()
    }

    func connectTo(device: ScannedPeripheral) -> Observable<Peripheral>? {
        bluetooth.connectTo(device: device)
    }

    func ConnectionServicesTo(device: ScannedPeripheral, serviceCBUUID: CBUUID, discoverCharacteristicsCBUUID: CBUUID) -> Observable<Characteristic>? {
        bluetooth.ConnectionServicesTo(device: device, serviceCBUUID: serviceCBUUID, discoverCharacteristicsCBUUID: discoverCharacteristicsCBUUID)
    }
}

extension RXiBeaconBLE: IBeaconServices {
    public func addButterfly(proximityUUIDs: [(UUID,String)]) {
        iBeacon.addButterfly(proximityUUIDs: proximityUUIDs)
    }

    public func removeButterfly(proximityUUID: UUID) -> Bool? {
        iBeacon.removeButterfly(proximityUUID: proximityUUID)
    }

    public func clear() {
        iBeacon.clear()
    }

    public func start() -> Observable<iBeaconStruct> {
        iBeacon.start()
    }

    public func stop() {
        iBeacon.stop()
    }
}
