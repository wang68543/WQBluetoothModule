//
//  WQBLEManager.swift
//  Pods
//
//  Created by hejinyin on 2018/3/12.
//

import Foundation
import CoreBluetooth

public typealias WQCompeletionHandle  = (WQBLEError?) -> Void

public typealias WQAdapterCompeletion = (WQBLEManager, WQBLEError?) -> Void
 
public class WQBLEManager:NSObject{
    //扫描到设备
    public typealias BLEDevice = (peripheral: CBPeripheral, advertisementData: [String : Any]? , RSSI: NSNumber? )
    ///扫描周边设备完成回调
    public typealias ScanCompeletion = (WQBLEManager,[BLEDevice],WQBLEError?) -> Void
    
    /// 当前正在连接、以及正在重连的设备
    public private(set) var sessions:[UUID: WQBLESession] = [:]
  
    /// 初始化蓝牙适配器
    private var openCentralCompeletion:WQAdapterCompeletion?
    
    /// 扫描完成
    private var scanCompeletionHandle:ScanCompeletion?
    /// 设备连接回调
    private var connectedsCompeletion:[UUID: WQCompeletionHandle] = [:]
    // 正在建立连接的设备
    private var connectingPeripherals:[CBPeripheral] = []

    /// 验证
    var validations:[UUID:[String:WQBLEDataValidation]] = [:]
    
    /// 公共的解析部分
    var commonValidate:WQBLEDataValidation?
    
    lazy private var centralManager:CBCentralManager =  { [unowned self] in
        let central = CBCentralManager.init(delegate: self, queue: nil)
        return central
    }()
    
    public static let manager = WQBLEManager()
}

