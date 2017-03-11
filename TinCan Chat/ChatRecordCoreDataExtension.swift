//
//  ChatRecordCoreDataExtension.swift
//  TinCan Chat
//
//  Created by Li Yin on 10/12/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import CoreData
import MultipeerConnectivity
import AudioToolbox

extension ChatRecordViewController {
  //implemente notification
  func handleLostConnection(notification: NSNotification) {
    dispatch_async(dispatch_get_main_queue()){
      self.tableView.reloadData()
    }
  }
  
  //Reaction function used for successConnection notification, add Peer info into CoreData or update peer info is already exist
  func handleSuccessConnection(notification: NSNotification){
    let peerID = notification.object as! MCPeerID
    
    dispatch_async(dispatch_get_main_queue()){
      //Perform a fetch to get stored ChatPeers
      //If the connected peer has previously stored in CoreData, update it's peerID info
      if let objectInTempContext = self.customFetch(peerID.displayName){
        let objectID = objectInTempContext.objectID
        let connectedPeer = self.sharedContext.objectWithID(objectID) as! ChatPeer
        connectedPeer.peerID = peerID
        connectedPeer.lastChatTime = NSDate()
        CoreDataStackManager.sharedInstance().saveContext()
      }
        //If the connected peer is a new peer, add this ChatPeer object into CoreData
      else {
        let newPeer = ChatPeer(newPeerID: peerID, messagesArray: nil, context: self.sharedContext)
        self.sharedContext.insertObject(newPeer)
        CoreDataStackManager.sharedInstance().saveContext()
      }
    }
  }
  
  //Reaction fucntion used for received Message Notification
  func handleMCReceivedDataWithNotification(notification: NSNotification){
    var sourcePeer: ChatPeer!
    let receivedDataDictionary = notification.object as! [String:AnyObject]
    
    if soundEffectOn {
      AudioServicesPlaySystemSound(1003)
    }
    if vibrationEffectOn {
      AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    // Extract the data and the sender's MCPeerID from the received dictionary.
    let data = receivedDataDictionary["data"] as? NSData
    let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
    
    temporaryContext.performBlockAndWait(){
      //Perform a fetch to get associated ChatPeer object
      let objectInTempContext = self.customFetch(fromPeer.displayName)!
      let objectID = objectInTempContext.objectID
      sourcePeer = self.sharedContext.objectWithID(objectID) as! ChatPeer
    }
    //Update unread message count for specific peer and save this info into userDefault
    dispatch_async(dispatch_get_main_queue()){
      if self.defaults.valueForKey(fromPeer.displayName) != nil {
        var count = self.defaults.valueForKey(fromPeer.displayName) as! Int
        count += 1
        self.defaults.setValue(count, forKey: fromPeer.displayName)
      } else {
        self.defaults.setValue(1, forKey: fromPeer.displayName)
      }
      self.tableView.reloadData()
    }
    
    // Convert the data (NSData) into a Dictionary object.
    let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! [String:String]
    
    // Check if there's an entry with the "message" key.
    if let message = dataDictionary["message"] {
      
      // Make sure that the message is other than "_end_chat_".
      if message != "This chat is ended"{
        
        dispatch_async(dispatch_get_main_queue()){
          let receivedMessage = ChatMessage(sender: fromPeer.displayName, body: message, context: self.sharedContext)
          receivedMessage.messagePeer = sourcePeer
          self.sharedContext.insertObject(receivedMessage)
          CoreDataStackManager.sharedInstance().saveContext()
        }
      }
      else{
        //in this case, only post the last message
        dispatch_async(dispatch_get_main_queue()){
          let receivedMessage = ChatMessage(sender: fromPeer.displayName, body: message, context: self.sharedContext)
          receivedMessage.messagePeer = sourcePeer
          self.sharedContext.insertObject(receivedMessage)
          CoreDataStackManager.sharedInstance().saveContext()
        }
      }
    }
  }
  
  //implemente advertiser delegate methods
  func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession?) -> Void) {
    print("received a invitation")
    print("received invitatio from: \(peerID.displayName)")
    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    
    //First config the invitation AlertView
    let alert = UIAlertController(title: "", message: "\(peerID.displayName) want to chat with you", preferredStyle: UIAlertControllerStyle.Alert)
    
    //Config accept action
    let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
      invitationHandler(true, MCManager.sharedInstance.session)
      
      //If user tap accept button, present a custom BroserView to show connection status
      dispatch_async(dispatch_get_main_queue()){
        let browserViewController = self.storyboard?.instantiateViewControllerWithIdentifier("browserViewController") as! BrowserViewController
        
        //indicate that browserView is presented for handling invitation sent from other peer, will update browserView UI accordingly
        browserViewController.searchingPeer = false
        browserViewController.connectWithPeer = peerID.displayName
        
        //Present the custom browserView from App window's rootViewController, so user will get noticed anywhere from the application
        self.appDelegate.window?.rootViewController?.presentViewController(browserViewController, animated: true, completion: nil)
      }
    }
    let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {(alertAction) -> Void in
      invitationHandler(false, MCManager.sharedInstance.session)
    }
    alert.addAction(declineAction)
    alert.addAction(acceptAction)
    
    //Present the invitation AlertView from App window's rootViewController, so user will get noticed anywhere from the application
    dispatch_async(dispatch_get_main_queue()){
      self.appDelegate.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
  }

  /*** CoreData Implementation ***/
  func customFetch(predicatePeerName: String) -> ChatPeer? {
    var fetchedObject = [ChatPeer]()
    let fetch = NSFetchRequest(entityName: "ChatPeer")
    fetch.predicate = NSPredicate(format: "peerName == %@", predicatePeerName)
    do{
      fetchedObject = try temporaryContext.executeFetchRequest(fetch) as! [ChatPeer]
    } catch {
      print(error)
    }
    return fetchedObject.first
  }
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    tableView.beginUpdates()
  }
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                  atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    case .Delete:
      self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    default:
      return
    }
  }
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType,newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
    case .Update:
      break
    case .Move:
      break
    }
  }
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    tableView.endUpdates()
  }

}
