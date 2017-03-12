//
//  ChatRecordTableViewExtension.swift
//  TinCan Chat
//
//  Created by Li Yin on 10/12/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import UIKit

extension ChatRecordViewController {
  /***  Implemente tableView delegate  ***/
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = fetchedRequestController.sections?[section]
    return sectionInfo?.numberOfObjects ?? 0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("storedPeerCell", forIndexPath: indexPath) as! PeerCell
    let storedPeer = fetchedRequestController.objectAtIndexPath(indexPath) as! ChatPeer
    cell.connectedPeerLabel!.text = storedPeer.peerName
    
    //Check whether this peer is currently connected
    if MCManager.sharedInstance.connectedPeers.contains(storedPeer.peerID){
      cell.statusLabel!.text = "connected 😎"
    } else {
      cell.statusLabel!.text = "Not connected"
    }
    
    //Config badgeLabel
    cell.badgeLabel.hidden = true
    cell.badgeLabel.clipsToBounds = true
    cell.badgeLabel.layer.cornerRadius = 8.0
    cell.badgeLabel.backgroundColor = UIColor.redColor()
    cell.badgeLabel.textColor = UIColor.whiteColor()
    
    //Check whether this peer has unread messages count stored in userDefault
    if defaults.valueForKey(storedPeer.peerName) != nil {
      cell.badgeLabel.text = String(defaults.valueForKey(storedPeer.peerName)!)
      cell.badgeLabel.hidden = false
    }
    return cell
  }
  
  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 50.0
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selectedPeer = fetchedRequestController.objectAtIndexPath(indexPath) as! ChatPeer
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    
    //Reset unread message count for this peerID
    defaults.setValue(nil, forKey: selectedPeer.peerName)
    
    //Prepare and present the ChatViewController
//    let controller = storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController 
    let controller = storyboard?.instantiateViewControllerWithIdentifier("JSQChatViewController") as! JSQChatViewController
    controller.senderId = "self"
    controller.senderDisplayName = localChatName
    controller.tabBarController?.tabBar.hidden = true
    controller.chatPeer = selectedPeer
    
    if MCManager.sharedInstance.connectedPeers.contains(selectedPeer.peerID){
      controller.readOnly = false
    } else {
      controller.readOnly = true
    }
    navigationController?.pushViewController(controller, animated: true)
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    switch (editingStyle) {
    case .Delete:
      let peerToDelete = fetchedRequestController.objectAtIndexPath(indexPath) as! ChatPeer
      //If this peer is currently conntected, first disconnect it
      if MCManager.sharedInstance.connectedPeers.contains(peerToDelete.peerID){
        ConvenientView.sharedInstance().showAlertView("Deleteing active Chat!", message: "This Chat record is currently active, please first disconnect it and then delete the chat record", hostView: self)
      } else {
        sharedContext.deleteObject(peerToDelete)
        CoreDataStackManager.sharedInstance().saveContext()
      }
      
    default:
      break
    }
  }
  
  override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
    return "Delete"
  }
}
