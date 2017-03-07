//
//  DanmakuWindowController.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 06/03/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Cocoa

class DanmakuWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.level = Int(CGWindowLevelForKey(.maximumWindow))
    }
}
