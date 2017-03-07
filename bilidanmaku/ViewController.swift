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

    @IBAction func onConnectClicked(_ sender: NSButton) {
        self.connectServer()
    }
    
    @IBAction func onDisconnectClicked(_ sender: NSButton) {
        self.onDisconnect()
    }
    
    @IBAction func onEndEditingLiveId(_ sender: Any) {
        self.connectServer()
    }
    
    private func onDisconnect() {
        self.danmakuClient?.disconnectServer()
        self.danmakuClient = nil
        self.textFieldLiveId.isEnabled = true
        self.btnConnect.isEnabled = true
        self.btnDisconnect.isEnabled = false
    }
    
    private func connectServer() {
        let liveIdStr = self.textFieldLiveId.stringValue
        guard liveIdStr.characters.count > 0  else {
            return
        }
        guard let liveId = Int(liveIdStr) else {
            return
        }
        debugPrint(liveId)
        self.danmakuClient = DanmakuClient(liveId: liveId, delegate: self)
        self.danmakuClient!.connectServer()
        self.textFieldLiveId.isEnabled = false
        self.btnConnect.isEnabled = false
        self.btnDisconnect.isEnabled = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.textFieldLiveId.formatter = IntegerOnlyFormatter()
        self.btnDisconnect.isEnabled = false
        
        self.danmakuWindow = self.storyboard?.instantiateController(withIdentifier: "DanmakuWindow") as? DanmakuWindowController
        self.danmakuWindow?.showWindow(self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // DanmakuProtocol
    func handleMsg(msg: Message) {
        switch msg.type {
        case .MSG_ROOM_ID(let roomId):
            debugPrint("房号: ", roomId)
        case .MSG_ROOM_TITLE(let title):
            debugPrint("标题: ", title)
        case .MSG_DANMU_MSG(let danmu):
            debugPrint("消息：", danmu, msg.uname, msg.isadmin, msg.vip)
        case .MSG_GIFT(let giftName):
            debugPrint("礼物：", giftName, msg.uname, msg.isadmin, msg.vip)
        case .MSG_USER_NUM(let userNum):
            debugPrint("人数：", userNum)
        case .MSG_WELCOME:
            debugPrint("欢迎：", msg.uname)
        case .MSG_UNKNOWN_JSON_MSG(let cmd):
            debugPrint("未知：", cmd)
        default:
            debugPrint("default")
        }
    }
}

