//
//  DanmakuClient.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 27/02/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Alamofire
import CocoaAsyncSocket

// action type (a field of a socket frame)
enum ActionType: Int {
    case ACTION_HEART_BEAT = 2
    case ACTION_ROOM_USER = 3
    case ACTION_JSON_DATA = 5
    case ACTION_JOIN_ROOM = 7
    case ACTION_ENTER_ROOM = 8
}

class DanmakuClient: NSObject {
    weak public var delegate: DanmakuProtocol?
    private let PROTOCOL_VERSION: Int16 = 1
    private var liveId: String = ""
    var sock: GCDAsyncSocket?
    var timer: Timer?
    
    init(liveId: Int, delegate: DanmakuProtocol) {
        self.delegate = delegate
        self.liveId = String(liveId)
    }
    
    deinit {
        debugPrint("DanmakuClient deinit")
    }
    
    public func disconnectServer() {
        self.timer?.invalidate()
        self.sock?.disconnect()
        self.sock = nil
        self.timer = nil
    }
    
    private func getRoomBasicInfo(liveId: String, completionHandler: @escaping (String, String) -> Void) {
        let url = URL(string: "https://live.bilibili.com/\(liveId)")!
        // fetch html
        Alamofire.request(url).responseString { (resp: DataResponse<String>) in
            if resp.result.isFailure {
                let msg = Message(type: .MSG_ERROR("Fetch room info failed"))
                self.delegate?.handleMsg(msg: msg)
                return
            }
            var roomId = ""
            var title = ""
            if let html = resp.result.value {
                // search for room id in html
                guard let roomIdStr = self.getFirstRegexMatch(pattern: "var\\s+roomid\\s+=\\s*(\\d+);", content: html) else {
                    let msg = Message(type: .MSG_ERROR("Fetch room info failed"))
                    self.delegate?.handleMsg(msg: msg)
                    return
                }
                roomId = roomIdStr
                // search for title in html
                guard let titleStr = self.getFirstRegexMatch(pattern: "<title>(.*)</title>", content: html) else {
                    let msg = Message(type: .MSG_ERROR("Fetch room info failed"))
                    self.delegate?.handleMsg(msg: msg)
                    return
                }
                title = titleStr
            }
            completionHandler(roomId, title)
        }
    }
    
