//
//  CharactTableViewController.swift
//  testRxBluetoothKit
//
//  Created by  BlueYang on 2017/6/26.
//  Copyright © 2017年  BlueYang. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import RxCocoa

class CharactTableViewController: UITableViewController {

    open var service: Service? = nil
    fileprivate let cellID = "charactCellid"
    fileprivate let bag = DisposeBag()
    fileprivate var charactArray = Variable<[Characteristic]> ([])
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Characteristic"
        
        
        
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.dataSource = nil
        tableView.delegate   = nil
        
        
        service?.discoverCharacteristics(nil)
        .debug().flatMap { Observable.from($0) }
        .subscribe(onNext: {
            [weak self] charact in
            self?.charactArray.value.append(charact)
            self?.tableView.reloadData()
        }).addDisposableTo(bag)
        
        charactArray.asObservable().bind(to: tableView.rx.items(cellIdentifier: cellID)) {
            row, charact, cell in
            
            cell.textLabel?.text = charact.uuid.uuidString
        }.addDisposableTo(bag)
        
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

}
