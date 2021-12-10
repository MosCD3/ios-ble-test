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
    var itemsTableView: UITableView?
    var detectedDevices: [String] = []
    var isReadyForScan: Bool = false
    var isScanning: Bool = false {
        didSet {
            scanButton?.setTitle(isScanning ? "Stop" : "Scan", for: .normal)
        }
    }
    var scanButton: UIButton?
    lazy var tableHeader: UIView = {
        let wrapper = UIView()
        let button = UIButton()
        button.setTitle("Scan", for: .normal)
        wrapper.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false;
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor).isActive = true
        button.addTarget(self, action: #selector(startScan), for: .touchUpInside)
        scanButton = button
        wrapper.backgroundColor = .systemGray5
        wrapper.frame.size.height = 70
        return wrapper
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configTableView()
        
        cbCentralManager = CBCentralManager(delegate: self, queue: nil)
        cbCentralManager.stopScan()
    }
    
    func configTableView(){
        itemsTableView = UITableView()
        view.addSubview(itemsTableView!)
        itemsTableView?.translatesAutoresizingMaskIntoConstraints = false;
        itemsTableView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        itemsTableView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        itemsTableView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        itemsTableView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        itemsTableView?.tableHeaderView = tableHeader
        itemsTableView?.dataSource = self
        itemsTableView?.delegate = self
        itemsTableView?.allowsSelection = true;
        
    }
    
    @objc func startScan(){
        print("Please start scan")
        guard isReadyForScan else {  return }
        
        if isScanning {
            isScanning = false
            cbCentralManager.stopScan()
        } else {
            isScanning = true
            cbCentralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        
        
    }
    
    func deviceFound(name: String){
        
        print("Adding device:\(name)")
        if let _ = detectedDevices.first(where: {$0 == name }) {
            print("This device is already added");
            return
        }
        detectedDevices.append(name)
        itemsTableView?.reloadData()
    }
    
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detectedDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "CELL")
        cell.textLabel?.text = detectedDevices[indexPath.row]
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    //    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //        return 70
    //    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 70
//    }
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//
//        return wrapper
//    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("slected row at \(indexPath.row)")
    }
    
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("CBCentralManagerDelegate -> centralManagerDidUpdateState()")
        if central.state == .poweredOn {
            //          central.scanForPeripherals(withServices: nil, options: nil)
            isReadyForScan = true
            print("Bluetooth on and you can start scanning now")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            deviceFound(name: name)
        }
        
//        guard peripheral.name != nil else {return}
//        print("Device found:\(peripheral.name)")
//
//        if peripheral.name! == "Thunder Sense #33549" {
//
//            print("Another device Found!")
//            //stopScan
//            cbCentralManager.stopScan()
//
//            //connect
//            cbCentralManager.connect(peripheral, options: nil)
//            self.peripheral = peripheral
//        }
    }
}

