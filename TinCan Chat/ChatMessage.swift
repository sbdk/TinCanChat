//
//  ChatMessage.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/11/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import CoreData

class ChatMessage: NSManagedObject {
    
    @NSManaged var messageSender: String?
    @NSManaged var messageBody: String
    @NSManaged var messageTime: NSDate
    @NSManaged var messagePeer: ChatPeer
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(sender: String?, body: String, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("ChatMessage", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        messageSender = sender
        messageBody = body
        messageTime = NSDate()
    }
    
}