//
//  DanmakuWindowController.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 06/03/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Cocoa

class DanmakuWindowController: NSWindowController {
    private let width: CGFloat = 250
    private var height: CGFloat = 0
    
    override func windowDidLoad() {
        // set the window position and size
        self.window?.level = Int(CGWindowLevelForKey(.maximumWindow))
        self.window?.collectionBehavior = [.stationary, .canJoinAllSpaces, .fullScreenAuxiliary]
        guard let frame = NSScreen.main()?.visibleFrame else {
            return
        }
        height = frame.height
        let posX = frame.width - width
        let posY = frame.minY
        let rect = CGRect(x: posX, y: posY, width: width, height: height)
        self.window?.setFrame(rect, display: true)
        
        // initialize view
        let viewController = self.contentViewController as! DanmakuViewController
        viewController.initialize()
        
        // set the window style
        self.window?.backgroundColor = NSColor.clear
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            NSApplication.shared().windows.forEach {
                if $0.isVisible == false {
                    $0.makeKeyAndOrderFront(self)
                }
            }
        }
    }
}
