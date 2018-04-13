//
//  WQBleRequest.swift
//  Pods
//
//  Created by hejinyin on 2018/3/12.
//

import Foundation

public enum WQCharacteristicResponseMethod {
    case withResponse
    case withoutResponse
    case withResponseNotify
}
//public typealias WQSendCompeletion = (WQBLEResponse?,Error?) -> Void
public typealias WQValueChanged = (WQBLEResponse?,WQBLEError?) -> Void
/// 校验通过了就返回有效数据 否则就返回nil
public typealias WQBLEDataValidation = ([UInt8]) -> WQBLEResponse
public typealias WQSubscribe = (WQBLEError?) -> Void

open class WQBLERequest {
    
    let identifier:UUID? //设备的唯一标识 如果为nil的话 就是处理整个业务逻辑只有一个连接设备的时候使用 默认nil
    
    let serviceId:String
    /// 有可能是characteristicID
    let characteristicId:String
 
//    public var validate:WQBLEDataValidation?
    
    public init(_ deviceId:UUID?,
         service serviceId:String,
         characteristic detailId:String ) {
            identifier = deviceId
            self.serviceId = serviceId
            characteristicId = detailId
    }
 
}

open class WQBLEDataRequest: WQBLERequest {
    let writeMethod:WQCharacteristicResponseMethod
    let sendData: Data
    //作为key值
    let callbackCmd: UInt8 //响应的cmd 如果设备端是多线程的话 最好是使用命令字
    
    //响应的 获取cmd 的range 暂时只支持一个字节 
//    let callbackCmdRange: NSRange?
    
    /// notify 方式回调的特征id 当写入方式为notify的时候 这里默认与characteristicId一致
    /// 这里暂时只支持与characteristicId在同一个service下面的characteristic
    var notifyCharacteristicId: String? = nil
    
    private(set) var callback:WQValueChanged?
    
    public init(_ deviceId:UUID?,
         service serviceId:String,
         characteristic detailId:String,
         notify notifyId: String? = nil,
         send data:Data,
         response cmd:UInt8 = UInt8.max ,
//         cmdRange:NSRange?,
         resMethod:WQCharacteristicResponseMethod ) {
            sendData = data
            writeMethod = resMethod
            callbackCmd = cmd
//            callbackCmdRange = cmdRange
            notifyCharacteristicId = notifyId
        super.init(deviceId, service: serviceId, characteristic: detailId)
    }
}

//open class WQBLEDescriptorRequest:WQBLEDataRequest {
//    let descriptorId:String
//    public  init(_ deviceId: UUID?, service serviceId: String, characteristic detailId: String, descriptor descriptorId:String,  send data: Data, response cmd: UInt8?, cmdRange: NSRange?, resMethod: WQCharacteristicResponseMethod) {
//        self.descriptorId = descriptorId
//        super.init(deviceId, service: serviceId, characteristic: detailId, send: data, response: cmd, cmdRange: cmdRange, resMethod: resMethod)
//    }
//    
//}


/// 订阅请求
open class WQBLESubscribeRequest:WQBLERequest {
    private(set) var valueChanged: WQValueChanged?
    
    private(set) var isSuccessSubscribe:WQSubscribe?
    
    public func subscribe(success:@escaping WQSubscribe, compeletion:@escaping WQValueChanged) -> Self{
        isSuccessSubscribe = success
        valueChanged = compeletion
        WQBLEManager.manager.subscribeSession(for: self)
        return self
    }
}

extension WQBLERequest {
    ///需要通过这里的验证返回cmd
    public func validation(compeletion:@escaping WQBLEDataValidation) -> Self{
        WQBLEManager.manager.validation(identifier: identifier, characteristicId: characteristicId, completion: compeletion)
        return self
        
    }
}
extension WQBLEDataRequest {
    @discardableResult
    public func response(compeletion:@escaping WQValueChanged) -> Self {
        callback = compeletion
        WQBLEManager.manager.requestSession(for: self, compeletion: compeletion)
        return self
    }
}



//extension WQBLERequest{
//    public static func ser
//}

