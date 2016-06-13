//
//  SettingViewController.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/10/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class SettingViewController: UITableViewController {

    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var chatIDTextField: UITextField!
    @IBOutlet weak var visibilitySwitch: UISwitch!
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var vibrationSwitch: UISwitch!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Check whether user has previouly set custom ChatID
        if let customChatID = self.defaults.valueForKey("customChatID") as? String {
            self.chatIDTextField.text = customChatID
        }
        
        //If userDefaults has a visibleSwitch status stored, use this status to set the visibleSwitch
        if defaults.valueForKey("switchStatus") != nil {
            let switchStatus = self.defaults.valueForKey("switchStatus") as! Bool
            visibilitySwitch.setOn(switchStatus, animated: false)
        }
//        if  visibilitySwitch.on {
//            appDelegate.mcManager.advertiser.startAdvertisingPeer()
//        } else {
//            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
//        }

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if appDelegate.mcManager.connectedPeers.count > 0 {
            chatIDTextField.enabled = false
        }
    }
}