extension WQBLEManager{
    
//    @discardableResult
    public func openBluetoothSetting() {
        let app = UIApplication.shared
        if #available(iOS 10.0, *) {
           if let url = URL(string: "App-Prefs:root=Bluetooth"),
            app.canOpenURL(url){ app.open(url, options: [:]) }
        } else {
            if let url = URL(string: "prefs:root=General&path=Bluetooth"),
                app.canOpenURL(url){ app.openURL(url) }
        }
        
    }
    /// 开启手机蓝牙主模式
    public func openCenteralManager(queue: DispatchQueue? = nil, options: [String : Any]? = nil ,compeletion: WQAdapterCompeletion? ) {
        debugPrint(self)
        centralManager = CBCentralManager.init(delegate: self, queue: queue, options: options)
        
        openCentralCompeletion = compeletion
    }
    
    /// 扫描周边设备
    public func startScanDevices(withServices services: [CBUUID]? = nil,
                                 options: [String : Any]? = nil,
                                 time timeOut:TimeInterval = 60,
                                 scanResponse:@escaping ScanCompeletion){
        
        guard centralManager.state == .poweredOn else{
            scanResponse(self,[],WQBLEError.init(stateRawValue: centralManager.state.rawValue))
            return
        }
        //超时设置
        WQBLEManager.cancelPreviousPerformRequests(withTarget: self, selector: #selector(bleScanTimeOut), object: nil)
        self.perform(#selector(bleScanTimeOut), with: nil, afterDelay: timeOut)
        
        scanCompeletionHandle = scanResponse
        
        if let uuids = services , !uuids.isEmpty {
            /// 获取 已与本机其它应用建立连接的设备
            let connectedDevices = centralManager.retrieveConnectedPeripherals(withServices: uuids)
            if !connectedDevices.isEmpty {
                var devices:[BLEDevice] = []
                connectedDevices.forEach({ peripheral in
                    devices.append(BLEDevice(peripheral: peripheral,advertisementData:nil,RSSI:nil))
                })
                 scanResponse(self,devices,nil)
            }
        }
        
        if #available(iOS 9.0, *), centralManager.isScanning {
            centralManager.delegate = self
        } else {
            centralManager.scanForPeripherals(withServices: services , options: options)
        }
    }
    
    @objc private func bleScanTimeOut(){
        if let compeletion = scanCompeletionHandle {
            compeletion(self,[],WQBLEError.scanTimeOut)
        }
        scanCompeletionHandle = nil
        self.centralManager.stopScan()
    }
    
    public func stopScanDevices(){
        WQBLEManager.cancelPreviousPerformRequests(withTarget: self, selector: #selector(bleScanTimeOut), object: nil)
        scanCompeletionHandle = nil
        self.centralManager.stopScan()
    }
    public func createBLEConnection(for peripheral:CBPeripheral, compeletion: @escaping WQCompeletionHandle){
        let uuid = peripheral.identifier
        if  centralManager.state != .poweredOn{
            connectedsCompeletion.removeValue(forKey: uuid)
            compeletion( WQBLEError(stateRawValue: centralManager.state.rawValue))
        }else {
            if peripheral.state == .connected {
                if  let _ = sessions[uuid] {
                     compeletion(nil)
                } else {
                    connectedsCompeletion[uuid] = compeletion
                    centralManager(centralManager, didConnect: peripheral)
                }
            }else {
                if let session = sessions[uuid] {//有会话但是设备连接丢失
                    connectedsCompeletion[uuid] = compeletion
                    if !session.isReconnecting && peripheral.state != .connecting{
                       connectingPeripherals.append(peripheral)//这里需要持有设备 否则连接之后会立马断开
                        centralManager.connect(peripheral, options: nil)
                    }
//                    else{
//                        assert(false, "有会话但是设备又没有连接,应该是哪处逻辑出错了")
//                        //这里暂时处理就是
//                    }
                }else {
                    connectedsCompeletion[uuid] = compeletion
                    if peripheral.state != .connecting {
                        connectingPeripherals.append(peripheral)
                        centralManager.connect(peripheral, options: nil)
                    }
                }
            }
        }
    }
    public func closeBLEConnection(for peripheral:CBPeripheral){
        let uuid = peripheral.identifier
        connectedsCompeletion.removeValue(forKey: uuid)
        if  let session = sessions[uuid] {
            session.didClosedConnect();
            sessions.removeValue(forKey: uuid)
        }
        //这里 会回调代理的didDisconnectPeripheral方法
        centralManager.cancelPeripheralConnection(peripheral)
    }
    //重新 连接设备
    public func reconnection(for peripheral:CBPeripheral ,compeletion:@escaping WQCompeletionHandle) {
        let devices = centralManager.retrievePeripherals(withIdentifiers:[peripheral.identifier])
        if let device = devices.first {
            createBLEConnection(for: device, compeletion: compeletion)
        }else {
            var services:[CBUUID] = []
            peripheral.services?.forEach{services.append($0.uuid)}
            var connectedDevice: CBPeripheral? = nil
            
            //           CBCentralManagerScanOptionAllowDuplicatesKey key值是NSNumber,默认值为NO表示不会重复扫描已经发现的设备,如需要不断获取最新的信号强度RSSI所以一般设为YES了
            startScanDevices(withServices: services, time: 15, scanResponse: { (manager, bleDevices, error) in
                    if let err = error {
                        compeletion(err)
                    }else {
                        if connectedDevice == nil {
                            for (bleDevice,_,_) in bleDevices {
                                if bleDevice.identifier.uuidString == peripheral.identifier.uuidString {
                                    manager.stopScanDevices()
                                    connectedDevice = bleDevice
                                    break
                                }
                            }
                            if let device = connectedDevice {
                                manager.createBLEConnection(for: device, compeletion: compeletion)
                            }
                        }else {
                            manager.stopScanDevices()
                        }
                }
            })
        }
    }
 
}

extension WQBLEManager {
    public func getSession(with identifier:UUID?) -> WQBLESession?{
        if let identifier = identifier {
            return sessions[identifier] ?? (sessions.count == 1 ? sessions.first!.value : nil)
        }else {
            if sessions.count > 1 {  assert(false, "当连接多个设备的时候必须制定设备id")   }
            return sessions.count == 1 ? sessions.first!.value : nil
        }
    }
    func getValidation(identifier:UUID?,characteristicId:String) -> WQBLEDataValidation {
        let identifier =  identifier ?? (sessions.count == 1 ? sessions.first!.value.peripheral.identifier : nil)
        
        if let identifier = identifier {
            if let periphralValidations = validations[identifier] ,
                let validation = periphralValidations[characteristicId]{
                    return validation
            }else {
                if let validation = commonValidate {
                    return validation
                }else {
                    fatalError("没有具体的验证方式必须要有公共的验证方式")
                }
            }
        }else {
            if let validation = commonValidate {
                return validation
            }else {
                fatalError("没有具体的验证方式必须要有公共的验证方式")
            }
        }
    }
}
extension WQBLEManager {
    public func requestSession(for request:WQBLEDataRequest, compeletion:@escaping WQValueChanged){
        if let session = getSession(with: request.identifier) {
            session.requestTask(for: request)
        }else {
            compeletion(nil,WQBLEError.connectionFailed(reason: .disconnected))
        }
    }
    public func subscribeSession(for request:WQBLESubscribeRequest){
        guard let compeletion = request.isSuccessSubscribe else {
            assert(false, "订阅要有订阅回调")
            return
        }
        if let session = getSession(with: request.identifier) {
            session.subscribeTask(for: request)
        }else {
            compeletion(WQBLEError.connectionFailed(reason: .disconnected))
        }
    }
    public func validation(identifier:UUID?,characteristicId:String,completion:@escaping WQBLEDataValidation){
        if let identifier = identifier {
            if validations[identifier] == nil {
                validations[identifier] = [:]
            }
              validations[identifier]![characteristicId] = completion
        }else {
            if sessions.count == 1 {
                let identifier = sessions.first!.value.peripheral.identifier
                if validations[identifier] == nil {
                    validations[identifier] = [:]
                }
                validations[identifier]![characteristicId] = completion
            }else {
                //没有找到指定的
                assert(false, "没有验证数据的方法")
            }
        }
    }
}
extension WQBLEManager:CBCentralManagerDelegate{
    //蓝牙适配器状态改变了
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state != .unknown else {
            debugPrint("等待蓝牙状态继续更新")
            return
        }
        //TODO: -- 如果蓝牙明明是开启的 但是状态确总是 .poweredOff(关闭状态) 那就换一种蓝牙开关打开方式 (例:如果之前是设置里面开启蓝牙的就在上拉选项里面开启蓝牙,否则反着操作)
        debugPrint(central.state.rawValue)
        if central.state == .poweredOn {
            if let openAction = openCentralCompeletion {
                openAction(self,nil)
                openCentralCompeletion = nil
            }else {
                NotificationCenter.default.post(
                    name: Notification.Name.Bluetooth.AdapterDidEnable,
                    object: self,
                    userInfo: [Notification.BleKey.AdapterState: central.state]
                )
            }
        }else{
            if let openAction = openCentralCompeletion {//有初始化回调就不发通知
                openAction(self,WQBLEError.init(stateRawValue: central.state.rawValue))
                openCentralCompeletion = nil
            }else {
                if central.state == .poweredOff {//适配器关闭了
                    //要关闭扫描
                    WQBLEManager.cancelPreviousPerformRequests(withTarget: self, selector: #selector(bleScanTimeOut), object: nil)
                    let error = WQBLEError.adapterFailed(reason: .statePoweredOff)
                    connectedsCompeletion.forEach { $0.value(error) }
                    connectedsCompeletion.removeAll()
                    
                    
                    sessions.forEach { $0.value.didFailedToConnect(error: error) }
                    sessions.removeAll()
                    
                    if let scanHandle = scanCompeletionHandle {
                        scanHandle(self,[],error)
                    }
                    scanCompeletionHandle = nil
                    
                }
                NotificationCenter.default.post(
                    name: Notification.Name.Bluetooth.AdapterDidDisable,
                    object: self,
                    userInfo: [Notification.BleKey.Error: WQBLEError.init(stateRawValue: central.state.rawValue)]
                )
            }
        }
            
    }
    
    //发现设备
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let scanCompeletion = scanCompeletionHandle {
            scanCompeletion(self,[BLEDevice(peripheral: peripheral,advertisementData:advertisementData,RSSI:RSSI)],nil)
        }else{//如果没有回调
            central.stopScan()
        }
    }
    //这里 连接成功就创建 Task任务 
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        var sessionTask:WQBLESession
        
        if let session = sessions[peripheral.identifier] { //是自动重连的
             session.didReconnect(peripheral)
            sessionTask = session
        }else {
          sessionTask = WQBLESession(device:peripheral)
          sessions[peripheral.identifier] = sessionTask
            NotificationCenter.default.post(name: Notification.Name.Bluetooth.PeripheralDidConnected, object: self, userInfo: [Notification.BleKey.Peripheral: peripheral])
        }
        
        let compeletion = connectedsCompeletion[peripheral.identifier]
        compeletion?(nil)
        connectedsCompeletion.removeValue(forKey: peripheral.identifier)
        if let index =  connectingPeripherals.index(of: peripheral) {
            connectingPeripherals.remove(at: index)
        }
//        if !reconnectionPeripheral.contains(peripheral.identifier){
//            //这里 需要判断是否是重连 然后 发出通知
//            NotificationCenter.default.post(name: Notification.Name.Bluetooth.PeripheralDidConnected, object: self, userInfo: [Notification.BleKey.Peripheral: peripheral])
//        }
        
    }
    //建立连接失败
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let compeletion = connectedsCompeletion[peripheral.identifier]
        compeletion?(WQBLEError.connectionFailed(reason: .failToConnect(error: error)))
        connectedsCompeletion.removeValue(forKey: peripheral.identifier)
        
        if let index =  connectingPeripherals.index(of: peripheral) {
            connectingPeripherals.remove(at: index)
        }
    }
    //连接的中途断开了
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        //主动断开连接的 在这之前就删除session了
        guard let session = sessions[peripheral.identifier], peripheral.state != .connected else {
            return
        }
        
        let failedErr = WQBLEError.connectionFailed(reason: .failToConnect(error: error))
        session.didFailedToConnect(error: failedErr)
        
        if session.isNeedToReconnect {
            session.isReconnecting = true
            reconnection(for: peripheral) { [weak self]  error in
                if let err = error { //重连失败了
                    NotificationCenter.default.post(
                        name: Notification.Name.Bluetooth.PeripheralDidDisconnected,
                        object: self,
                        userInfo: [Notification.BleKey.Peripheral: peripheral,Notification.BleKey.Error:err])
                    if let weakSelf = self {
                        weakSelf.sessions.removeValue(forKey: peripheral.identifier)
                    }
                }
            }
        }else {
           sessions.removeValue(forKey: peripheral.identifier)
            NotificationCenter.default.post(
                name: Notification.Name.Bluetooth.PeripheralDidDisconnected,
                object: self,
                userInfo: [Notification.BleKey.Peripheral: peripheral,Notification.BleKey.Error:failedErr])
        }
      
    }
}
