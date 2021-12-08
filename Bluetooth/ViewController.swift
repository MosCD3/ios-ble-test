//
//  ViewController.swift
//  Bluetooth
//
//  Created by Mostafa Gamal on 2021-12-07.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var cbCentralManager: CBCentralManager!
    var peripheral : CBPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cbCentralManager = CBCentralManager(delegate: self, queue: nil)
    }


}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("CBCentralManagerDelegate -> centralManagerDidUpdateState()")
        if central.state == .poweredOn {
          central.scanForPeripherals(withServices: nil, options: nil)
          print("Scanning...")
         }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
      guard peripheral.name != nil else {return}
      
      print("Device found:\(peripheral.name)")
        
      if peripheral.name! == "Thunder Sense #33549" {
      
        print("Another device Found!")
        //stopScan
        cbCentralManager.stopScan()
        
        //connect
        cbCentralManager.connect(peripheral, options: nil)
        self.peripheral = peripheral
       }
    }
}

