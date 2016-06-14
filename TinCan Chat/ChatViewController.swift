//
//  ChatViewController.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/13/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import CoreData
import MultipeerConnectivity

class ChatViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var messageInputTextView: UITextView!
    
    var chatPeer: ChatPeer!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    var readOnly: Bool = false
    
    //Preapare for keyboard config
    var keyboardAdjusted = false
    var lastKeyboardOffset : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageInputTextView.layer.cornerRadius = 8.0
        messageInputTextView.layer.borderColor = UIColor.whiteColor().CGColor
        messageInputTextView.layer.borderWidth = 1
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        //Auto adjust tableView height according to it's content size
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 50.0
        
        let endChatButton = UIBarButtonItem(image: UIImage(named: "NoChat"), style: .Plain, target: self, action: #selector(ChatViewController.endChat(_:)))
        navigationItem.rightBarButtonItem = endChatButton
        
        //Put not-so-urgent task into background queue to improve ChatViewContoller load speed
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            self.subscribeToKeyboardNotifications()
            
            //Custom keyboard return key
            self.messageInputTextView.delegate = self
            self.messageInputTextView.returnKeyType = UIReturnKeyType.Send
            self.messageInputTextView.enablesReturnKeyAutomatically = true
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
            
            //Add a tapRecognizer to this ChatView, user will tap screen to dismiss keyboard
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.handleSingleTap))
            tapRecognizer.numberOfTapsRequired = 1
            self.view.addGestureRecognizer(tapRecognizer)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.hidden = true
        navigationItem.title = chatPeer.peerID.displayName
        if readOnly{
            messageInputTextView.editable = false
            messageInputTextView.text = "This peer is not currently connected"
            messageInputTextView.textColor = UIColor.lightGrayColor()
            messageInputTextView.textAlignment = .Center
            navigationItem.rightBarButtonItem?.enabled = false
        } else {
            messageInputTextView.editable = true
            messageInputTextView.text = ""
            messageInputTextView.textAlignment = .Left
        }
        
        fetchedResultController.delegate = self
        do{
            try fetchedResultController.performFetch()
        } catch{print(error)}
        
        //Scroll tableView to bottom
        if let storedMessages = fetchedResultController.fetchedObjects {
            if storedMessages.count > 0 {
                let delay = 0.1 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()){
                    self.chatTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: storedMessages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //Upon leave ChatView, reset unread message count for this Peer, since incoming message number are still counting during the Chat
        defaults.setValue(nil, forKey: chatPeer.peerID.displayName)
        tabBarController?.tabBar.hidden = false
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentMessage = fetchedResultController.objectAtIndexPath(indexPath) as! ChatMessage
        let messageBody = currentMessage.messageBody
        let messageViewMaxWidth: CGFloat = 240.0
        
        //Situation that it's a normal chat message(which mean message has a sender info)
        if let sender = currentMessage.messageSender {
            if sender == "self"{
                //implemente outgoing message
                let cell = tableView.dequeueReusableCellWithIdentifier("sentMessageCell")! as! ChatSentMessageCell
                cell.sentTextView.text = messageBody
                cell.sentTextView.backgroundColor = UIColor.purpleColor()
                cell.sentTextView.textColor = UIColor.whiteColor()
                cell.sentTextView.layer.cornerRadius = 10.0
                
                //If the content size of textView is smaller than massageMaxWidth, use adjusted contentsize for this message, which will be a single line message
                if cell.sentTextView.attributedText.size().width < messageViewMaxWidth {
                    cell.sentTextViewWidth.constant = cell.sentTextView.attributedText.size().width + 10
                }
                    
                    //If the content size of textView is bigger than massageMaxWidth, fix the message widht to maxWidth and make this messageView muliple line
                else {
                    cell.sentTextViewWidth.constant = 240.0
                }
                return cell
                
            } else {
                //implemente incoming message
                let cell = tableView.dequeueReusableCellWithIdentifier("receivedMessageCell")! as! ChatReceivedMessageCell
                cell.receivedTextView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
                cell.receivedTextView.textColor = UIColor.blackColor()
                cell.receivedTextView.layer.cornerRadius = 10.0
                cell.receivedTextView.text = messageBody
                if cell.receivedTextView.attributedText.size().width < messageViewMaxWidth {
                    cell.receivedTextViewWidth.constant = cell.receivedTextView.attributedText.size().width + 10
                } else {
                    cell.receivedTextViewWidth.constant = 240.0
                }
                return cell
            }
        }
            //Situation that it's the last message (other party terminated the Chat, sender info is nil)
        else {
            //implemente end-of-chat message
            let cell = tableView.dequeueReusableCellWithIdentifier("receivedMessageCell")! as! ChatReceivedMessageCell
            cell.receivedTextView.backgroundColor = UIColor.whiteColor()
            cell.receivedTextView.textColor = UIColor.lightGrayColor()
            cell.receivedTextView.layer.cornerRadius = 10.0
            cell.receivedTextView.text = messageBody
            cell.receivedTextViewWidth.constant = 240.0
            return cell
        }
    }
    
    //Implemente textView delegate method
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        //If user hit return key
        if text == "\n"{
            //First send out this message dictionary to connected peer
            let messageDictionary: [String: String] = ["message": (messageInputTextView?.text)!]
            if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: chatPeer.peerID){
                //After message send out, store the sent message into CoreData
                dispatch_async(dispatch_get_main_queue()){
                    let sentMessage = ChatMessage(sender: "self", body: messageDictionary["message"]!, context: self.sharedContext)
                    sentMessage.messagePeer = self.chatPeer
                    self.sharedContext.insertObject(sentMessage)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            else{
                print("Could not send data")
            }
            messageInputTextView.text = ""
        }
        return true
    }
    
    //Another textViewDelegate method, remove the typed-in "return" value from textView, return the inputTextView to it's default status
    func textViewDidChange(textView: UITextView) {
        if messageInputTextView.text == "\n"{
            messageInputTextView.text = ""
        }
    }
    
    //Implemente the endChat function for the endChatButton
    func endChat(sender: AnyObject){
        print("end chat")
        let messageDictionary: [String: String] = ["message": "chat is ended by the other party"]
        if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: chatPeer.peerID){
            appDelegate.mcManager.session.cancelConnectPeer(chatPeer.peerID)
        }
    }
    
    //Reaction fucntion used for lostConnection Notification
    func handleLostConnection(notification: NSNotification) {
        
        //whenever user lost connection with a peer, we need to check whether it's the current chatting peer, if so, present an alertView and leave the current ChatView
        if (notification.object) as! MCPeerID == chatPeer.peerID {
            dispatch_sync(dispatch_get_main_queue()){
                let alterView = UIAlertController(title: "Lost connection", message: "Connection is lost, will dismiss chat window", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel){(OKAction) -> Void in self.navigationController?.popViewControllerAnimated(true)
                }
                alterView.addAction(okAction)
                self.presentViewController(alterView, animated: true, completion: nil)
            }
        }
    }
    
    //Config the TapRecognizer reponse fucntion to dismiss keyboard
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    //Set lazy variable for CoreData
    lazy var sharedContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "ChatMessage")
        fetchRequest.predicate = NSPredicate(format: "messagePeer == %@", self.chatPeer)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "messageTime", ascending: true)]
        let fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedRequestController
    }()
    
    //implemente FetchedResultController Delegate Method
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        chatTableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                    atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            chatTableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            chatTableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType,newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            chatTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            chatTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            break
        case .Move:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        chatTableView.endUpdates()
        
        //After new message has been stored and presented, scroll the ChatTable to most recent message
        chatTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: (fetchedResultController.fetchedObjects?.count)! - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
}

