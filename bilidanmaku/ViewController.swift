//
//  ViewController.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 27/02/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, DanmakuProtocol {
    @IBOutlet weak var txtLiveId: NSTextField!
    @IBOutlet weak var txtLog: NSTextView!
    @IBOutlet weak var txtShowTime: NSTextField!
    @IBOutlet weak var btnConnect: NSButton!
    @IBOutlet weak var btnDisconnect: NSButton!
    @IBOutlet weak var sldShowTime: NSSlider!
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
    
    @IBAction func onShowTimeChanged(_ sender: NSSlider) {
        let showTime = sender.doubleValue.rounded().toInt()
        self.txtShowTime.integerValue = showTime
        self.sldShowTime.integerValue = showTime
        ConfigManager.shared.danmakuScene.showTime = showTime
    }
    
    private func onDisconnect() {
        self.danmakuClient?.disconnectServer()
        self.danmakuClient = nil
        self.danmakuView?.clearDanmakuItems()
        
        self.txtLiveId.isEnabled = true
        self.btnConnect.isEnabled = true
        self.btnDisconnect.isEnabled = false
    }
    
    private func onConnect() {
        let liveIdStr = self.txtLiveId.stringValue
        guard liveIdStr.characters.count > 0,
            let liveId = Int(liveIdStr) else {
                return
        }
        
        self.danmakuView?.resetStats()
        
        self.txtLiveId.isEnabled = false
        self.btnConnect.isEnabled = false
        self.btnDisconnect.isEnabled = true
        
        self.danmakuClient = DanmakuClient(liveId: liveId, delegate: self)
        self.danmakuClient!.connectServer()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.txtLiveId.formatter = IntegerOnlyFormatter()
        self.txtShowTime.integerValue = ConfigManager.shared.danmakuScene.showTime
        self.sldShowTime.integerValue = ConfigManager.shared.danmakuScene.showTime
        self.btnDisconnect.isEnabled = false
        
        self.danmakuWindow = self.storyboard?.instantiateController(withIdentifier: "DanmakuWindow") as? DanmakuWindowController
        self.danmakuWindow?.showWindow(self)
        self.danmakuView = self.danmakuWindow?.contentViewController as? DanmakuViewController
        
        // FIXME: 64 danmaku at once
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // DanmakuProtocol
    func handleMsg(msg: Message) {
        let fontSize1: CGFloat = 15
        let font1 = NSFontManager.shared().font(withFamily: "Heiti SC",
                                                traits: NSFontTraitMask.boldFontMask,
                                                weight: 0,
                                                size: fontSize1) ?? NSFont.systemFont(ofSize: fontSize1)
        // white
        let attrNormal: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:1, green:1, blue:1, alpha:1),
                                         NSFontAttributeName: font1]
        // orange
        let attrGift: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:1, green:0.709, blue:0.134, alpha:1),
                                       NSFontAttributeName: font1]
        // blue
        let attrUser: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:0.31, green:0.757, blue:0.914, alpha:1),
                                       NSFontAttributeName: font1]
        // red
        let attrWelcome: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:1, green:0.426, blue:0.627, alpha:1),
                                          NSFontAttributeName: font1]
        // green
        let attrWelcGuard: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:0.663, green:1, blue:0.388, alpha:1),
                                            NSFontAttributeName: font1]
        // purple
        let attrAdmin: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:0.708, green:0.59, blue:1, alpha:1),
                                        NSFontAttributeName: font1]
        
        let fontSize2: CGFloat = 13
        let font2 = NSFontManager.shared().font(withFamily: "Heiti SC",
                                                traits: NSFontTraitMask.unboldFontMask,
                                                weight: 0,
                                                size: fontSize2) ?? NSFont.systemFont(ofSize: fontSize2)
        let attrLogTitle: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:0.31, green:0.757, blue:0.914, alpha:1),
                                           NSFontAttributeName: font2]
        let attrLogContent: [String: Any] = [NSForegroundColorAttributeName: NSColor(red:0.3, green:0.3, blue:0.3, alpha:1),
                                             NSFontAttributeName: font2]
        
        switch msg.type {
        case .MSG_ROOM_ID(let roomId):
            let title = NSAttributedString(string: "房间号: ", attributes: attrLogTitle)
            let content = NSAttributedString(string: "\(roomId)\n", attributes: attrLogContent)
            self.txtLog.textStorage?.append(title)
            self.txtLog.textStorage?.append(content)
            self.txtLog.scrollToEndOfDocument(self)
        case .MSG_ROOM_TITLE(let title):
            let titl = NSAttributedString(string: "标题: ", attributes: attrLogTitle)
            let content = NSAttributedString(string: "\(title)\n", attributes: attrLogContent)
            self.txtLog.textStorage?.append(titl)
            self.txtLog.textStorage?.append(content)
            self.txtLog.scrollToEndOfDocument(self)
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
            self.danmakuView?.updateDanmakuNum()
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
            self.danmakuView?.updateGiftNum(num: msg.num)
            self.danmakuView?.updateCostNum(num: msg.num * msg.price)
        case .MSG_USER_NUM(let userNum):
            self.danmakuView?.setUserNum(num: userNum)
        case .MSG_WELCOME:
            let welcStr = NSAttributedString(string: "欢迎老爷：", attributes: attrWelcome)
            let msgStr = NSAttributedString(string: "\(msg.uname)", attributes: attrNormal)
            
            let str = NSMutableAttributedString()
            str.append(welcStr)
            str.append(msgStr)
            self.danmakuView?.appendDanmakuItem(string: str)
        case .MSG_WELCOME_GUARD:
            let welcStr = NSAttributedString(string: "欢迎舰长：", attributes: attrWelcGuard)
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
