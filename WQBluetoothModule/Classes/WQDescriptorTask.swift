//
//  WQDescriptorTask.swift
//  Pods
//
//  Created by hejinyin on 2018/4/2.
//

import Foundation
import CoreBluetooth
public class WQDescriptorTask{
    private let descriptor:CBDescriptor
    unowned private let peripheral:CBPeripheral
    
    private var cmdRange:NSRange?
//    private var sendRequests:[WQBLEDescriptorRequest] = []
    init(for descriptor:CBDescriptor , peripheral:CBPeripheral) {
        self.descriptor = descriptor
        self.peripheral = peripheral
    }
}
extension WQDescriptorTask {
//    public func request(for request:WQBLEDescriptorRequest){
//        guard let _ = request.callback else{
//            return
//        }
//        self.begin(for: request)
//    }
//    private func begin(for request:WQBLEDescriptorRequest){
//        cmdRange = request.callbackCmdRange
//        sendRequests.append(request)
//        peripheral.writeValue(request.sendData, for: descriptor)
//
//    }
}

extension WQDescriptorTask{
    func didWriteValue(error: WQBLEError?){
        //写入的时候 失败的话 回调最后一个
//        guard let err = error,
//            let request = sendRequests.popLast()  else {
//                return
//        }
//        if let compeletion = request.callback {
//            compeletion(nil,WQBLEError.writeFailed(reason: .failed(error: err)))
//        }
    }
    
    
    func didUpdateValue(error: WQBLEError?){
//        guard error == nil  else {//发生错误了 先删除最早的发送请求
//            if let request = sendRequests.first {
//                if let comeletion = request.callback {
//                    comeletion(nil,error)
//                }
//                sendRequests.removeFirst()
//            }
//            return
//        }
//
//        guard let data = descriptor.value else {//没有数据
//            if let request = sendRequests.first {
//                if let comeletion = request.callback {
//                    comeletion(nil,error)
//                }
//                sendRequests.removeFirst()
//            }
//            return
//        }
//
//
//        if let range = cmdRange,
//            data.count >= range.location + range.length { //根据cmdRange 找对应的cmd回调
//            let startIndex = data.index(data.startIndex, offsetBy: range.location)
//            let endIndex = data.index(startIndex, offsetBy: range.length)
//            let dataRange = Range<Data.Index>.init(uncheckedBounds: (lower: startIndex, upper: endIndex))
//            if let cmdStr = String.init(data: data.subdata(in: dataRange), encoding: .utf8),
//                let cmd = Int(cmdStr) {
//                var request:WQBLEDataRequest?
//
//                for req in sendRequests {
//                    if let reqCmd = req.callbackCmd , cmd == reqCmd {
//                        request = req
//                        break;
//                    }
//                }
//
//                if let req = request{
//                    if let compeletion = req.callback {
//                        if let validation = req.validate , let validateData = validation(data) {
//                            compeletion(WQBLEResponse(response: data, checked: true, vaildate: validateData),nil)
//                        }else{
//                            compeletion(WQBLEResponse(response: data),nil)
//                        }
//                    }
//                    if let index = sendRequests.index(where: { $0 === req }) {
//                        sendRequests.remove(at: index)
//                    }
//
//                    return
//                }
//            }
//
//        }


        
    }
}
