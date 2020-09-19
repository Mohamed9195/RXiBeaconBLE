//
//  PublicStruct.swift
//  RXiBeaconBLE
//
//  Created by mohamed hashem on 9/18/20.
//  Copyright © 2020 mohamed hashem. All rights reserved.
//

import CoreLocation
import RxSwift
import RxBluetoothKit

public struct iBeaconStruct {
    var UUID: UUID?
    var major: NSNumber?
    var minor: NSNumber?
    var rssi: Int?

    init(major: NSNumber?, minor: NSNumber?, uuid: UUID?, rssi: Int? ) {
        self.UUID = uuid
        self.major = major
        self.minor = minor
        self.rssi = rssi
    }
}

public enum iBeaconAdvertisement {
    case outOfRange
    case beacons([iBeaconStruct])
}
