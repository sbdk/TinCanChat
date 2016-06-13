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

class ChatRecordViewController: UITableViewController, MCManagerInvitationDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var browserButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    var storedPeerNames: Dictionary = [String:String]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.mcManager.advertiser.startAdvertisingPeer()
        
        let backgroundImage = UIImage(named: "BeachEffect")
        let imageView = UIImageView(image: backgroundImage)
        imageView.contentMode = .ScaleAspectFill
        imageView.alpha = 0.4
        
        tableView.backgroundView = imageView
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        //Check whether user has previouly set custom ChatID, if so, reset MCManager session with this custom ChatID
        if let customChatID = self.defaults.valueForKey("customChatID") as? String {
            self.appDelegate.mcManager.peerID = nil
            self.appDelegate.mcManager.session = nil
            self.appDelegate.mcManager.setupPeerAndSessionWithDisplayName(customChatID)
        }
        
        //If userDefaults has a visibleSwitch status stored, use this status to set the advertiseing status
        if defaults.valueForKey("switchStatus") != nil {
            let switchStatus = self.defaults.valueForKey("switchStatus") as! Bool
            if  switchStatus {
                appDelegate.mcManager.advertiser.startAdvertisingPeer()
            } else {
                appDelegate.mcManager.advertiser.stopAdvertisingPeer()
            }
        }
        
        //Put not-so-urgent task into background queue
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            
            self.appDelegate.mcManager.invitationDelegate = self
            
            //Make this viewController listen to lostConnection notification and successConnection notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatRecordViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatRecordViewController.handleSuccessConnection(_:)), name: "connectedWithPeer", object: nil)
            //Make this viewController listen to receive message notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatRecordViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
        }
    }
    
    /***  Implemente tableView delegate  ***/
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mcManager.connectedPeers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tableViewCell", forIndexPath: indexPath) as! PeerCell
        let peerID = (appDelegate.mcManager.connectedPeers)[indexPath.row] as! MCPeerID
        cell.connectedPeerLabel!.text = peerID.displayName as String
        cell.statusLabel!.text = "connected 😎"
        
        //Config badgeLabel
        cell.badgeLabel.hidden = true
        cell.badgeLabel.clipsToBounds = true
        cell.badgeLabel.layer.cornerRadius = 8.0
        cell.badgeLabel.backgroundColor = UIColor.redColor()
        cell.badgeLabel.textColor = UIColor.whiteColor()
        
        //Check whether this peer has unread messages count stored in userDefault
        if defaults.valueForKey(peerID.displayName) != nil {
            cell.badgeLabel.text = String(defaults.valueForKey(peerID.displayName)!)
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
        let peerID = (appDelegate.mcManager.connectedPeers)[indexPath.row] as! MCPeerID
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //Perform a predicated fetch with peerID info, get the associated ChatPeer
        let fetchController = peerFetchController(peerID.displayName)
        do{
            try fetchController.performFetch()
        } catch{print(error)}
        let selectedPeer = (fetchController.fetchedObjects as! [ChatPeer]).first!
        
        //Reset unread message count for this peerID
        defaults.setValue(nil, forKey: peerID.displayName)
        
        //Prepare and present the ChatViewController
        let controller = storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        controller.chatPeer = selectedPeer
        controller.readOnly = false
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch (editingStyle) {
        case .Delete:
            let peerToDelete = fetchedRequestController.objectAtIndexPath(indexPath) as! ChatPeer
            //If this peer is currently conntected, first disconnect it
            if appDelegate.mcManager.connectedPeers.containsObject(peerToDelete.peerID){
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
        return "Disconnect"
    }


    @IBAction func browserButtonTouched(sender: AnyObject) {
        
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("browserViewController") as! BrowserViewController
        controller.searchingPeer = true
        presentViewController(controller, animated: true, completion: nil)
    }
    
    /***  Implemente all custom delegate methods and notification functions  ***/
    
    //Implemente custom MCManger invitation delegate
    func invitationWasReceived(fromPeer: String, invitationHandler: (Bool, MCSession?) -> Void) {
        print("received invitatio from: \(fromPeer)")
        
        //First config the invitation AlertView
        let alert = UIAlertController(title: "", message: "\(fromPeer) want to chat with you", preferredStyle: UIAlertControllerStyle.Alert)
        
        //Config accept action
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            invitationHandler(true, self.appDelegate.mcManager.session)
            
            //If user tap accept button, present a custom BroserView to show connection status
            dispatch_async(dispatch_get_main_queue()){
                let browserViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ClosestFansBrowserViewController") as! BrowserViewController
                
                //indicate that browserView is presented for handling invitation sent from other peer, will update browserView UI accordingly
                browserViewController.searchingPeer = false
                browserViewController.connectWithPeer = fromPeer
                
                //Present the custom browserView from App window's rootViewController, so user will get noticed anywhere from the application
                self.appDelegate.window?.rootViewController?.presentViewController(browserViewController, animated: true, completion: nil)
            }
        }
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {(alertAction) -> Void in
            invitationHandler(false, self.appDelegate.mcManager.session)
        }
        alert.addAction(declineAction)
        alert.addAction(acceptAction)
        
        //Present the invitation AlertView from App window's rootViewController, so user will get noticed anywhere from the application
        dispatch_async(dispatch_get_main_queue()){
            self.appDelegate.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }

    
    //Reaction function used for lostConnection notification
    func handleLostConnection(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()){
            self.tableView.reloadData()
        }
    }
    
    //Reaction function used for successConnection notification, add Peer info into CoreData or update peer info is already exist
    func handleSuccessConnection(notification: NSNotification){
        let peerID = notification.object as! MCPeerID
        
        //Perform a fetch to get stored ChatPeers
        let fetchController = peerFetchController(peerID.displayName)
        do{
            try fetchController.performFetch()
        } catch{print(error)}
        
        dispatch_async(dispatch_get_main_queue()){
            
            //If the connected peer has previously stored in CoreData, update it's peerID info
            if let connectedPeer = (fetchController.fetchedObjects as! [ChatPeer]).first {
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
        
        let receivedDataDictionary = notification.object as! [String:AnyObject]
        
        // Extract the data and the sender's MCPeerID from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        //Perform a fetch to get associated ChatPeer object
        let fetchController = peerFetchController(fromPeer.displayName)
        do{
            try fetchController.performFetch()
        } catch{print(error)}
        let sourcePeer = (fetchController.fetchedObjects as! [ChatPeer]).first!
        
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
            if message != "chat is ended by the other party"{
                
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
                    let receivedMessage = ChatMessage(sender: nil, body: message, context: self.sharedContext)
                    receivedMessage.messagePeer = sourcePeer
                    self.sharedContext.insertObject(receivedMessage)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
    /*** CoreData Implementation ***/
    
    //Set lazy variable for CoreData
    lazy var sharedContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    //Convenient function for later use, enable real-time fetch with predicate
    func peerFetchController(predicatePeerName: String) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "ChatPeer")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastChatTime", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "peerName == %@", predicatePeerName)
        let fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedRequestController.delegate = self
        return fetchedRequestController
    }
    
    //Convenient function for later use, enable real-time fetch with predicate
    lazy var fetchedRequestController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "ChatPeer")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastChatTime", ascending: false)]
        let fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedRequestController
    }()
    
    //implemente FetchedResultController Delegate Method
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                    atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            break
        case .Delete:
            break
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
