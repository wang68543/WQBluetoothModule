//
//  WQBluetoothSession.swift
//  Pods
//
//  Created by hejinyin on 2018/3/12.
//  一个session代表一个设备

import Foundation
import CoreBluetooth


//单线程
public class WQBLESession: NSObject{
    
    public typealias FindServiceCallback = (CBService?,WQBLEError?) -> Void
    public typealias FindCharacteristicCallback = (CBCharacteristic?,WQBLEError?) -> Void
    public typealias TaskCompeletion = (WQCharacteristicTask?,WQBLEError?) -> Void
  
    //默认需要重新连接
    public var isNeedToReconnect = true
    
    //正在重新连接
    public internal(set) var isReconnecting:Bool = false
    
    
    //对外只读 对内可读写
    public private(set) var peripheral: CBPeripheral
    
    public private(set) var tasks:[String:WQCharacteristicTask] = [:]
    
    private var discoveredCharacteristics: [String: CBCharacteristic] = [:]
 
    //扫描外围设备的服务
    private var discoverServicesCompeletion: WQCompeletionHandle?
    //扫描外围设备的特征
    private var discoverCharacteristicsCompeletions: [String:WQCompeletionHandle] = [:]
  
    
    init(device peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
    }
   
    deinit {
        debugPrint("蓝牙会话断开了")
    }
}
extension WQBLESession {
 
    public func subscribeTask(for request:WQBLESubscribeRequest){
        getTask(service: request.serviceId, uuidString: request.characteristicId) { (characteristicTask, error) in
            if let task = characteristicTask {
                 task.subcribe(for: request)
            }else{
                if let compeletion = request.isSuccessSubscribe {
                    compeletion(error)
                }
            }
        }
    }
    
    public func requestTask(for request:WQBLEDataRequest){
        getTask(service: request.serviceId,  uuidString: request.characteristicId,notifyId:request.notifyCharacteristicId) { (characteristicTask, error) in
            if let task = characteristicTask {
                task.request(for: request)
            }else{
                if let compeletion = request.callback {
                    compeletion(nil,error)
                }
            }
        }
    }
    public func validationTask(for request:WQBLERequest,validation:@escaping WQBLEDataValidation){
        
    }
    
}
/// CBCentralManagerDelegate
extension WQBLESession {
    
    /// 根据uid创建读写任务
    ///
    /// - Parameters:
    ///   - serviceUuid: 服务的id
    ///   - uuidString: 特征id
    ///   - notifyId: notify回调特征的id (withResponseNotify方式才传)
    ///   - compeletion: 完成回调
    public func getTask(service serviceUuid:String,
                        uuidString:String ,
                        notifyId:String? = nil,
                        compeletion:@escaping TaskCompeletion){
        
        if let notify = notifyId  {//有 notifyId
            if let task = tasks[notify] {
                compeletion(task,nil)
            }else {
                if let notifyCharacteristic = discoveredCharacteristics[notify] ,
                   let characteristic = discoveredCharacteristics[uuidString] {
                    let task = WQCharacteristicTask(for: characteristic, notify: notifyCharacteristic, peripheral: peripheral)
                    compeletion(task,nil)
                    tasks[notify] = task
                } else if discoveredCharacteristics[notify] != nil || discoveredCharacteristics[uuidString] != nil {//只有一个 出问题了
                   
             compeletion(nil,WQBLEError.writeFailed(reason: .notFoundCharacteristic))
                }else{
                    enableCharacteristic(service: serviceUuid, uuidString: uuidString, compeletion: {[weak self] (characteristic, error) in
                        if let weakSelf = self {
                            if let err = error{
                                compeletion(nil,err)
                            }else {
                                if let character = characteristic, let notifyCharacter = weakSelf.discoveredCharacteristics[notify] {
                                    let task = WQCharacteristicTask(for: character, notify: notifyCharacter, peripheral: weakSelf.peripheral)
                                    compeletion(task,nil)
                                    weakSelf.tasks[notify] = task
                                }else {
                                    compeletion(nil,WQBLEError.writeFailed(reason: .notFoundCharacteristic))
                                }
                            }
                        }
                    })
                }
            }
        }else if let task = tasks[uuidString] {//非withNotify方式写入
            compeletion(task,nil)
        }else if let characteristic = discoveredCharacteristics[uuidString] {
            //因为暂时只支持一个Service下面的不同的Characteristic回调
            let task = WQCharacteristicTask(for: characteristic, peripheral: peripheral)
           compeletion(task,nil)
        }else {
            enableCharacteristic(service: serviceUuid, uuidString: uuidString, compeletion: {[weak self] (characteristic , error) in
                if let weakSelf = self, let character = characteristic {
                    let task = WQCharacteristicTask(for: character, peripheral: weakSelf.peripheral)
                    compeletion(task,nil)
                    weakSelf.tasks[character.uuid.uuidString] = task
                }else {
                    if let err = error {
                        compeletion(nil,err)
                    }else {
                        compeletion(nil,WQBLEError.connectionFailed(reason: .disconnected))
                    }
                }
            })
        }
    }
    
