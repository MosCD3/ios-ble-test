//
//  ViewController.swift
//  Bluetooth
//
//  Created by Mostafa Gamal on 2021-12-07.
//

import UIKit
import CoreBluetooth
import os

struct TransferService {
    var serviceUUID: CBUUID
    var characteristicUUID: CBUUID
    static let serviceUUIDDef = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
    static let characteristicUUIDDef = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
}

class ViewController: UIViewController {
    
    var cbCentralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager?
    var transfereService: TransferService?
    var transferCharacteristic: CBCharacteristic?
    var srTransferCharacteristic: CBMutableCharacteristic?
    var data = Data()
    var dataToSend = Data()
    var sendDataIndex: Int = 0
    var connectedCentral: CBCentral?
    var sendingEOM = false
    
    var peripheral : CBPeripheral?
    var itemsTableView: UITableView?
    var detectedPeripherals: [CBPeripheral] = []
    var isReadyForScan: Bool = false
    var isScanning: Bool = false {
        didSet {
            scanButton.setTitle(isScanning ? "Stop" : "Scan", for: .normal)
        }
    }
    
    private let uuidTxtFldTag: Int = 320
    
    func getDefaultButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .blue
        return button
    }
    
    func getDefaultInput() -> UITextField {
        let input = UITextField()
        input.backgroundColor = .brown
        input.translatesAutoresizingMaskIntoConstraints = false
        return input
    }
    
    lazy var scanButton: UIButton = {
        let button = getDefaultButton()
        button.setTitle("Scan", for: .normal)
        button.addTarget(self, action: #selector(startScan), for: .touchUpInside)
        
        return button
    }()
    
    lazy var messageInput: UITextField = {
        let fld = getDefaultInput()
        fld.placeholder = "UUID"
        fld.delegate = self
        fld.tag = uuidTxtFldTag
        fld.autocorrectionType = .no
        return fld
    }()
    
    lazy var promoteButton: UIButton = {
        let button = getDefaultButton()
        button.setTitle("Promote", for: .normal)
        button.addTarget(self, action: #selector(startPromote), for: .touchUpInside)
        return button
    }()
    
    lazy var tableHeader: UIView = {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.spacing = 5
        wrapper.alignment = .center
        wrapper.distribution = .fillEqually
        wrapper.backgroundColor = .systemGray5
        wrapper.frame.size.height = 140
        
        
        wrapper.addArrangedSubview(scanButton)
        scanButton.widthAnchor.constraint(equalTo: wrapper.widthAnchor).isActive = true
        
        wrapper.addArrangedSubview(promoteButton)
        promoteButton.widthAnchor.constraint(equalTo: wrapper.widthAnchor).isActive = true
        
        wrapper.addArrangedSubview(messageInput)
        messageInput.widthAnchor.constraint(equalTo: wrapper.widthAnchor).isActive = true
        
        
        
        //Adding promote button
        //        let promoteRow = UIStackView()
        //        promoteRow.axis = .horizontal
        //        promoteRow.spacing = 10
        //        promoteRow.alignment = .center
        
        //        promoteRow.addArrangedSubview(promoteButton)
        //        promoteRow.addArrangedSubview(uuidInput)
        //        uuidInput.heightAnchor.constraint(equalTo: promoteRow.heightAnchor, constant: 0).isActive = true
        //        promoteButton.heightAnchor.constraint(equalTo: promoteRow.heightAnchor, constant: 0).isActive = true
        //        wrapper.addArrangedSubview(promoteRow)
        //        promoteRow.widthAnchor.constraint(equalTo: wrapper.widthAnchor).isActive = true
        
        
        
        return wrapper
    }()
    
    
    var isPromoting: Bool = false {
        didSet {
            if isPromoting {
                promoteButton.setTitle("Promoting Now .. (Click to stop)", for: .normal)
            } else {
                promoteButton.setTitle("Promote Services", for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configTableView()
        
        //Central will allow me to connect to other devices
        cbCentralManager = CBCentralManager(delegate: self, queue: nil)
        
        //Peripheral will allow me to promote my services to other devices
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
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
            //            cbCentralManager.scanForPeripherals(withServices: nil, options: nil)
            print("Start scanning for prefs..")
            cbCentralManager.scanForPeripherals(withServices: [TransferService.serviceUUIDDef], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            
        }
        
        
    }
    
    @objc func startPromote() {
        print("Please start promote")
        if isPromoting {
            peripheralManager?.stopAdvertising()
            isPromoting = false
        } else {
            peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUIDDef]])
            isPromoting = true
        }
        
    }
    
    func deviceFound(periph: CBPeripheral){
        
//        print("Adding peripheral:\(periph.defaultName)")
        if let _ = detectedPeripherals.first(where: {$0.identifier == periph.identifier }) {
//            print("This device is already added");
            return
        }
        
        print("Adding peripheral:\(periph.defaultName), ID:\(periph.identifier)")
        detectedPeripherals.append(periph)
        itemsTableView?.reloadData()
    }
    
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detectedPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "CELL")
        
        var name = detectedPeripherals[indexPath.row].defaultName
        if let _ = detectedPeripherals[indexPath.row].name {
            name = detectedPeripherals[indexPath.row].name!
        }
        cell.textLabel?.text = name
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
        let peripheral = detectedPeripherals[indexPath.row]
        os_log("Attempt tp connect to peripheral %@", peripheral)
        cbCentralManager.connect(peripheral, options: nil)
        
    }
    
}

