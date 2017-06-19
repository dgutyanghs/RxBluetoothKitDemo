//
//  ViewController.swift
//  testRxBluetoothKit
//
//  Created by  BlueYang on 2017/6/19.
//  Copyright © 2017年  BlueYang. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import CoreBluetooth

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    private let cellID =  "bluetootdevicecell"
    
    private var isScanInProgress = false
    private var scheduler: ConcurrentDispatchQueueScheduler!
    private let manager = BluetoothManager(queue: .main)
    private var scanningDisposable: Disposable?
  
    /// RxBluetoothKit variable : 
    fileprivate var peripheralsArray: [ScannedPeripheral] = []
    
    public func rightItemDidClicked(_ sender:UIBarButtonItem) {
        print("right item did clicked")
        if isScanInProgress {
            self.stopScanning()
            sender.title = "start scan"
        }else {
            self.startScanning()
            sender.title = "stop scan"
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let rightItem = UIBarButtonItem.init(title: "scan", style: UIBarButtonItemStyle.done, target: self, action: #selector( rightItemDidClicked(_ :)))
    
            navigationItem.rightBarButtonItem = rightItem
        
        tableView.dataSource = self
        tableView.delegate   = self
        
        tableView.register(ScannedPeripheralCell.self, forCellReuseIdentifier: cellID)
    }
    
    private func addNewScannedPeripheral(_ peripheral: ScannedPeripheral) {
        let mapped = peripheralsArray.map{ $0.peripheral }
        if let index = mapped.index(of: peripheral.peripheral) {
           peripheralsArray[index] = peripheral
        }else {
            self.peripheralsArray.append(peripheral)
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func stopScanning() {
        scanningDisposable?.dispose()
        isScanInProgress = false
        self.title = "normal"
    }
    
    private func startScanning() {
        
        self.title = "scanning"
        isScanInProgress = true
         
        let scanningObserable = manager.rx_state.share()
        
       _ = scanningObserable
        .flatMap {_ in self.manager.scanForPeripherals(withServices:nil, options:nil) }
        .subscribeOn(MainScheduler.instance)
        .subscribe(onNext: {
                self.addNewScannedPeripheral($0)
            }, onError: { error in
                print("!!!error: \(error)")
        })
        
       
        /// 蓝牙未打开，提示用户
        _ = scanningObserable
            .filter {
                $0 != .poweredOn
            }
            .subscribe(onNext: { _ in
                self.showMessage("bluetooth", msg: "pls turn on bluetooth first")
            })
    }

    private func showMessage(_ title:String, msg:String) {
//       UIAlertController *ctrl
        let ctrl = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        ctrl.addAction(action)
        
        self.present(ctrl, animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let peripheral = peripheralsArray[indexPath.row]
        if let peripheralCell = cell as? ScannedPeripheralCell {
            peripheralCell.configure(with: peripheral)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralsArray.count
    }

}

extension ScannedPeripheralCell {
    func configure(with peripheral:ScannedPeripheral)  {
        self.textLabel?.text = peripheral.advertisementData.localName ?? peripheral.peripheral.identifier.uuidString
    }
}

