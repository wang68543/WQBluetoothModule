//
//  WQBLEResponse.swift
//  Pods
//
//  Created by hejinyin on 2018/3/21.
//

import Foundation

public struct WQBLEResponse {
   
    /// 蓝牙发过来的原始值
    public let responseValue: Array<UInt8>
    /// 校验失败 就是出错了
    public var isCheckedSuccess: Bool = true
    /// 有效数据部分 (排除公共的头部跟校验和)
    public let validData: Array<UInt8>?
    
    public let responseCmd: UInt8?
    /// 接收的数据是否分包
    public var isPart: Bool = false
    
    public init(response cmd:UInt8?, value:Array<UInt8>,checked isSuccess:Bool = false, vaildate data:Array<UInt8>? = nil) {
        responseCmd = cmd
        responseValue = value
        isCheckedSuccess = isSuccess
        validData = data
    }
}