    // 每次写数据或者读数据之前获取 characteristics
    private func enableCharacteristic(
        service serviceUuid:String,
        uuidString:String,
        compeletion:@escaping FindCharacteristicCallback
        ){
        if self.peripheral.state != .connected {
            compeletion(nil,WQBLEError.connectionFailed(reason: .disconnected))
            return
        }
        
        if let characteristic = discoveredCharacteristics[uuidString] {
            compeletion(characteristic,nil)
        }else {
            discoverServices(for: serviceUuid) { (service, error) in
                if let foundService = service {
                    self.discoverCharacteristic(with: uuidString, for: foundService, compeletion: { (characteristics, error) in
                        if let character = characteristics {
                            compeletion(character,nil)
                        }else {
                            compeletion(nil,WQBLEError.connectionFailed(reason: .notFoundCharacteristic(error: error)))
                        }
                    })
                }else {
                    compeletion(nil,WQBLEError.connectionFailed(reason: .notFoundServices(error: error)))
                }
            }
        }

    }
    
    public func discoverServices(for uuid:String, compeletion:@escaping FindServiceCallback){
        if let service = getService(with: uuid) {
            compeletion(service,nil)
        }else if let _ = peripheral.services {//之前搜索过此service
            compeletion(nil,WQBLEError.writeFailed(reason: .notFoundService))
        }else {
            let compeletion:WQCompeletionHandle = {[weak self]  error in
                if let weakSelf = self, let service = weakSelf.getService(with: uuid) {
                    compeletion(service,nil)
                }else {
                    compeletion(nil,error)
                }
            }
            discoverServicesCompeletion = compeletion
            self.peripheral.discoverServices(nil)
        }
    }
    
    public func discoverCharacteristic(with uuid:String, for service:CBService ,compeletion:@escaping FindCharacteristicCallback) {
        if let characteristic = getCharacteristic(with: uuid, for: service) {
             compeletion(characteristic,nil)
        }else if let _ = service.characteristics {//之前搜索过此service
            compeletion(nil,WQBLEError.writeFailed(reason: .notFoundCharacteristic))
        }else {
            let compeletion:WQCompeletionHandle = { [weak self] error in
                if  let weakSelf = self,
                    let characteristic = weakSelf.getCharacteristic(with: uuid, for: service)
                {
                    compeletion(characteristic,nil)
                }else {
                    compeletion(nil,error)
                }
            }
            discoverCharacteristicsCompeletions[service.uuid.uuidString] = compeletion
             self.peripheral.discoverCharacteristics(nil, for: service)
        }
    }
 
    private func getService(with uuid:String) -> CBService? {
        var service:CBService?
        if let index = peripheral.services?.index(where: { $0.uuid.uuidString == uuid }) {
            service =  peripheral.services![index]
        }
        return service
    }
    
    private func getCharacteristic(with uuid:String, for service:CBService) -> CBCharacteristic? {
        var characteristic:CBCharacteristic?
        if let index = service.characteristics?.index(where: { $0.uuid.uuidString == uuid }) {
            characteristic = service.characteristics![index]
        }
        return characteristic
    }
}

extension WQBLESession{
    
