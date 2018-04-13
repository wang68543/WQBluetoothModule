//
//  WQBLEError.swift
//  Pods
//
//  Created by hejinyin on 2018/3/16.
//

import Foundation
import CoreBluetooth

public enum WQBLEError:Error{
    public enum adapterReason {
        case stateUnknown
        case stateResetting
        case stateUnsupported
        case stateUnauthorized
        case statePoweredOff
//        case statePoweredOn
    }
    case scanTimeOut//扫描设备超时
    
    public enum peripheralFailedReason {
        case closed
        case disconnected
        case moreConnected //多个连接设备
        case failToConnect(error: Error?)
        case notFoundServices(error: Error?)
        case notFoundCharacteristic(error: Error?)
        
//        case unKnownFailed(message: String)
        
    }
    public enum writeFailedReason {
        case notPermission(message: String?)
        case notFoundService
        case notFoundCharacteristic
        case notFoundDescriptor
        case enableNotifyFailed(error: Error?)
        case disabledNotifyFailed(error: Error?)
        case unableConnectCharacteristic(error: Error?)
        case failed(error: Error?)
    }
    
    public enum readFailedReason {
        case noData(error : Error?)
        case validationFailed(message: String)
        case failed(error: Error?)
    }
//    case connectTimeOut //连接超时 
    case adapterFailed(reason: adapterReason)
    case connectionFailed(reason: peripheralFailedReason)
    case writeFailed(reason: writeFailedReason)
    case readFailed(reason: readFailedReason)
    
//    case errorMessage(message: String)
//    case genralError(error: Error)
    
    //根据蓝牙状态初始化
    init(stateRawValue state: Int) {
        if #available(iOS 10.0, *) {
            switch state {
                case CBManagerState.unknown.rawValue:
                    self = .adapterFailed(reason: .stateUnknown)
                case CBManagerState.resetting.rawValue:
                    self = .adapterFailed(reason: .stateResetting)
                case CBManagerState.unsupported.rawValue:
                    self = .adapterFailed(reason: .stateUnsupported)
                case CBManagerState.unauthorized.rawValue:
                    self = .adapterFailed(reason: .stateUnauthorized)
                case CBManagerState.poweredOff.rawValue:
                    self = .adapterFailed(reason: .statePoweredOff)
                case CBManagerState.poweredOn.rawValue:
                    fatalError("蓝牙是正常可用状态, 所以无法创建错误")
                default :
                    fatalError("未知的蓝牙状态")
            }
        }else {
            switch state {
                case 0:
                    self = .adapterFailed(reason: .stateUnknown)
                case 1:
                    self = .adapterFailed(reason: .stateResetting)
                case 2:
                    self = .adapterFailed(reason: .stateUnsupported)
                case 3:
                    self = .adapterFailed(reason: .stateUnauthorized)
                case 4:
                    self = .adapterFailed(reason: .statePoweredOff)
                case 5:
                    fatalError("蓝牙是可用状态,没有出错 所以无法创建错误")
                default :
                    fatalError("未知的蓝牙状态")
            }
        }
    }

}
extension WQBLEError {
    public var isAdapterFailedError:Bool {
        if case .adapterFailed = self {return true}
        return false
    }
    public var isConnectionFailedError:Bool {
        if case .connectionFailed = self {return true}
        return false
    }
    public var isWriteFailedError:Bool {
        if case .writeFailed = self {return true}
        return false
    }
    public var isReadFailedError:Bool {
        if case .readFailed = self {return true}
        return false
    }
}

extension WQBLEError: LocalizedError {
  public var errorDescription: String? {
        switch self {
        case .scanTimeOut:
            return "没有发现更多的设备了"
//        case .connectTimeOut:
//            return "长时间没有连接到设备"
//        case .genralError(let error ):
//            return error.localizedDescription
        case .adapterFailed(let reason):
            return reason.localizedDescription
//        case .errorMessage(let message):
//            return message
        case .connectionFailed(let reason):
            return reason.localizedDescription
        case .writeFailed(let reason):
            return reason.localizedDescription
        case .readFailed(let reason):
            return reason.localizedDescription
        }
    }
}
extension WQBLEError.readFailedReason {
    var localizedDescription: String {
        switch self {
        case .noData(let error):
            if let err = error {
                return err.localizedDescription
            }else {
                return "没有数据"
            }
        case .validationFailed(let message):
             return message
        case .failed(let error):
            if let err = error {
                return err.localizedDescription
            }else {
                return "数据读取失败"
            }
        }
    
    }
}
extension WQBLEError.writeFailedReason {
    var localizedDescription: String {
        switch self {
        case .notFoundService:
            return "没有找到对应的服务"
        case .notFoundCharacteristic:
            return "没有找到对应的特征"
        case .notFoundDescriptor:
            return "没要找到对应的描述"
        case .notPermission(let message):
            if let msg = message {
                return msg
            }else {
                return "没有写的权限"
            }
        case .enableNotifyFailed(let error):
            if let err = error {
                return err.localizedDescription
            }else {
                return "监听特征的notify失败"
            }
        case .unableConnectCharacteristic(let error):
            if let err = error {
                return err.localizedDescription
            }else {
                return "无法连接到特征"
            }
        case .disabledNotifyFailed(let error):
            if let err = error {
                return err.localizedDescription
            }else {
                return "关闭特征的notify失败"
            } 
        case .failed(let error):
            if let err = error {
                 return err.localizedDescription
            }else {
                return "写入失败"
            }
        }
    }
}

extension WQBLEError.adapterReason {
    var localizedDescription: String {
        switch self {
        case .stateUnknown:
            return "蓝牙还未初始化"
        case .stateResetting:
            return "蓝牙正在重启"
        case .stateUnsupported:
            return "当前设备不支持蓝牙功能"
        case .stateUnauthorized:
            return "当前应用没有使用蓝牙权限,请前往设置开启q权限"
        case .statePoweredOff:
            return "请打开蓝牙开关"
        }
    }
}
extension WQBLEError.peripheralFailedReason {
    var localizedDescription: String {
        switch self {
        case .closed:
            return "关闭连接了"
        case .disconnected:
            return "设备已断开连接"
        case .moreConnected:
            return "有多个连接设备无法找到指定的设备"
        case .failToConnect(let error):
            if let err = error {
                return err.localizedDescription
            }else {
                return "创建连接失败"
            }
        case .notFoundServices(let error):
            if let err = error {
                return err.localizedDescription
            }else {
                return "未发现指定的服务"
            }
        case .notFoundCharacteristic(let error):
            if let err = error {
                return err.localizedDescription
            }else {
                return "未发现指定的描述"
            }
//        case .unKnownFailed(let message):
//            return message
        }
    }
    
}


