//
//  ViewController.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 27/02/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, DanmakuProtocol {
    @IBOutlet weak var liveIdTextField: NSTextField!
    
    func log(type: LogType, text: String) {
    }

    @IBAction func onConnectClicked(_ sender: NSButton) {
//        let self.liveIdTextField.stringValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

