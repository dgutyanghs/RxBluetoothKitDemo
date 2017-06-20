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
//import CoreBluetooth
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private let cellID =  "bluetootdevicecell"
    
    private var isScanInProgress = Variable<Bool>(false)
    private var scheduler: ConcurrentDispatchQueueScheduler!
    private let manager = BluetoothManager(queue: .main)
    private var scanningDisposable: Disposable?
  
    /// RxBluetoothKit  ScannedPeripheral
    fileprivate var peripheralsArray = Variable<[ScannedPeripheral]>([])
    
    let bag = DisposeBag()
    
    public func rightItemDidClicked(_ sender:UIBarButtonItem) {
        isScanInProgress.value = !isScanInProgress.value
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let rightItem = UIBarButtonItem.init(title: "scan", style: UIBarButtonItemStyle.done, target: self, action: #selector( rightItemDidClicked(_ :)))
        navigationItem.rightBarButtonItem = rightItem
        
        tableView.register(ScannedPeripheralCell.self, forCellReuseIdentifier: cellID)
        /// tableView 的 cell 生成
        peripheralsArray.asObservable().bind(to: tableView.rx.items(cellIdentifier:cellID)) {
            _, ScannedPeripheral, cell in
            if let cellToUse = cell as? ScannedPeripheralCell {
                cellToUse.configure(with: ScannedPeripheral)
            }
        }.addDisposableTo(bag)
        
        
        ///scan item 状态
        isScanInProgress.asObservable()
        .skip(1) //skip the initial value
        .subscribe(onNext:{
           [weak self]  status in
            if status {
                self?.startScanning()
                
            }else {
                self?.stopScanning()
            }
        }).addDisposableTo(bag)
    }
    
    private func addNewScannedPeripheral(_ peripheral: ScannedPeripheral) {
        let mapped = peripheralsArray.value.map{ $0.peripheral }
        if let index = mapped.index(of: peripheral.peripheral) {
           peripheralsArray.value[index] = peripheral
        }else {
            self.peripheralsArray.value.append(peripheral)
        }
    }
    
    private func stopScanning() {
        scanningDisposable?.dispose()
        self.title = "Peripherals"
        navigationItem.rightBarButtonItem?.title = "scan"
    }
    
    private func startScanning() {
        
        self.title = "scanning"
        navigationItem.rightBarButtonItem?.title = "stop scan"
        let scanningObserable = manager.rx_state.share()
        
       scanningDisposable = scanningObserable
        .flatMap {_ in self.manager.scanForPeripherals(withServices:nil, options:nil) }
        .subscribeOn(MainScheduler.instance)
        .subscribe(onNext: {
                self.addNewScannedPeripheral($0)
            }, onError: { error in
                print("!!!error: \(error)")
        })
        
       
        /// 蓝牙未打开，提示用户
        _ = scanningObserable
            .takeLast(1)
            .filter {
                $0 != .poweredOn
            }
            .subscribe(onNext: { _ in
                self.showMessage("bluetooth", msg: "pls turn on bluetooth first")
            }).addDisposableTo(bag)
    }

    private func showMessage(_ title:String, msg:String) {
        let ctrl = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        ctrl.addAction(action)
        
        self.present(ctrl, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ScannedPeripheralCell {
    func configure(with peripheral:ScannedPeripheral)  {
        self.textLabel?.text = peripheral.advertisementData.localName ?? peripheral.peripheral.identifier.uuidString
    }
}

