//
//  SettingViewController.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/10/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class SettingViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var chatIDTextField: UITextField!
    @IBOutlet weak var visibilitySwitch: UISwitch!
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var vibrationSwitch: UISwitch!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatIDTextField.delegate = self
        
        //Check whether user has previouly set custom ChatID
        if let customChatID = self.defaults.valueForKey("customChatID") as? String {
            self.chatIDTextField.text = customChatID
        }
        
        //If userDefaults has a visibleSwitch status stored, use this status to set the visibleSwitch
        if defaults.valueForKey("switchStatus") != nil {
            let switchStatus = self.defaults.valueForKey("switchStatus") as! Bool
            visibilitySwitch.setOn(switchStatus, animated: false)
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if appDelegate.mcManager.connectedPeers.count == 0 {
            chatIDTextField.enabled = true
        } else {
            chatIDTextField.enabled = false
        }
    }
    

    @IBAction func toggleVisibility(sender: AnyObject) {
        if  visibilitySwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        } else {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
        //Whenever user changed the status of visibleSwitch, save new stauts into UserDefaults to preserve this change
        defaults.setObject(visibilitySwitch.on, forKey: "switchStatus")
    }
    
    //Implemente textField delegate method
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        chatIDTextField.resignFirstResponder()
        //If user tap the textField but don't input anything, use default device name
        var resetDeviceName: String!
        if chatIDTextField.text! == "" {
            resetDeviceName = UIDevice.currentDevice().name
            defaults.removeObjectForKey("customChatID")
        } else {
            resetDeviceName = chatIDTextField.text!
            //Save user's custom ChatID into UserDefault to preserve this change
            defaults.setObject(resetDeviceName, forKey: "customChatID")
        }
        
        //If MCManger advertiser is on, first stop it and then reset it, since user will use a new ChatID to advitise with
        if visibilitySwitch.on {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
        appDelegate.mcManager.advertiser = nil
        
        //Upon user hit return key, reset peerID and session using the new ChatID
        appDelegate.mcManager.peerID = nil
        appDelegate.mcManager.session = nil
        appDelegate.mcManager.setupPeerAndSessionWithDisplayName(resetDeviceName)
        
        //After reset is done, resume advertiser if it's switch is on
        if visibilitySwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        }
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 15
        let currentString: NSString = textField.text!
        let newString: NSString =
            currentString.stringByReplacingCharactersInRange(range, withString: string)
        return newString.length <= maxLength
    }
}
