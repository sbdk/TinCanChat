//
//  ChatRecordViewController.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/11/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import CoreData
import MultipeerConnectivity

class ChatRecordViewController: UITableViewController {
    
    @IBOutlet weak var browserButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    var storedPeerNames: Dictionary = [String:String]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.mcManager.advertiser.startAdvertisingPeer()
    }

    @IBAction func browserButtonTouched(sender: AnyObject) {
        
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("browserViewController") as! BrowserViewController
        controller.searchingPeer = true
        presentViewController(controller, animated: true, completion: nil)
    }
}
