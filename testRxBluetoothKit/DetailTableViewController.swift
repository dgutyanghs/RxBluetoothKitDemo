//
//  DetailTableViewController.swift
//  testRxBluetoothKit
//
//  Created by  BlueYang on 2017/6/22.
//  Copyright © 2017年  BlueYang. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import RxCocoa

class DetailTableViewController: UITableViewController {
    open var peripheral: Peripheral? = nil
    let bag = DisposeBag ()
    fileprivate var servicesArray = Variable<[Service]>([])
    private let cellID =  "detailcell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Connected"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        // TODO: 在servicesArray.asObservable().bind tableView,需要将tableView的dataSource 置空
        tableView.dataSource = nil
        tableView.delegate = nil
        servicesArray.asObservable().bind(to: tableView.rx.items(cellIdentifier:cellID)) {
            _, serv, cell in
            cell.textLabel?.text = serv.uuid.uuidString
        }.addDisposableTo(bag)
        
        
        
        peripheral?.connect()
            .flatMap { $0.discoverServices(nil) }
            .flatMap { Observable.from( $0 ) }
            .subscribe(onNext: {
                [weak self] service in
                print("discovered service: \(service.uuid.uuidString)")
                self?.servicesArray.value.append(service)
                self?.tableView.reloadData()
            }).addDisposableTo(bag)
        
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let peripheral = self.peripheral else {
            return
        }
        
        ViewController.manager.cancelPeripheralConnection(peripheral)
            .subscribe( 
            onError: { (error) in
                print("cancel connect error :\(error.localizedDescription)")
            }, onCompleted: {
                print("\(peripheral.name ?? "device") disconnect")
            }, onDisposed: {
                print("cancelConnection disposed")
            }).addDisposableTo(bag)
    }

}
