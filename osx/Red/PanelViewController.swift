//
//  PanelViewController.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/11/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class PanelViewController: NSSplitViewController {
    
    var mainMenu : NSMenu!

    convenience init(menu: NSMenu) {
        self.init(nibName: nil, bundle: nil)
        
        mainMenu = menu
    }
    
    @IBAction func splitVertically(_ sender: NSMenuItem) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
