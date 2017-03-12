//
//  BrowserExtension.swift
//  TinCan Chat
//
//  Created by Li Yin on 10/12/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import UIKit

extension BrowserViewController {
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return MCManager.sharedInstance.foundPeers.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let peerID = MCManager.sharedInstance.foundPeers[indexPath.row]
    let cell = tableView.dequeueReusableCellWithIdentifier("browserTableCell")! as! PeerCell
    cell.foundPeerLabel?.text = peerID.displayName
    
    cell.connectStatusLabel.text = connectStatusText
    
    //If already connected peer, it will show up in browserView list, so we set its status label to connected
    if MCManager.sharedInstance.connectedPeers.contains(peerID){
      cell.connectStatusLabel?.text = "connected 😎"
    }
      //For the peer user currently connecting with, pass cellDetailText value to this peer's status label
    else if peerID.displayName == connectWithPeer {
      cell.connectStatusLabel?.text = connectStatusText
    }
      //For not connecting peer that shown in BrowserView list, set it's status Label to default
    else {
      cell.connectStatusLabel?.text = "Touch to connect"
    }
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    //By disable selection for tableView after selecting a row, make sure only one invitation is been sent and send only once
    browserTableView.allowsSelection = false
    
    let cell = tableView.cellForRowAtIndexPath(indexPath) as! PeerCell
    let peerID = MCManager.sharedInstance.foundPeers[indexPath.row]
    
    //Set the current connecting peer info with selected peerID
    connectWithPeer = peerID.displayName
    
    if MCManager.sharedInstance.connectedPeers.contains(peerID){
      //Do noting if the found peer has already connected
    } else {
      cell.connectStatusLabel!.text = "request sent...😐"
      
      print("start to connect...")
      //Sent the invitation
      MCManager.sharedInstance.browser.invitePeer(peerID, toSession: MCManager.sharedInstance.session, withContext: nil, timeout: 20)
    }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
}
