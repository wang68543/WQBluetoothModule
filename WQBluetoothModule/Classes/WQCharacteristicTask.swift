//
//  WQBluetoothTask.swift
//  Pods
//
//  Created by hejinyin on 2018/3/12.
//  每个Task发送数据都是单线程的

import Foundation
import CoreBluetooth

public typealias WQNotifyCompeletion = (Bool,WQBLEError?) -> Void

public class WQCharacteristicTask{
//    public typealias WQFindDescriptor = (CBDescriptor?,WQBLEError?) -> Void
//    public typealias WQDescriptorTaskCompeletion = (WQDescriptorTask?,WQBLEError?) -> Void
    public let write_characteristic:CBCharacteristic
    
    public let notifty_characteristic:CBCharacteristic?
    unowned private let peripheral:CBPeripheral
    
    /// 每个特征只有一个订阅block (只有当没有回调的时候)
    public internal(set) var subscribeRequest:WQBLESubscribeRequest?
    
    private var notifyCompeletion:WQNotifyCompeletion?
    
//    private var discoverDescriptorsCompeletion:WQCompeletionHandle?
    
    /// 保存所有接收到的数据
    private var buffer:Array<UInt8> = []
  //=======================
    private var sendRequests:[WQBLEDataRequest] = []
    /// 暂时一个Characteristic 只支持一种校验方式
//    private var validation:WQBLEDataValidation?
    
//    private var tasks:[String:WQDescriptorTask] = [:]
    
    init(for write_character:CBCharacteristic ,
         notify notify_character:CBCharacteristic? = nil,
         peripheral:CBPeripheral) {
        write_characteristic = write_character
        notifty_characteristic = notify_character
        self.peripheral = peripheral
    }
    public func request(for request:WQBLEDataRequest){
        guard let compeletion = request.callback else{
            return
        }
        if request.writeMethod == .withResponse  , !write_characteristic.properties.contains(.write) {
            compeletion(nil,WQBLEError.writeFailed(reason: .notPermission(message: "当前特征不支持`withResponse`写入方式")))
            return
        }

        if request.writeMethod == .withoutResponse, !write_characteristic.properties.contains(.writeWithoutResponse) {
            compeletion(nil,WQBLEError.writeFailed(reason: .notPermission(message: "当前特征不支持`withoutResponse`写入方式")))
            return
        }
        
        if request.writeMethod == .withResponseNotify {
            enableNotify{[weak self] (isNotifying, error) in
                if let weakSelf = self,isNotifying {
                    weakSelf.begin(for: request)
                }else {
                    if let err = error {
                        compeletion(nil,err)
                    }else {
                        compeletion(nil,WQBLEError.writeFailed(reason: .unableConnectCharacteristic(error: nil)))
                    }
                }
            }
        }else {
                begin(for: request)
        }
        
    }
    
    
    func subcribe(for request:WQBLESubscribeRequest) {
        enableNotify {[weak self] (isNotify, error) in
             if let compeletion = request.isSuccessSubscribe {
                    if isNotify {
                       compeletion (nil)
                    }else {
                       compeletion (error)
                    }
            }
            if let weakSelf = self, let _ = request.valueChanged {
                weakSelf.subscribeRequest = request
            }
        }
    }
    
//    private func requestDescriptor(for request:WQBLEDescriptorRequest){
//        getDescriptorTask(with: request.descriptorId) { (task, error) in
//            if let task = task {
//                task.request(for: request)
//            }else {
//                request.callback?(nil,error)
//            }
//        }
//    }
    
 
}
extension WQCharacteristicTask {
    private func begin(for request:WQBLEDataRequest){
        sendRequests.append(request)
     
        if request.writeMethod == .withResponseNotify {
            if write_characteristic.properties.contains(.writeWithoutResponse){
                peripheral.writeValue(request.sendData, for: write_characteristic, type: .withoutResponse )
            }else {
                peripheral.writeValue(request.sendData, for: write_characteristic, type: .withResponse  )
            }
        }else {
           peripheral.writeValue(request.sendData, for: write_characteristic, type: request.writeMethod == .withResponse ? .withResponse : .withoutResponse )
        }
 
        
    }
}

