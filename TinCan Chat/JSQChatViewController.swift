//
//  JSQChatView.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/23/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import CoreData
import MultipeerConnectivity
import JSQMessagesViewController

class JSQChatViewController: JSQMessagesViewController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    var chatPeer: ChatPeer!
    var fetchedMessages = [ChatMessage]()
    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.hidden = true
        
        let fetchRequest = NSFetchRequest(entityName: "ChatMessage")
        fetchRequest.predicate = NSPredicate(format: "messagePeer == %@", self.chatPeer)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "messageTime", ascending: true)]
        
        do {
            fetchedMessages = try sharedContext.executeFetchRequest(fetchRequest) as! [ChatMessage]
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        for message in fetchedMessages {
            
            addMessage(message.messageSender!, text: message.messageBody)
        }
        finishReceivingMessage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBubbles()
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        navigationItem.title = chatPeer.peerName
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(JSQChatViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(JSQChatViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.hidden = false
        //Upon leave ChatView, reset unread message count for this Peer, since incoming message number are still counting during the Chat
        defaults.setValue(nil, forKey: chatPeer.peerID.displayName)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
     messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView!.textColor = UIColor.blackColor()
        }
        return cell
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.purpleColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    func addMessage(id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: "", text: text)
        messages.append(message)
    }
    
    //implemente outgoing messages
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!,senderDisplayName: String!, date: NSDate!) {
        
        //First send out this message dictionary to connected peer
        let messageDictionary: [String: String] = ["message": text]
        if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: chatPeer.peerID){
            
            //first add new sent message into JSQMessage array
            addMessage("self", text: text)
            
            //After message send out, store the sent message into CoreData
            dispatch_async(dispatch_get_main_queue()){
                let sentMessage = ChatMessage(sender: "self", body: messageDictionary["message"]!, context: self.sharedContext)
                sentMessage.messagePeer = self.chatPeer
                self.sharedContext.insertObject(sentMessage)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            finishSendingMessage()
        }
        else{
            print("Could not send data")
        }
    }
    
    func handleMCReceivedDataWithNotification(notification: NSNotification){
        let receivedDataDictionary = notification.object as! [String:AnyObject]

        // Extract the data and the sender's MCPeerID from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        // Convert the data (NSData) into a Dictionary object.
        let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! [String:String]
        
        // Check if there's an entry with the "message" key.
        if let message = dataDictionary["message"] {
            
            // Make sure that the message is other than "_end_chat_".
            if message != "chat is ended by the other party"{
                
                dispatch_async(dispatch_get_main_queue()){
                    self.addMessage(fromPeer.displayName, text: message)
//                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.finishReceivingMessage()
                }
            }
            else{
                //in this case, only post the last message
                dispatch_async(dispatch_get_main_queue()){
                    self.addMessage("", text: "Chat is ended by the other party")
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.finishReceivingMessage()
                }
            }
        }
    }
    
    func handleLostConnection(notification: NSNotification){
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
    
    //implemente incoming message
    
    //Set lazy variable for CoreData
    lazy var sharedContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
}
