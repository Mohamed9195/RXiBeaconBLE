//
//  iBeacon.swift
//  RXiBeaconBLE
//
//  Created by mohamed hashem on 9/18/20.
//  Copyright © 2020 mohamed hashem. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxBluetoothKit

protocol LocationDelegate: CLLocationManagerDelegate {
    var iBeaconRXSubject: ReplaySubject<iBeaconAdvertisement> { get set }
}

protocol IBeaconServices {
    func addButterfly(proximityUUIDs: [(UUID, String)])
    func removeButterfly(proximityUUID: UUID) -> Bool?
    func start() -> Observable<iBeaconStruct>
    func stop()
    func clear()
}

internal class IBeaconServicesClass: NSObject, IBeaconServices {

    internal var beaconRegions: [CLBeaconRegion]
    internal var locationManager: CLLocationManager
    internal var iBeaconLocationDelegate: LocationDelegate

    required internal init(iBeaconLocationDelegate: LocationDelegate) {

        beaconRegions = [CLBeaconRegion]()

        locationManager = CLLocationManager()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

        self.iBeaconLocationDelegate = iBeaconLocationDelegate
        locationManager.delegate = iBeaconLocationDelegate

        beaconRegions = locationManager.rangedRegions.compactMap { $0 as? CLBeaconRegion }
    }

    func addButterfly(proximityUUIDs: [(UUID, String)]) {
        proximityUUIDs.forEach { (proximityUUID) in
            if beaconRegions.first(where: { $0.proximityUUID.uuidString == proximityUUID.0.uuidString}) == nil {
                let beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID.0, identifier: proximityUUID.1)
                beaconRegion.notifyOnEntry = true
                beaconRegion.notifyOnExit = true
                beaconRegion.notifyEntryStateOnDisplay = true

                locationManager.startMonitoring(for: beaconRegion)
                beaconRegions.append(beaconRegion)
            }
        }
    }

    func removeButterfly(proximityUUID: UUID) -> Bool? {
        guard let removedBeaconRegionIndex = (beaconRegions.firstIndex { $0.proximityUUID.uuidString == proximityUUID.uuidString }) else {
            return false
        }

        let removedBeaconRegion = beaconRegions.remove(at: removedBeaconRegionIndex)

        locationManager.stopMonitoring(for: removedBeaconRegion)
        locationManager.stopRangingBeacons(in: removedBeaconRegion)

        return true
    }

    public func clear() {

        beaconRegions.forEach { (beaconRegion) in
            locationManager.stopMonitoring(for: beaconRegion)
            locationManager.stopRangingBeacons(in: beaconRegion)
        }

        beaconRegions.removeAll()
    }

    func start() -> Observable<iBeaconStruct> {
        locationManager.requestAlwaysAuthorization()
        return iBeaconLocationDelegate.iBeaconRXSubject.asObserver()
            .map({ (advertisement) -> [iBeaconStruct] in
                return self.beaconRegions.union(with: advertisement)
            }).flatMap({ devices -> Observable<iBeaconStruct> in
                return Observable.from(devices)
            }).filter({ (device) -> Bool in
                if device.UUID != nil {
                    return true
                } else {
                    return false
                }
            })
    }

    func stop() {
        iBeaconLocationDelegate.iBeaconRXSubject.onCompleted()
    }
}

class IBeaconDelegation: NSObject, LocationDelegate  {

    private let dispatchQueue = DispatchQueue(label: "IBeaconQueue")
    var manager: CentralManager
    let disposeBag = DisposeBag()
    var iBeaconRXSubject: ReplaySubject<iBeaconAdvertisement>

    internal override init() {
        iBeaconRXSubject = ReplaySubject<iBeaconAdvertisement>
            .create(bufferSize: 1)

        manager = CentralManager(queue: dispatchQueue)

        super.init()

        manager.observeState()
            .startWith(manager.state)
            .delay(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                if state != .poweredOn {
                    self?.iBeaconRXSubject.onNext(iBeaconAdvertisement.outOfRange)
                }
            }).disposed(by: disposeBag)
    }

    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else {
            assertionFailure("handle region failed from type: \(type(of: region))")
            return
        }

        if #available(iOS 13.0, *) {
            manager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: beaconRegion.uuid))
        } else {
            manager.startRangingBeacons(in: beaconRegion)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        iBeaconRXSubject.onError(error)
    }

    public func locationManager(_ manager: CLLocationManager,didRangeBeacons beacons: [CLBeacon],in region: CLBeaconRegion) {
        guard !beacons.isEmpty else {
            iBeaconRXSubject.onNext(.outOfRange)
            return
        }

        let readings: [iBeaconStruct] = beacons.map { (beacon) -> iBeaconStruct in
            if #available(iOS 13.0, *) {
                return iBeaconStruct(major: beacon.major, minor: beacon.minor, uuid: beacon.uuid, rssi: beacon.rssi)
            } else {
                return iBeaconStruct(major: beacon.major, minor: beacon.minor, uuid: beacon.proximityUUID, rssi: beacon.rssi)
            }
        }

        iBeaconRXSubject.onNext(iBeaconAdvertisement.beacons(readings))
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion")
    }
}

extension Array where Element == CLBeaconRegion {

    func union(with advertisement: iBeaconAdvertisement) -> [iBeaconStruct] {
        switch advertisement {
        case .outOfRange:
            return self.map({ (region) -> iBeaconStruct in
                if #available(iOS 13.0, *) {
                    return iBeaconStruct(major: region.major, minor: region.minor, uuid: region.uuid, rssi: nil)
                } else {
                    return iBeaconStruct(major: region.major, minor: region.minor, uuid: region.proximityUUID, rssi: nil)
                }
            })
        case .beacons(let devices):
            return join(with: devices)
        }
    }

    func join(with devices: [iBeaconStruct]) -> [iBeaconStruct] {

        var devices = devices

        return map { (region) -> iBeaconStruct in
            devices = devices.filter({ (device) -> Bool in
                if device.UUID != nil {
                    return true
                } else {
                    return false
                }
            })

            // get the index of the device
            let deviceIndex = devices.firstIndex(where: { (device) -> Bool in
                return region.proximityUUID.uuidString == device.UUID?.uuidString
            })

            if let deviceIndex = deviceIndex {
                return devices.remove(at: deviceIndex)
            } else {
                if #available(iOS 13.0, *) {
                    return iBeaconStruct(major: region.major, minor: region.minor, uuid: region.uuid, rssi: nil)
                } else {
                    return iBeaconStruct(major: region.major, minor: region.minor, uuid: region.proximityUUID, rssi: nil)
                }
            }
        }
    }
}