//extension WQCharacteristicTask {
//    public func getDescriptorTask(with descriptorId:String, compeletion:@escaping  WQDescriptorTaskCompeletion){
//        if let task = tasks[descriptorId] {
//            compeletion(task,nil)
//        }else {
//            getDescriptor(with: descriptorId) { [weak self] (descriptor, error) in
//                if let weakSelf = self {
//                    if let descriptor = descriptor {
//                        let task = WQDescriptorTask(for: descriptor, peripheral: weakSelf.peripheral)
//                        weakSelf.tasks[descriptor.uuid.uuidString] = task
//                        compeletion(task,nil)
//
//                    }else {
//                        compeletion(nil,error)
//                    }
//                }
//            }
//        }
//
//    }
//
//    private func getDescriptor(with descriptorId:String, compeletion: @escaping WQFindDescriptor) {
//        if let descriptors = self.characteristic.descriptors{
//            if let index =  descriptors.index(where: { $0.uuid.uuidString == descriptorId }) {
//                compeletion(descriptors[index],nil)
//            }else {
//                compeletion(nil,WQBLEError.writeFailed(reason: .notFoundDescriptor))
//            }
//        }else {
//            discoverDescriptors { [weak self] error in
//                if let weakSelf = self {
//                    if let err = error {
//                        compeletion(nil, err)
//                    }else{
//                        if let index =  weakSelf.characteristic.descriptors?.index(where: { $0.uuid.uuidString == descriptorId }) {
//                            compeletion(weakSelf.characteristic.descriptors![index],nil)
//                        }else {
//                            compeletion(nil,WQBLEError.writeFailed(reason: .notFoundDescriptor))
//                        }
//                    }
//                }
//            }
//        }
//
//    }
//    private func discoverDescriptors(compeletion:@escaping WQCompeletionHandle) {
//        if let descriptors = self.characteristic.descriptors, !descriptors.isEmpty {
//            compeletion(nil)
//        }else {
//            peripheral.discoverDescriptors(for: characteristic)
//            discoverDescriptorsCompeletion = compeletion
//        }
//    }
//}
extension WQCharacteristicTask {
    
   private  func enableNotify(compeletion: @escaping WQNotifyCompeletion) {
    guard let notify = notifty_characteristic else{
        compeletion(false,WQBLEError.writeFailed(reason: .notFoundCharacteristic))
        return
    }
    
        if notify.isNotifying {
            compeletion(true,nil)
        }else if !notify.properties.contains(.notify) {//当前特征值不支持特征属性
            compeletion(false,WQBLEError.writeFailed(reason: .enableNotifyFailed(error: nil)))
        } else{
            let callback:WQNotifyCompeletion = { (isNotifying, error) in
                if isNotifying {
                    compeletion (true,nil)
                }else{
                    compeletion(false,WQBLEError.writeFailed(reason: .enableNotifyFailed(error: error)))
                }
            }
             notifyCompeletion = callback
            peripheral.setNotifyValue(true, for: notify)
        }
    }
    
//   private func disableNotify(compeletion:@escaping WQNotifyCompeletion)  {//关闭notify
//        if self.write_characteristic.isNotifying {
//            let callback:WQNotifyCompeletion = { (isNotifying, error) in
//                if !isNotifying {
//                    compeletion (false,nil)
//                }else{
//                    compeletion(true,WQBLEError.writeFailed(reason: .disabledNotifyFailed(error: error)))
//                }
//            }
//            notifyCompeletion = callback
//            peripheral.setNotifyValue(false, for: write_characteristic)
//        }else{
//             compeletion(false,nil)
//        }
//    }
    
}
/// CBPeripheralDelegate
extension WQCharacteristicTask {
    func didWriteValue(for descriptor: CBDescriptor, error: WQBLEError?){
//        guard let task = tasks[descriptor.uuid.uuidString] else {
//            return
//        }
//        task.didWriteValue(error: error)
    }
    func didUpdateValue(for descriptor: CBDescriptor, error: WQBLEError?){
//        guard let task = tasks[descriptor.uuid.uuidString] else {
//            return
//        }
//        task.didUpdateValue(error: error)
    }
    
