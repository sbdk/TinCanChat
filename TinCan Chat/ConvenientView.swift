//
//  ConvenientView.swift
//  TinCan Chat
//
//  Created by Li Yin on 6/12/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import UIKit

class ConvenientView: NSObject {
    
    class func sharedInstance() -> ConvenientView {
        struct Singleton {
            static var sharedInstance = ConvenientView()
        }
        return Singleton.sharedInstance
    }
    
    func showAlertView(title: String, message: String, hostView: UIViewController){
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(okAction)
        hostView.presentViewController(controller, animated: true, completion: nil)
    }
    
    func setLabel(label: UILabel, fontName: String, size: CGFloat, color: UIColor){
        label.font = UIFont(name: fontName, size: size)
        label.textColor = color
    }
    
    func setRoundButton(button: UIButton){
        button.layer.cornerRadius = button.bounds.size.width * 0.5
    }
    
    func enhanceItemUI(button: UIButton, cornerRadius: CGFloat){
        
        button.layer.shadowColor = UIColor.blackColor().CGColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        button.layer.cornerRadius = cornerRadius
        button.showsTouchWhenHighlighted = true
        
    }
}
