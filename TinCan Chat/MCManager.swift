//
//  MCManager.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/11/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation


import MultipeerConnectivity

protocol MCManagerBrowserDelegate {
    func foundPeer()
    func lostPeer()
}

protocol MCManagerInvitationDelegate {
    func invitationWasReceived(fromPeer: String, invitationHandler:(Bool, MCSession?) -> Void)
}

protocol MCManagerSessionDelegate {
    func connectedWithPeer(peerID: MCPeerID)
    func connectingWithPeer()
    func notConnectedWithPeer(peerID: MCPeerID)
}

class MCManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    var connectedPeers: NSMutableArray!
    var chatHistoryDict:[String:AnyObject]!
    
    var browserDelegate: MCManagerBrowserDelegate?
    var invitationDelegate: MCManagerInvitationDelegate?
    var sessionDelegate: MCManagerSessionDelegate?
    
    override init(){
        super.init()
        peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: peerID)
        session.delegate = self
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "TinCanChat")
        browser.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "TinCanChat")
        advertiser.delegate = self
        connectedPeers = []
        chatHistoryDict = [:]
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        foundPeers.append(peerID)
        browserDelegate?.foundPeer()
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        for (index, peer) in foundPeers.enumerate() {
            if peer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
        browserDelegate?.lostPeer()
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print(error.localizedDescription)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        print("received a invitation")
        self.invitationDelegate?.invitationWasReceived(peerID.displayName){(Bool, MCSession) in
            invitationHandler(Bool, MCSession!)
        }
        
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print(error.localizedDescription)
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        switch state {
        case MCSessionState.Connected:
            print("Connected to session")
            connectedPeers.addObject(peerID)
            sessionDelegate?.connectedWithPeer(peerID)
            NSNotificationCenter.defaultCenter().postNotificationName("connectedWithPeer", object: peerID)
        case MCSessionState.Connecting:
            print("Connecting to session")
            sessionDelegate?.connectingWithPeer()
        default:
            print("Did not connect to session")
            connectedPeers.removeObject(peerID)
            sessionDelegate?.notConnectedWithPeer(peerID)
            NSNotificationCenter.defaultCenter().postNotificationName("lostConnectionWithPeer", object: peerID)
        }
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
        //for every received data, use a dictionary to store received data and sender's MCPeerID
        let dictionary:[String:AnyObject] = ["data": data, "fromPeer": peerID]
        NSNotificationCenter.defaultCenter().postNotificationName("receivedMCDataNotification", object: dictionary)
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func setupPeerAndSessionWithDisplayName(name: String){
        peerID = MCPeerID.init(displayName: name)
        session = MCSession.init(peer: peerID)
        session.delegate = self
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "TinCanChat")
        browser.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "TinCanChat")
        advertiser.delegate = self
    }
    
    func sendData(dictionaryWithData dictionary: [String:String], toPeer targetPeer: MCPeerID) -> Bool {
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
        let peersArray = NSArray(object: targetPeer)
        do {
            try session.sendData(dataToSend, toPeers: peersArray as! [MCPeerID], withMode: MCSessionSendDataMode.Reliable)
            return true
        } catch {
            print("There is a error during sending data")
            return false
        }
    }
}
