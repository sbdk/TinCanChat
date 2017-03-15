//
//  BrowserViewController.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/11/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import CoreData
import MultipeerConnectivity

class BrowserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MCNearbyServiceBrowserDelegate {

    @IBOutlet weak var browserTableView: UITableView!
    @IBOutlet weak var browserActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var browserViewTopLabel: UILabel!
    @IBOutlet weak var dismissButton: UIBarButtonItem!
  
    var connectStatusText: String?
    var searchingPeer: Bool = true
    var connectWithPeer: String = ""
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //prepare view UI according to the status of this browserView
        if searchingPeer{
            browserViewTopLabel.text = "Searching"
            connectStatusText = "Touch to connect"
        }else{
            browserViewTopLabel.text = "Connecting"
            browserTableView.allowsSelection = false
            connectStatusText = "connecting..."
        }
    }
    
    override func viewDidLoad() {
      super.viewDidLoad()
      browserTableView.delegate = self
      browserTableView.dataSource = self
      browserTableView.tableFooterView = UIView(frame: CGRectZero)
      browserActivityIndicator.startAnimating()
      MCManager.sharedInstance.browser.delegate = self
      MCManager.sharedInstance.browser.startBrowsingForPeers()
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowserViewController.connectingWithPeer(_:)), name: MCManagerNotifications.connectingWithPeer.rawValue, object: nil)
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowserViewController.connectedWithPeer(_:)), name: MCManagerNotifications.connectedWithPeer.rawValue, object: nil)
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowserViewController.notConnectedWithPeer(_:)), name: MCManagerNotifications.notConnectedWithPeer.rawValue, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
      super.viewWillDisappear(animated)
      MCManager.sharedInstance.foundPeers.removeAll()
      MCManager.sharedInstance.browser.stopBrowsingForPeers()
      NSNotificationCenter.defaultCenter().removeObserver(self, name: MCManagerNotifications.connectingWithPeer.rawValue, object: nil)
      NSNotificationCenter.defaultCenter().removeObserver(self, name: MCManagerNotifications.connectedWithPeer.rawValue, object: nil)
      NSNotificationCenter.defaultCenter().removeObserver(self, name: MCManagerNotifications.notConnectedWithPeer.rawValue, object: nil)
    }
  
  //implemente delegate methods for browser
  func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
    MCManager.sharedInstance.foundPeers.append(peerID)
    browserTableView.reloadData()
    print("find a peer in delegate")
  }
  
  func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    for (index, peer) in MCManager.sharedInstance.foundPeers.enumerate() {
      if peer == peerID {
        MCManager.sharedInstance.foundPeers.removeAtIndex(index)
        browserTableView.reloadData()
        break
      }
    }
  }
  
  func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
    print(error.localizedDescription)
  }
  
  //implemente session notification handler functions
  func connectedWithPeer(notification: NSNotification) {
        connectStatusText = "connected 😎"
        print(connectStatusText)
        //When connect success,dismiss the browserView
        dispatch_async(dispatch_get_main_queue()){
          self.browserTableView.reloadData()
          self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
  func connectingWithPeer(notification: NSNotification) {
        connectStatusText = "connecting...😍"
        dispatch_async(dispatch_get_main_queue()){
            self.browserTableView.reloadData()
        }
    }
    
  func notConnectedWithPeer(nofification: NSNotification) {
        connectStatusText = "connect failed 😭"
        dispatch_async(dispatch_get_main_queue()){
            self.browserTableView.reloadData()
        }
    }
  
  //Config the dismiss button action
  @IBAction func cancelButtonTouched(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
}
