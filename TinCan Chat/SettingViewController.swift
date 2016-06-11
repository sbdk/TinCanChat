//
//  SettingViewController.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/10/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit

class SettingViewController: UITableViewController {

    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var chatIDTextField: UITextField!
    @IBOutlet weak var visibilitySwitch: UISwitch!
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var vibrationSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
}
