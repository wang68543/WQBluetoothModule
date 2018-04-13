//
//  BLERequest.swift
//  WQBluetoothModule_Example
//
//  Created by hejinyin on 2018/3/30.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import WQBluetoothModule

public let primaryServiceId  = "0001"//00000001-0000-1000-8000-00805F9B34FB //FEE7
public let primaryCharacteristicId = "0002"//00000003-0000-1000-8000-00805F9B34FB
public let primaryNotifyCharacteristicId = "0003"//00000003-0000-1000-8000-00805F9B34FB
public let DescriptorId = "2902"

public let periphralId:UUID = UUID.init(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!

//extension WQBLEDescriptorRequest {
//    convenience init(descriptor data: Data, response cmd: UInt8?) {
//        self.init(nil, service: primaryServiceId, characteristic: primaryCharacteristicId, descriptor: DescriptorId, send: data, response: cmd, cmdRange: NSMakeRange(0, 1), resMethod: .withResponseNotify)
//    }
//}
extension WQBLEDataRequest {
 
    
    convenience init(data:Data,
                     response cmd:UInt8 = UInt8.max) {
        
        self.init(nil, service: primaryServiceId, characteristic: primaryCharacteristicId, notify: primaryNotifyCharacteristicId, send:data ,response:cmd , resMethod:.withResponseNotify)
    }
    
    /// 组装数据
    static  func assembleData(cmd:UInt8, value:Array<UInt8>) -> Data  {
        return Data(bytes: [cmd] + [UInt8(value.count)] + value + [UInt8(getCheckSum(values: value) % 100)] )
    }
    static func getCheckSum(values:Array<UInt8>) -> Int {
        return values.map{ Int($0) }.reduce(0, ^)
    }
    
    
    static func getValidation() -> WQBLEDataValidation {
        //公共的校验部分
        let validate:WQBLEDataValidation =  { bytes in
            
            if bytes.count <= 1 {
                return WQBLEResponse(response: nil, value: bytes, checked: false, vaildate: nil)
            }
            let length = Int(bytes[1])
            let cmd = bytes[0]
            if length <= 0 {
                return WQBLEResponse(response: cmd, value: bytes, checked: true, vaildate: nil)
                
            }
            
            if bytes.count - length >= 3 {//够一个完整包了 一个命令 一个数据长度 一个校验码
                let data = Array(bytes[0 ... length + 3])
                let validateData = Array(bytes[2 ... length + 2])
                let checkSum = WQBLEDataRequest.getCheckSum(values: validateData)
                if UInt8(checkSum % 100) == bytes[length+2] {
                    return WQBLEResponse.init(response: cmd, value: data, checked: true, vaildate: validateData)
                }else {
                    return WQBLEResponse.init(response: cmd, value: data, checked: true, vaildate: nil)
                }
            }else{
                var response  = WQBLEResponse.init(response: cmd, value: bytes, checked: false, vaildate: nil)
                response.isPart = true
                
                return response
            }
        }
        return validate
    }
}

extension WQBLERequest {
    static func requestSetDateTime() -> WQBLEDataRequest {
        let compments = Calendar.current.dateComponents([.year,.month,.day,.hour, .minute,.second,.weekday], from: Date())
        var values:[Int] = []
        values.append(compments.year! % 100)
        values.append(compments.month!)
        values.append(compments.day!)
        values.append(compments.hour!)
        values.append(compments.minute!)
        values.append(compments.second!)
        values.append(compments.weekday!)
        return WQBLEDataRequest(data: WQBLEDataRequest.assembleData(cmd: 0xC2, value: values.map { UInt8($0) }), response:0x22)
        
    }
}
