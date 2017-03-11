//
//  ViewController.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 27/02/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, DanmakuProtocol {
    @IBOutlet weak var textFieldLiveId: NSTextField!
    @IBOutlet weak var btnConnect: NSButton!
    @IBOutlet weak var btnDisconnect: NSButton!
    private var danmakuClient: DanmakuClient?
    private var danmakuWindow: DanmakuWindowController?
    private var danmakuView: DanmakuViewController?

    @IBAction func onConnectClicked(_ sender: NSButton) {
        self.onConnect()
    }
    
    @IBAction func onDisconnectClicked(_ sender: NSButton) {
        self.onDisconnect()
    }
    
    @IBAction func onEndEditingLiveId(_ sender: Any) {
        self.onConnect()
    }
    
    private func onDisconnect() {
        self.danmakuClient?.disconnectServer()
        self.danmakuClient = nil
        self.textFieldLiveId.isEnabled = true
        self.btnConnect.isEnabled = true
        self.btnDisconnect.isEnabled = false
    }
    
    private func onConnect() {
        let liveIdStr = self.textFieldLiveId.stringValue
        guard liveIdStr.characters.count > 0,
            let liveId = Int(liveIdStr)
            else {
                return
        }
        debugPrint(liveId)
        
        self.textFieldLiveId.isEnabled = false
        self.btnConnect.isEnabled = false
        self.btnDisconnect.isEnabled = true

        self.danmakuClient = DanmakuClient(liveId: liveId, delegate: self)
        self.danmakuClient!.connectServer()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.textFieldLiveId.formatter = IntegerOnlyFormatter()
        self.btnDisconnect.isEnabled = false
        
        self.danmakuWindow = self.storyboard?.instantiateController(withIdentifier: "DanmakuWindow") as? DanmakuWindowController
        self.danmakuWindow?.showWindow(self)
        self.danmakuView = self.danmakuWindow?.contentViewController as? DanmakuViewController
        
        
        let fontSize: CGFloat = 15
        let font = NSFontManager.shared().font(withFamily: "Heiti SC",
                                               traits: NSFontTraitMask.boldFontMask,
                                               weight: 0,
                                               size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let attributes: [String: Any] = [NSForegroundColorAttributeName: NSColor.white,
                                         NSFontAttributeName: font,
                                         //                                         NSParagraphStyleAttributeName: paragraphStyle
        ]
        let str = "NSAttributedString"
        let attrStr = NSAttributedString(string: str, attributes: attributes)
//        for _ in 1..<63 {
//            self.danmakuView?.appendDanmakuItem(string: attrStr)
//        }
//        self.danmakuView?.appendDanmakuItem(string: attrStr)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // DanmakuProtocol
    func handleMsg(msg: Message) {
        let fontSize: CGFloat = 15
        let font = NSFontManager.shared().font(withFamily: "Heiti SC",
                                               traits: NSFontTraitMask.boldFontMask,
                                               weight: 0,
                                               size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let attrNormal: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:1, green:1, blue:1, alpha:1),
                                         NSFontAttributeName: font]
        let attrGift: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:1, green:0.709, blue:0.134, alpha:1),
                                         NSFontAttributeName: font]
        let attrUser: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:0.31, green:0.757, blue:0.914, alpha:1),
                                       NSFontAttributeName: font]
        let attrWelcome: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:1, green:0.426, blue:0.627, alpha:1),
                                       NSFontAttributeName: font]
        let attrAdmin: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:0.708, green:0.59, blue:1, alpha:1),
                                        NSFontAttributeName: font]
        
        switch msg.type {
        case .MSG_ROOM_ID(let roomId):
            debugPrint("房号: ", roomId)
        case .MSG_ROOM_TITLE(let title):
            debugPrint("标题: ", title)
        case .MSG_DANMU_MSG(let danmu):
            var userStr: NSAttributedString
            if msg.isadmin {
                userStr = NSAttributedString(string: "\(msg.uname)：", attributes: attrAdmin)
            } else {
                userStr = NSAttributedString(string: "\(msg.uname)：", attributes: attrUser)
            }
            
            let msgStr = NSAttributedString(string: danmu, attributes: attrNormal)
            
            let str = NSMutableAttributedString()
            str.append(userStr)
            str.append(msgStr)
            self.danmakuView?.appendDanmakuItem(string: str)
        case .MSG_GIFT(let giftName):
            let giftStr = NSAttributedString(string: "礼物：", attributes: attrGift)
            
            var userStr: NSAttributedString
            if msg.isadmin {
                userStr = NSAttributedString(string: "\(msg.uname)：", attributes: attrAdmin)
            } else {
                userStr = NSAttributedString(string: "\(msg.uname)：", attributes: attrUser)
            }
            
            var numStr = ""
            if msg.num > 1 {
                numStr = " x\(msg.num)"
            }
            let msgStr = NSMutableAttributedString(string: "\(giftName)\(numStr)", attributes: attrNormal)
            
            let str = NSMutableAttributedString()
            str.append(giftStr)
            str.append(userStr)
            str.append(msgStr)
            self.danmakuView?.appendDanmakuItem(string: str)
        case .MSG_USER_NUM(let userNum):
            debugPrint("人数：", userNum)
        case .MSG_WELCOME:
            let welcStr = NSAttributedString(string: "欢迎：", attributes: attrWelcome)
            let msgStr = NSAttributedString(string: "\(msg.uname)", attributes: attrNormal)
            
            let str = NSMutableAttributedString()
            str.append(welcStr)
            str.append(msgStr)
            self.danmakuView?.appendDanmakuItem(string: str)
        case .MSG_UNKNOWN_JSON_MSG(let cmd):
            debugPrint("未知：", cmd)
        default:
            debugPrint("default")
        }
    }
}

