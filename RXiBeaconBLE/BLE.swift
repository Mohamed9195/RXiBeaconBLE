//
//  BLE.swift
//  RXiBeaconBLE
//
//  Created by mohamed hashem on 9/18/20.
//  Copyright © 2020 mohamed hashem. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxSwift
import RxBluetoothKit

protocol BLEServices {
    func scan() -> Observable<ScannedPeripheral>?
    func connectTo(device: ScannedPeripheral) -> Observable<Peripheral>?
    func ConnectionServicesTo(device: ScannedPeripheral, serviceCBUUID: CBUUID, discoverCharacteristicsCBUUID: CBUUID) -> Observable<Characteristic>?
}

class BLE: NSObject, BLEServices {

    var manager: CentralManager?
    var peripheral: CBPeripheral!
    fileprivate let disposeBag: DisposeBag = DisposeBag()

    required internal override init() {
        _ = [CBCentralManagerOptionRestoreIdentifierKey: "RestoreIdentifierKey"] as [String: AnyObject]
        manager = CentralManager(queue: .main, options: nil)
    }

    func scan() -> Observable<ScannedPeripheral>? {
        let stateObservable = manager?.observePoweredOnState()
        let scanner =   manager?.observeState()
            .startWith(manager!.state)
            .filter{ $0 == .poweredOn }
            .timeout(.seconds(30), scheduler: MainScheduler.instance)
            .flatMap{ _ in
                self.manager!.scanForPeripherals(withServices: nil)
        }

        return stateObservable
            .flatMap { _ in return scanner }
    }

    func connectTo(device: ScannedPeripheral) -> Observable<Peripheral>? {
        let stateObservable = manager?.observePoweredOnState()
        let devices =  device.peripheral.establishConnection()

        return stateObservable
            .flatMap { _ in return devices }
    }

    func ConnectionServicesTo(device: ScannedPeripheral,
                                       serviceCBUUID: CBUUID,
                                       discoverCharacteristicsCBUUID: CBUUID) -> Observable<Characteristic>? {
        let stateObservable = manager?.observePoweredOnState()
        let services = device.peripheral.establishConnection()
            .flatMap { $0.discoverServices([serviceCBUUID])}
            .asObservable()
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([discoverCharacteristicsCBUUID])}
            .asObservable()
            .flatMap { Observable.from($0) }

        return stateObservable
            .flatMap { _ in return services }
    }
}


extension CentralManager {
    // powered on BLE signal
    internal func observePoweredOnState() -> Observable<BluetoothState> {
        return self
            .observeState()
            .startWith(state)
            .filter { $0 == .poweredOn }
            .timeout(DispatchTimeInterval.seconds(5), scheduler: MainScheduler.instance)
            .catchError { [weak self] (error) -> Observable<BluetoothState> in
                if let rxError = error as? RxError,
                    case RxError.timeout = rxError {
                    return Observable.from(optional: self?.state)
                }
                throw error
        }
    }
}
