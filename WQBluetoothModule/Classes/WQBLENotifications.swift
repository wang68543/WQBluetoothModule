//
//  WQBLENotifications.swift
//  Pods
//
//  Created by hejinyin on 2018/3/12.
//

import Foundation

extension Notification.Name{
    public struct Bluetooth {
        
        public static let AdapterDidEnable = Notification.Name(rawValue: "wq.notification.name.ble.adapterDidEnable")
        
        public static let AdapterDidDisable = Notification.Name(rawValue: "wq.notification.name.ble.adapterDidDisable")
        
        public static let PeripheralDidConnected = Notification.Name(rawValue: "wq.notification.name.ble.peripheralDidConnected")
        
        public static let PeripheralDidDisconnected = Notification.Name(rawValue: "wq.notification.name.ble.peripheralDidDisconnected")
        
    }
   
}
extension Notification{
    public struct BleKey {
        public static let Peripheral = "wq.notification.name.bleKey.peripheral"
        public static let AdapterState = "wq.notification.name.bleKey.adapterState"
        public static let Error = "wq.notification.name.bleKey.error"
    }
}
