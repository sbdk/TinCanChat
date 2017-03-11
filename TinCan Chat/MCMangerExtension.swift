//
//  MCMangerExtension.swift
//  TinCan Chat
//
//  Created by Li Yin on 10/11/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension MCManager {
    
//  func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
//    print(error.localizedDescription)
//  }
  
  func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
    switch state {
      case .Connecting:
        print("Connecting to session")
        NSNotificationCenter.defaultCenter().postNotificationName(MCManagerSessionNotifications.connectingWithPeer.rawValue, object: peerID)
      case .Connected:
        print("Connected to session")
        MCManager.sharedInstance.connectedPeers.append(peerID)
        NSNotificationCenter.defaultCenter().postNotificationName(MCManagerSessionNotifications.connectedWithPeer.rawValue, object: peerID)
      case .NotConnected:
        print("Did not connect to session")
        if let index = MCManager.sharedInstance.connectedPeers.indexOf(peerID) {
          MCManager.sharedInstance.connectedPeers.removeAtIndex(index) //frist remove the peerID from temp connectedPeers array
          NSNotificationCenter.defaultCenter().postNotificationName(MCManagerSessionNotifications.notConnectedWithPeer.rawValue, object: peerID)
        } else {
          print("peer is already disconnected")
          return
        }
    }
  }
  
  func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
    
  }
  
  func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
    
  }
  
  func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
    //for every received data, use a dictionary to store received data and sender's MCPeerID
    let dictionary:[String:AnyObject] = ["data": data, "fromPeer": peerID]
    NSNotificationCenter.defaultCenter().postNotificationName(MCManagerSessionNotifications.receivedData.rawValue, object: dictionary)
  }
  
  func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    
  }
}

  
