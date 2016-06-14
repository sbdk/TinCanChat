//
//  BrowserViewController.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/11/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import CoreData
import MultipeerConnectivity

class BrowserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MCManagerBrowserDelegate, MCManagerSessionDelegate {

    @IBOutlet weak var browserTableView: UITableView!
    @IBOutlet weak var browserActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var browserViewTopLabel: UILabel!
    @IBOutlet weak var dismissButton: UIBarButtonItem!

    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var cellDetailText: String!
    var searchingPeer: Bool = true
    var connectWithPeer: String = ""
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //prepare view UI according to the status of this browserView
        if searchingPeer{
            browserViewTopLabel.text = "Searching"
            cellDetailText = "Touch to connect"
        }else{
            browserViewTopLabel.text = "Connecting"
            browserTableView.allowsSelection = false
            cellDetailText = "connecting..."
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        browserTableView.delegate = self
        browserTableView.dataSource = self
        browserTableView.tableFooterView = UIView(frame: CGRectZero)
        appDelegate.mcManager.browserDelegate = self
        appDelegate.mcManager.sessionDelegate = self
        browserActivityIndicator.startAnimating()
        appDelegate.mcManager.browser.startBrowsingForPeers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        appDelegate.mcManager.foundPeers.removeAll()
        appDelegate.mcManager.browser.stopBrowsingForPeers()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mcManager.foundPeers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let peerID = appDelegate.mcManager.foundPeers[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("browserTableCell")! as! PeerCell
        cell.foundPeerLabel?.text = peerID.displayName
        
        //If already connected peer, it will show up in browserView list, so we set its status label to connected
        if appDelegate.mcManager.connectedPeers.containsObject(peerID){
            cell.connectStatusLabel?.text = "connected 😎"
        }
            //For the peer user currently connecting with, pass cellDetailText value to this peer's status label
        else if peerID.displayName == connectWithPeer {
            cell.connectStatusLabel?.text = cellDetailText
        }
            //For not connecting peer that shown in BrowserView list, set it's status Label to default
        else {
            cell.connectStatusLabel?.text = "Touch to connect"
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //By disable selection for tableView after selecting a row, make sure only one invitation is been sent and send only once
        browserTableView.allowsSelection = false
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! PeerCell
        let peerID = appDelegate.mcManager.foundPeers[indexPath.row]
        
        //Set the current connecting peer info with selected peerID
        connectWithPeer = peerID.displayName
        
        if appDelegate.mcManager.connectedPeers.containsObject(peerID){
            //Do noting if the found peer has already connected
        } else {
            cell.connectStatusLabel!.text = "request sent...😐"
            
            //Sent the invitation
            appDelegate.mcManager.browser.invitePeer(peerID, toSession: appDelegate.mcManager.session, withContext: nil, timeout: 10)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //Implemente Custom MCManagerBrowserDelegate
    func foundPeer() {
        browserTableView.reloadData()
    }
    
    func lostPeer() {
        browserTableView.reloadData()
    }
    
    //implemente Custom MCManagerSessionDelegate
    func connectedWithPeer(peerID: MCPeerID) {
        cellDetailText = "connected 😎"
        print(cellDetailText)
        //When connect success,dismiss the browserView
        dispatch_async(dispatch_get_main_queue()){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func connectingWithPeer() {
        cellDetailText = "connecting...😍"
        dispatch_async(dispatch_get_main_queue()){
            self.browserTableView.reloadData()
        }
    }
    
    func notConnectedWithPeer(peerID: MCPeerID) {
        cellDetailText = "connect failed 😭"
        dispatch_async(dispatch_get_main_queue()){
            self.browserTableView.reloadData()
        }
    }
    
    //Config the dismiss button action
    @IBAction func cancelButtonTouched(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /*** CoreData Implementation ***/
    
//    //Set lazy variable for CoreData
//    lazy var sharedContext = {
//        return CoreDataStackManager.sharedInstance().managedObjectContext
//    }()
//    
//    //Convenient function for later use, enable real-time fetch with predicate
//    func peerFetchController(predicatePeerName: String) -> NSFetchedResultsController {
//        let fetchRequest = NSFetchRequest(entityName: "ChatPeer")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastChatTime", ascending: true)]
//        fetchRequest.predicate = NSPredicate(format: "peerName == %@", predicatePeerName)
//        let fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
//        fetchedRequestController.delegate = self
//        return fetchedRequestController
//    }
//    
//    //implemente FetchedResultController Delegate Method
//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//        browserTableView.beginUpdates()
//    }
//    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
//                    atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
//        switch type {
//        case .Insert:
//            break
//        case .Delete:
//            break
//        default:
//            return
//        }
//    }
//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType,newIndexPath: NSIndexPath?) {
//        switch type {
//        case .Insert:
//            break
//        case .Delete:
//            break
//        case .Update:
//            break
//        case .Move:
//            break
//        }
//    }
//    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        browserTableView.endUpdates()
//    }

}