    public func didReconnect(_ peripheral:CBPeripheral) {
         self.isReconnecting = false
         self.peripheral = peripheral
    }
    
    //中途连接的时候异常 断开连接了
    public func didFailedToConnect(error:WQBLEError) {
       //清除 写入的回调
        resetParameters(error: error)
    }
    //主动关闭
    public func didClosedConnect() {
        resetParameters()
    }
    
    //有error 就是异常断开  没有error的话就是主动断开
    private func resetParameters(error: WQBLEError? = nil) {
        if let err = error {
          tasks.forEach { $0.value.didFailedToConnect(error: err) }
          discoverCharacteristicsCompeletions.forEach{ $0.value(err) }
        }else {
          tasks.forEach { $0.value.didClosedConnect() }
          discoverCharacteristicsCompeletions.forEach{ $0.value(WQBLEError.connectionFailed(reason: .closed)) }
        }
        tasks.removeAll()
        discoveredCharacteristics.removeAll()
        discoveredCharacteristics = [:]
        
        if let discoverCompeletion = discoverServicesCompeletion {
            if let err = error {
                discoverCompeletion(err)
            }else {
                discoverCompeletion(WQBLEError.connectionFailed(reason: .closed))
            }
            discoverServicesCompeletion = nil
        }
       
    }
    
}

extension WQBLESession: CBPeripheralDelegate{
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
         if let compeletion = discoverServicesCompeletion {
            if let services = peripheral.services , !services.isEmpty {
                compeletion(nil)
            }else {
             compeletion(WQBLEError.connectionFailed(reason: .notFoundServices(error: error)))
            }
        }
        discoverServicesCompeletion = nil
    }
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characters = service.characteristics , !characters.isEmpty{
            characters.forEach{ discoveredCharacteristics[$0.uuid.uuidString] = $0 }
             if let compeletion = discoverCharacteristicsCompeletions[service.uuid.uuidString] {
                compeletion(nil)
            }
        }else {
            if let compeletion = discoverCharacteristicsCompeletions[service.uuid.uuidString] {
               compeletion(WQBLEError.connectionFailed(reason: .notFoundCharacteristic(error: error)))
            }
        }
        discoveredCharacteristics.removeValue(forKey: service.uuid.uuidString)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        guard let task = tasks[characteristic.uuid.uuidString] else {
            return
        }
        if let err = error {
            task.didDiscoverDescriptors(error: WQBLEError.writeFailed(reason: .failed(error: err)))
        }else {
            task.didDiscoverDescriptors(error: nil)
        }
    }
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        guard let task = tasks[descriptor.characteristic.uuid.uuidString] else {
            return
        }
        if let err = error {
            task.didUpdateValue(for: descriptor, error: WQBLEError.writeFailed(reason: .failed(error: err)))
        }else {
            task.didUpdateValue(for: descriptor, error: nil)
        }
    }
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard let task = tasks[descriptor.characteristic.uuid.uuidString] else {
            return
        }
        if let err = error {
            task.didWriteValue(for: descriptor, error: WQBLEError.writeFailed(reason: .failed(error: err)))
        }else {
            task.didWriteValue(for: descriptor, error: nil)
        }
    }
    //当写 withoutResponse 类型数据失败的的时候会回调这个方法 
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        debugPrint("准备好了可以发送不响应数据")
    }
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let task = tasks[characteristic.uuid.uuidString] else {
            return
        }
        if let err = error {
          task.didWriteValue(error: WQBLEError.writeFailed(reason: .failed(error: err)))
        }else {
            task.didWriteValue(error: nil)
        }
        
    }
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let task = tasks[characteristic.uuid.uuidString] else {
            return
        }
        if let err = error {
            task.didUpdateValue(error: WQBLEError.readFailed(reason: .failed(error: err)))
        }else {
            task.didUpdateValue(error: nil)
        } 
    }
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard let task = tasks[characteristic.uuid.uuidString] else {
            return
        }
        if let err = error {
            task.didUpdateNotificationState(error: WQBLEError.writeFailed(reason: .enableNotifyFailed(error: err)))
        }else {
            task.didUpdateNotificationState(error: nil)
        }
    }
}
