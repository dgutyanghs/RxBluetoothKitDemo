//
//  ServicesTableViewController.swift
//  testRxBluetoothKit
//
//  Created by  BlueYang on 2017/6/22.
//  Copyright © 2017年  BlueYang. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import RxCocoa

class ServicesTableViewController: UITableViewController {
    open var peripheral: Peripheral? = nil
    let bag = DisposeBag ()
    fileprivate var servicesArray = Variable<[Service]>([])
//    fileprivate var charactArray = Variable<[Characteristic]>([])
    private let cellID =  "detailcell"
    
    @objc private func rightItemDidClicked(_ sender:UIBarButtonItem) {
        guard let peripheral = self.peripheral else {
            return
        }
        
        ViewController.manager.cancelPeripheralConnection(peripheral)
            .subscribe( 
            onError: { (error) in
                print("cancel connect error :\(error.localizedDescription)")
            }, onCompleted: {
                [weak self] _ in
                print("\(peripheral.name ?? "device") disconnect")
                self?.navigationController?.popViewController(animated: true)
            }, onDisposed: {
                print("cancelConnection disposed")
            }).addDisposableTo(bag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Connected"
        
        
        let rightItem = UIBarButtonItem.init(title: "disconnect", style: UIBarButtonItemStyle.done, target: self, action: #selector(rightItemDidClicked(_ :)))
        navigationItem.rightBarButtonItem = rightItem
        
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
        
        tableView.rx.modelSelected(Service.self).subscribe(onNext: {
            serv in
            let charactVc = CharactTableViewController.init(style: UITableViewStyle.plain)
            charactVc.service = serv
            
            self.navigationController?.pushViewController(charactVc, animated: true)
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
    }

}