    public func connectServer() {
        getRoomBasicInfo(liveId: liveId) { roomId, title in
            self.delegate?.handleMsg(msg: Message(type: .MSG_ROOM_ID(roomId)))
            self.delegate?.handleMsg(msg: Message(type: .MSG_ROOM_TITLE(title)))
            
            // fetch room info
            let url = URL(string: "https://live.bilibili.com/api/player?id=cid:\(roomId)")!
            Alamofire.request(url).responseString { resp in
                let xml = resp.value
                guard xml != nil,
                    let dmHostStr = self.getFirstRegexMatch(pattern: "<server>\\s*(.*)\\s*</server>", content: xml!),
                    let dmPortStr = self.getFirstRegexMatch(pattern: "<dm_port>\\s*(.*)\\s*</dm_port>", content: xml!),
                    let dmPortInt = UInt16(dmPortStr)
                    else {
                        let msg = Message(type: .MSG_ERROR("Error: parsing danmaku server info."))
                        self.delegate?.handleMsg(msg: msg)
                        return
                }
                debugPrint(dmHostStr, dmPortStr)
                // connect to server
                let socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue(label: "bilidanmaku-socket-delegateQueue"))
                do {
                    try socket.connect(toHost: dmHostStr, onPort: dmPortInt)
                } catch {
                    debugPrint("connection failed")
                    return
                }
                // join in room
                let userId = arc4random()
                let dataDict: [String: Int] = ["roomid": Int(roomId)!, "uid": Int(userId)]
                let dataData = try! JSONSerialization.data(withJSONObject: dataDict, options: [])
                let data = self.genSocketFrame(action: .ACTION_JOIN_ROOM, data: dataData)
                socket.write(data, withTimeout: 10, tag: 0)
                self.sock = socket
            }
        }
    }
    
    func handleDanmaku(data: Data) {
        let actType = data.subdata(in: 4..<8).withUnsafeBytes { (t: UnsafePointer<Int32>) in t.pointee }.bigEndian
        let frameData = data.subdata(in: 12..<data.count)
        if Int(actType) == ActionType.ACTION_JSON_DATA.rawValue {
            if let jsonObject = try! JSONSerialization.jsonObject(with: frameData, options: []) as? [String: Any] {
                guard let jsonCmdType = jsonObject["cmd"] as? String else {
                    return
                }
                let jsonCmdTypeUpper = jsonCmdType.uppercased()
                if jsonCmdTypeUpper == "DANMU_MSG" {
                    guard let jsonInfo = jsonObject["info"] as? [Any],
                        let danmuMsg = jsonInfo[1] as? String,
                        let userInfo = jsonInfo[2] as? [Any],
                        let userName = userInfo[1] as? String,
                        let isAdmin = userInfo[2] as? Int,
                        let isVip = userInfo[3] as? Int,
                        let isSVip = userInfo[4] as? Int else {
                            return
                    }
                    let msg = Message(type: .MSG_DANMU_MSG(danmuMsg),
                                      uname: userName,
                                      isadmin: isAdmin,
                                      isvip: isVip, issvip: isSVip)
                    self.delegate?.handleMsg(msg: msg)
                } else if jsonCmdTypeUpper == "SEND_GIFT" {
                    guard let jsonData = jsonObject["data"] as? [String: Any],
                        let giftName = jsonData["giftName"] as? String,
                        let uname = jsonData["uname"] as? String,
                        let num = jsonData["num"] as? Int,
                        let price = jsonData["price"] as? Int else {
                            return
                    }
                    let msg = Message(type: .MSG_GIFT(giftName), uname: uname, num: num, price: price)
                    self.delegate?.handleMsg(msg: msg)
                } else if jsonCmdTypeUpper == "WELCOME" || jsonCmdTypeUpper == "WELCOME_GUARD" {
                    guard let jsonData = jsonObject["data"] as? [String: Any],
                        let uname = jsonData["uname"] as? String,
                        let isAdmin = jsonData["isadmin"] as? Int else {
                            return
                    }
                    var isVip: Int = 0, isSVip: Int = 0
                    if jsonData["vip"] != nil {
                        isVip = 1
                    } else if jsonData["svip"] != nil {
                        isSVip = 1
                    }
                    var type: MsgType = .MSG_WELCOME
                    if jsonCmdTypeUpper == "WELCOME_GUARD" {
                        type = .MSG_WELCOME_GUARD
                    }
                    let msg = Message(type: type,
                                      uname: uname,
                                      isadmin: isAdmin,
                                      isvip: isVip, issvip: isSVip)
                    self.delegate?.handleMsg(msg: msg)
                } else if jsonCmdTypeUpper == "WELCOME_GUARD" {
                    
                } else {
                    let msg = Message(type: .MSG_UNKNOWN_JSON_MSG(jsonCmdTypeUpper))
                    self.delegate?.handleMsg(msg: msg)
                }
            }
        } else if Int(actType) == ActionType.ACTION_ROOM_USER.rawValue {
            let userNum = frameData.toInt32().bigEndian
            let msg = Message(type: .MSG_USER_NUM(Int(userNum)))
            self.delegate?.handleMsg(msg: msg)
        } else if Int(actType) == ActionType.ACTION_ENTER_ROOM.rawValue {
            let msg = Message(type: .MSG_ENTER_ROOM)
            self.delegate?.handleMsg(msg: msg)
        } else {
            debugPrint([UInt8](frameData))
        }
    }
    
    private func getFirstRegexMatch(pattern: String, content: String) -> String? {
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let mTitles = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.characters.count))
        if mTitles.count > 0 {
            let mTitleRange = mTitles[0].rangeAt(1)
            let l = content.index(content.startIndex, offsetBy: mTitleRange.location)
            let r = content.index(l, offsetBy: mTitleRange.length)
            let str = content.substring(with: l..<r)
            return str
        }
        return nil
    }
    
    func genSocketFrame(action: ActionType, data: Data?) -> Data {
        var tempData = Data()
        let totalLen: Int32 = 16 + Int32(data?.count ?? 0)
        let headLen_verPro: Int32 = 16 << 16 | Int32(self.PROTOCOL_VERSION)
        let actionType: Int32 = Int32(action.rawValue)
        let param: Int32 = 1
        
        let arHead: [Int32] = [totalLen.bigEndian, headLen_verPro.bigEndian, actionType.bigEndian, param.bigEndian]
        tempData.append(UnsafeBufferPointer(start: arHead, count: arHead.count))
        if data != nil {
            tempData.append(data!)
        }
        
        return tempData
    }
}

// tags: write
// 0    join room
// 1    heart beat
// tags: read
// 10   Int32, length of the frame
// 11   rest of the frame

extension DanmakuClient: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        if tag == 0 {
            // heart beat, server will response with number of users in the room
            self.heartBeat()
            DispatchQueue.main.async { // any other solution?
                self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.heartBeat), userInfo: nil, repeats: true)
            }
            
            sock.readData(toLength: 4, withTimeout: -1, tag: 10)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if tag == 10 {
            let lenTotal = data.toInt32().bigEndian
            let lenRest = UInt(lenTotal) - 4
            sock.readData(toLength: lenRest, withTimeout: -1, tag: 11)
        } else {
            sock.readData(toLength: 4, withTimeout: -1, tag: 10)
            self.handleDanmaku(data: data)
        }
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if let e = err {
            debugPrint("disconnect", e)
        }
    }
    
    @objc private func heartBeat() {
        let data = self.genSocketFrame(action: .ACTION_HEART_BEAT, data: nil)
        self.sock?.write(data, withTimeout: -1, tag: 1)
    }
}