//MARK: TextField Delegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
//        if textField.tag == uuidTxtFldTag, let uuid = textField.text {
//            setTransfereService(uuid: uuid)
//        }
        return true
    }
}

//MARK: Central Delegate

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("CBCentralManagerDelegate -> centralManagerDidUpdateState()")
        if central.state == .poweredOn {
            //          central.scanForPeripherals(withServices: nil, options: nil)
            isReadyForScan = true
            print("Bluetooth on and you can start scanning now")
        } else {
            print("Bluetooth not connected")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Discovered \(String(describing: peripheral.name)) at \(RSSI.intValue) id \(peripheral.identifier)")
        
        if let name = peripheral.name {
            peripheral.defaultName = name
        }
        
        deviceFound(periph: peripheral)
        
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
    
    /*
     *  We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("Peripheral Connected")
        
        // Stop scanning
        if isScanning {
            startScan() //this will stop the scan
        }
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([TransferService.serviceUUIDDef])
    }
}



//MARK: Peripheral Delegate
extension ViewController: CBPeripheralManagerDelegate {
    
    /*
     *  Required protocol method.  A full app should take care of all the possible states,
     *  but we're just waiting for to know when the CBPeripheralManager is ready
     *
     *  Starting from iOS 13.0, if the state is CBManagerStateUnauthorized, you
     *  are also required to check for the authorization state of the peripheral to ensure that
     *  your app is allowed to use bluetooth
     */
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            print("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            print("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            print("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *) {
                switch peripheral.authorization {
                case .denied:
                    print("You are not authorized to use Bluetooth")
                case .restricted:
                    print("Bluetooth is restricted")
                default:
                    print("Unexpected authorization")
                }
            } else {
                // Fallback on earlier versions
            }
            return
        case .unknown:
            print("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            print("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            print("A previously unknown peripheral manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }
    
    
    /*
     *  Catch when someone subscribes to our characteristic, then start sending them data
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        os_log("peripheralManager>didSubscribeTo %@", characteristic)
        // Get the data
        guard let message = messageInput.text else {
            os_log("Error[374] Cannot send data while no input message!")
            return
        }
        dataToSend = message.data(using: .utf8)!
        
        // Reset the index
        sendDataIndex = 0
        
        // save central
        connectedCentral = central
        
        // Start sending
        sendData()
    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        os_log("peripheralManagerIsReady> Sending data ..")
        // Start sending again
        sendData()
    }
}

//MARK: Connected Peripheral Delegate
extension ViewController: CBPeripheralDelegate {
    /*
     *  The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        os_log("peripheral: didDiscoverServices error: Error?")
        
        if let error = error {
            os_log("Error discovering services: %s", error.localizedDescription)
            //Cleanup
            return
        }
        
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUIDDef], for: service)
        }
    }
    
    /*
     *  The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        os_log("peripheral: didDiscoverCharacteristicsFor service: CBService")
        
        // Deal with errors (if any).
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
//            cleanup()
            return
        }
        
        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUIDDef {
            // If it is, subscribe to it
            transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
        
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /*
     *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("peripheral: didUpdateNotificationStateFor characteristic: CBCharacteristic")
        
        // Deal with errors (if any)
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        }
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid == TransferService.characteristicUUIDDef else { return }
        
        if characteristic.isNotifying {
            // Notification has started
            os_log("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            os_log("Notification stopped on %@. Disconnecting", characteristic)
//            cleanup()
        }
        
    }
    
    
    /*
     *   This callback lets us know more data has arrived via notification on the characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        os_log("peripheral: didUpdateValueFor characteristic: CBCharacteristic")
        
        // Deal with errors (if any)
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
//            cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value,
            let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        os_log("Received %d bytes: %s", characteristicData.count, stringFromData)
        
        // Have we received the end-of-message token?
        if stringFromData == "EOM" {
            // End-of-message case: show the data.
            // Dispatch the text view update to the main queue for updating the UI, because
            // we don't know which thread this method will be called back on.
            DispatchQueue.main.async() {
                self.messageInput.text = String(data: self.data, encoding: .utf8)
            }
            
            // Write test data
//            writeData()
        } else {
            // Otherwise, just append the data to what we have previously received.
            data.append(characteristicData)
        }
    }
}


//MARK: Extentions
extension ViewController {
    
    private func setTransfereService(uuid: String){
        print("Setting service UUID to:\(uuid)")
        if transfereService == nil {
            transfereService = TransferService(serviceUUID: CBUUID(string: uuid), characteristicUUID: CBUUID(string: "\(uuid)_\(uuid)"))
            return
        }
        
        transfereService?.serviceUUID = CBUUID(string: uuid)
        transfereService?.characteristicUUID =  CBUUID(string: "\(uuid)_\(uuid)")
    }
    private func setupPeripheral() {
        
        
        print("Setting up peripheral")
        
        
        guard let _ = peripheralManager else {
            print("Error[283] peripheralManager undefined!")
            return
            
        }
        // Build our service.
        
        // Start with the CBMutableCharacteristic.
        let transferCharacteristic = CBMutableCharacteristic(type: TransferService.characteristicUUIDDef,
                                                             properties: [.notify, .writeWithoutResponse],
                                                             value: nil,
                                                             permissions: [.readable, .writeable])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: TransferService.serviceUUIDDef, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager?.add(transferService)
        
        // Save the characteristic for later.
        self.srTransferCharacteristic = transferCharacteristic
        
    }
    
    private func sendData() {
        os_log("sendData")
        guard let transferCharacteristic = srTransferCharacteristic else {
            os_log("Error[557] Transfer characteristics not set!")
            return
        }
        
        // First up, check if we're meant to be sending an EOM
        if sendingEOM {
            // send it
            let didSend = peripheralManager?.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            // Did it send?
            if didSend ?? false {
                // It did, so mark it as sent
                sendingEOM = false
                os_log("Sent: EOM")
            }
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        // Is there any left to send?
        if sendDataIndex >= dataToSend.count {
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        while didSend {
            
            // Work out how big it should be
            var amountToSend = dataToSend.count - sendDataIndex
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            // Copy out the data we want
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            // Send it
            didSend = peripheralManager?.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil) ?? false
            
            // If it didn't work, drop out and wait for the callback
            if !didSend {
                os_log("dropping out!")
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            os_log("Sent %d bytes: %s", chunk.count, String(describing: stringFromData))
            
            // It did send, so update our index
            sendDataIndex += amountToSend
            // Was it the last one?
            if sendDataIndex >= dataToSend.count {
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                sendingEOM = true
                
                //Send it
                let eomSent = peripheralManager?.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
                
                if eomSent ?? false {
                    // It sent; we're all done
                    sendingEOM = false
                    os_log("Sent: EOM")
                }
                return
            }
        }
    }
}


extension CBPeripheral {
    struct Holder {
        static var _myComputedProperty:String = "_Unknown"
    }
    
    var defaultName: String  {
        get {
            return Holder._myComputedProperty
        }
        set(newValue) {
            Holder._myComputedProperty = newValue
        }
    }
}



