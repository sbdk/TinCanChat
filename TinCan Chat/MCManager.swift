//
//  MCManager.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/11/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import MultipeerConnectivity

enum MCManagerSessionNotifications: String {
  case connectingWithPeer
  case connectedWithPeer
  case notConnectedWithPeer
  case receivedData
}

class MCManager: NSObject, MCSessionDelegate {
    static let sharedInstance = MCManager()
  
    //Defin core variables for MCManager class
    var peerID: MCPeerID
    var session: MCSession
    var browser: MCNearbyServiceBrowser
    var advertiser: MCNearbyServiceAdvertiser
  
    //Defin temperary collection variables to store temp data
    var foundPeers: [MCPeerID] = [] //used to store nearby peers found by browser
    var connectedPeers: [MCPeerID] = [] //used to store connected peers
    var chatHistoryDict:[String:AnyObject]? //used to store temp chat history
  
  override init(){
    peerID = MCPeerID(displayName: UIDevice.currentDevice().name) //use device name to set default peerID
    session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .None)
    browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "TinCanChat")
    advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "TinCanChat")
    super.init()
    session.delegate = self
  }

  //Method for resetting session with a new Chat name
  func resetSessionWithNewChatName(name: String){
    peerID = MCPeerID(displayName: name)
    session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .None)
    session.delegate = self
    browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "TinCanChat")
    advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "TinCanChat")
  }
  
  //Method for sending data between peers
  func sendData(dictionaryWithData dictionary: [String:String], toPeer targetPeer: MCPeerID) -> Bool {
    let dataToSend = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
    let receivingPeersArray = [targetPeer]
    do {
        try session.sendData(dataToSend, toPeers: receivingPeersArray, withMode: MCSessionSendDataMode.Reliable)
        return true
    } catch let error {
        print("Error: \(error)")
        return false
    }
  }
}
