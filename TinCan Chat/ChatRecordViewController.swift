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
import AudioToolbox

class ChatRecordViewController: UITableViewController, MCNearbyServiceAdvertiserDelegate, NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate {
  
    @IBOutlet weak var browserButton: UIBarButtonItem!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    lazy var sharedContext: NSManagedObjectContext = {
      return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    lazy var fetchedRequestController: NSFetchedResultsController = {
      let fetchRequest = NSFetchRequest(entityName: "ChatPeer")
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastChatTime", ascending: false)]
      let fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
      return fetchedRequestController
    }()
    var temporaryContext: NSManagedObjectContext!
    var soundEffectOn: Bool = true
    var vibrationEffectOn: Bool = true
    var localChatName: String?
    var invitationView: InvitationView!
  
    override func viewWillAppear(animated: Bool) {
      super.viewWillAppear(animated)
      tableView.reloadData()
      //Check sound and vibration effect status
      soundEffectOn = defaults.valueForKey("soundSwitchStatus") as? Bool ?? true
      vibrationEffectOn = defaults.valueForKey("vibrationSwitchStatus") as? Bool ?? true
      if let customChatID = defaults.valueForKey("customChatID") as? String {
        localChatName = customChatID
      } else {
        localChatName = UIDevice.currentDevice().name
      }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImage(named: "BeachEffect")
        let imageView = UIImageView(image: backgroundImage)
        imageView.contentMode = .ScaleAspectFill
        imageView.alpha = 0.4
        tableView.backgroundView = imageView
        tableView.tableFooterView = UIView(frame: CGRectZero)
        navigationController?.navigationBar.tintColor = UIColor.purpleColor()
        tabBarController?.tabBar.tintColor = UIColor.purpleColor()
      
        // Set the temporary context
        temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = sharedContext.persistentStoreCoordinator

        //Perform CoreData fetch
        fetchedRequestController.delegate = self
        do{
            try fetchedRequestController.performFetch()
        } catch {print(error)}
        
        //Check whether user has previouly set custom ChatID, if so, reset MCManager session with this custom ChatID
        if let customChatID = self.defaults.valueForKey("customChatID") as? String {
            MCManager.sharedInstance.resetSessionWithNewChatName(customChatID)
        }
        
        //If userDefaults has a visibleSwitch status stored, use this status to set the advertiseing status
        if defaults.valueForKey("switchStatus") != nil {
            let switchStatus = self.defaults.valueForKey("switchStatus") as! Bool
            if  switchStatus {
                MCManager.sharedInstance.advertiser.startAdvertisingPeer()
            } else {
                MCManager.sharedInstance.advertiser.stopAdvertisingPeer()
            }
        } else {
           MCManager.sharedInstance.advertiser.startAdvertisingPeer()
        }
        
        //Put not-so-urgent task into background queue
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
          
            MCManager.sharedInstance.advertiser.delegate = self
            //Make this viewController listen to lostConnection notification and successConnection notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatRecordViewController.handleLostConnection(_:)), name: MCManagerNotifications.notConnectedWithPeer.rawValue, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatRecordViewController.handleSuccessConnection(_:)), name: MCManagerNotifications.connectedWithPeer.rawValue, object: nil)
            //Make this viewController listen to receive message notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatRecordViewController.handleMCReceivedDataWithNotification(_:)), name: MCManagerNotifications.receivedData.rawValue, object: nil)
        }
    }
  
    @IBAction func browserButtonTouched(sender: AnyObject) {
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("browserViewController") as! BrowserViewController
        controller.searchingPeer = true
        presentViewController(controller, animated: true, completion: nil)
    }
  
    @IBAction func disconnectAllButtonTouched(sender: AnyObject) {
        //Disconnect from all current peers and reset the connectedPeers array
        MCManager.sharedInstance.session.disconnect()
        MCManager.sharedInstance.connectedPeers.removeAll()
        tableView.reloadData()
    }
}
