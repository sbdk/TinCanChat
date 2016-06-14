//
//  PeerCell.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/11/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation

import UIKit

class PeerCell: UITableViewCell {
    
    //BrowserViewTableCell
    @IBOutlet weak var foundPeerLabel: UILabel!
    @IBOutlet weak var connectStatusLabel: UILabel!
    
    
    //ChatRecord TableCell
    @IBOutlet weak var connectedPeerLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
}
