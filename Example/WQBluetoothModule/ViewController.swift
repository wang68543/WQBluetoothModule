//
//  ViewController.swift
//  WQBluetoothModule
//
//  Created by WangQiang68543 on 03/12/2018.
//  Copyright (c) 2018 WangQiang68543. All rights reserved.
//

import UIKit
import WQBluetoothModule

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
      
        
        
        WQBLEManager.manager.openCenteralManager { (manager, error) in
            if error == nil {
                manager.startScanDevices { (mgr, devices, error) in
                    if !devices.isEmpty {
                        devices.forEach { debugPrint( $0.peripheral.name ?? "没有名字" ) }
                        for device in devices {
                            if let _ = device.peripheral.name?.range(of: "UART52"){
                                mgr.stopScanDevices();
                                mgr.createBLEConnection(for: device.peripheral) { (error) in
                                    debugPrint(error?.errorDescription ?? "连接成功")
                                    guard error == nil else { return }
                                    WQBLERequest.requestSetDateTime().response { (reponse, error) in
                                        debugPrint(error?.errorDescription ?? "发送成功")
                                    }
                                }
                                break
                            }
                        }
//                        mgr.stopScanDevices()
//                        mgr.createBLEConnection(for: devices.first!.peripheral){ error in
//                            guard error == nil else {
//                                return
//                            }
//                           let request = WQBLEDataRequest(data: Data(), response: 84)
//                            request.validation{ (data) -> Data? in
//                                //在这里校验数据
//                                return nil
//                            }.response { (response, error) in
//                                //响应结果
//                            }
//                        }
                    }else {
                        debugPrint(error!.localizedDescription)
                    }
                }
            }else{
                debugPrint(error!.localizedDescription)
                if case WQBLEError.adapterFailed(reason: .statePoweredOff) = error!  {
                    manager.openBluetoothSetting()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