    func didWriteValue(error: WQBLEError?){
        //写入的时候 失败的话 回调最后一个
        guard let err = error,
            let request = sendRequests.popLast()  else {
            return
        }
        if let compeletion = request.callback {
            compeletion(nil,WQBLEError.writeFailed(reason: .failed(error: err)))
        }
    }
    

    func didUpdateValue(error: WQBLEError?){
        guard error == nil  else {//发生错误了 先删除最早的发送请求
            if let request = sendRequests.first {
                if let comeletion = request.callback {
                    comeletion(nil,error)
                }
                sendRequests.removeFirst()
            }
          buffer.removeAll()
            return
        }
        
        var value:Data? = nil
        if let notify = notifty_characteristic {
            value = notify.value ?? write_characteristic.value
        }else {
            value = write_characteristic.value
        }
         
        
        guard let data = value else {//没有数据
            if let request = sendRequests.first {
                if let comeletion = request.callback {
                    comeletion(nil,error)
                }
                sendRequests.removeFirst()
            }
            buffer.removeAll()
            return
        }
        let origin = data.withUnsafeBytes { [UInt8](UnsafeBufferPointer(start: $0, count: data.count)) }
        buffer += origin
        handleValue()
    }
    
    private func handleValue() {
        let  validate = WQBLEManager.manager.getValidation(identifier: peripheral.identifier, characteristicId: write_characteristic.uuid.uuidString)
//        guard let validate = commonParse else {
//            fatalError("请设置验证接收数据接口")
//        }
//        
        let response = validate(buffer)
        guard !response.isPart else {//分包的话 就继续等待
            return
        }
        
        //清除buffer
        buffer.removeFirst(response.responseValue.count)
        //清除原有数据之后 再清除 第一个不为0的无效数据
        if let index = buffer.index(where: { $0 > 0})  {
            buffer.removeFirst(index)
        }
        if let cmd = response.responseCmd,
            let request = sendRequests.first(where: { $0.callbackCmd == cmd }) {
            if let compeletion = request.callback {
                if response.isCheckedSuccess {
                    compeletion(response,nil)
                }else {
                    compeletion(response,WQBLEError.readFailed(reason: .validationFailed(message: "数据解析失败")))
                }
            }
            
            if let reqIndex = sendRequests.index(where: { $0.callbackCmd == cmd }) {
                sendRequests.remove(at: reqIndex)
            }
        }else {
            if let request = sendRequests.first  {
                if let compeletion = request.callback {
                    if response.isCheckedSuccess {
                        compeletion(response,nil)
                    }else {
                        compeletion(response,WQBLEError.readFailed(reason: .validationFailed(message: "数据解析失败")))
                    }
                }
                sendRequests.removeFirst()
            }else if response.isCheckedSuccess, let subcribe = subscribeRequest?.valueChanged{//解析成功了 才回调订阅
                subcribe(response,nil)
            }
        }
        if buffer.count > 0 {
            handleValue()
        }
    }
    func didUpdateNotificationState(error: WQBLEError?)  {
        guard let compeletion = notifyCompeletion,
            let notify = notifty_characteristic   else {
            return
        }
        compeletion(notify.isNotifying,error)
        
        notifyCompeletion = nil
    }
    
    func didDiscoverDescriptors(error: WQBLEError?) {
//        guard let compeletion = discoverDescriptorsCompeletion else{
//            return
//        }
//        compeletion(error)
//        discoverDescriptorsCompeletion = nil
    }
}

extension WQCharacteristicTask {
    //异常断开 
    func didFailedToConnect(error: WQBLEError) {
        sendRequests.forEach { $0.callback?(nil,error) }
    }
    
    //主动关闭了
    func didClosedConnect()  {
        let error = WQBLEError.connectionFailed(reason: .closed)
        sendRequests.forEach { $0.callback?(nil,error) }
    }
}
