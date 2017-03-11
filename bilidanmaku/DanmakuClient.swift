//
//  DanmakuClient.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 27/02/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Alamofire

// action type (a field of a socket frame)
enum ActionType: Int32 {
    case ACTION_HEART_BEAT = 2
    case ACTION_ROOM_USER = 3
    case ACTION_JSON_DATA = 5
    case ACTION_JOIN_ROOM = 7
    case ACTION_ENTER_ROOM = 8
}

class DanmakuClient: NSObject {
    public var delegate: DanmakuProtocol
    private let PROTOCOL_VERSION: Int16 = 1
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private var liveId: String = ""
    private var running: Bool = false
    
    init(liveId: Int, delegate: DanmakuProtocol) {
        self.delegate = delegate
        self.liveId = String(liveId)
    }
    
    deinit {
        debugPrint("DanmakuClient deinit")
    }
    
    public func disconnectServer() {
        self.running = false
    }
    
    public func connectServer() {
        getRoomBasicInfo(liveId: liveId) {
            (roomId, title) in
            self.delegate.handleMsg(msg: Message(type: .MSG_ROOM_ID(roomId)))
            self.delegate.handleMsg(msg: Message(type: .MSG_ROOM_TITLE(title)))
            
            // fetch room info
            let url = URL(string: "https://live.bilibili.com/api/player?id=cid:" + roomId)!
            Alamofire.request(url).responseString {
                resp in
                let xml = resp.value
                guard xml != nil,
                let urlDmServerStr = self.getFirstRegexMatch(pattern: "<server>\\s*(.*)\\s*</server>", content: xml!),
                let portDmServerStr = self.getFirstRegexMatch(pattern: "<dm_port>\\s*(.*)\\s*</dm_port>", content: xml!),
                let portDmServerInt = Int(portDmServerStr)
                else {
                    let msg = Message(type: .MSG_ERROR("Error: parsing danmaku server info."))
                    self.delegate.handleMsg(msg: msg)
                    return
                }
                debugPrint(urlDmServerStr, portDmServerStr)
                // connect to server
                Stream.getStreamsToHost(withName: urlDmServerStr, port: portDmServerInt, inputStream: &self.inputStream, outputStream: &self.outputStream)
                guard let inputStream = self.inputStream,
                    let outputStream = self.outputStream
                    else {
                        let msg = Message(type: .MSG_ERROR("Error: connecting to danmaku server."))
                        self.delegate.handleMsg(msg: msg)
                        return
                }
                inputStream.open()
                outputStream.open()
                // join in room
                let userId = arc4random()
                let dataDict: [String: Int] = ["roomid": Int(roomId)!, "uid": Int(userId)]
                let dataData = try! JSONSerialization.data(withJSONObject: dataDict, options: [])
                let dataJson = String(data: dataData, encoding: .utf8)
                debugPrint(dataJson!)
                self.sendSocketData(action: .ACTION_JOIN_ROOM, data: dataJson!)
                // heart beat, server will response with number of users in the room
                self.hearBeat()
                Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.hearBeat), userInfo: nil, repeats: true)
                
                // handle danmaku
                self.running = true
                DispatchQueue.global().async {
                    self.parseDanmakuData()
                    debugPrint("end parse")
                }
            }
        }
    }
    
    private func parseDanmakuData() {
        while self.running {
            let totalLen = self.readSocketData32()
            let _ = self.readSocketData32() // skip data
            let actType = self.readSocketData32()
            let d = self.readSocketData32()
            guard self.running == true else {
                self.inputStream?.close()
                self.outputStream?.close()
                break
            }
            if totalLen >= 16 {
                if Int32(actType) == ActionType.ACTION_JSON_DATA.rawValue {
                    let jsonRaw = self.readSocketData(length: Int(totalLen) - 16)
                    if let jsonObject = try! JSONSerialization.jsonObject(with: Data(bytes: jsonRaw), options: []) as? [String: Any] {
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
                                let isSVip = userInfo[4] as? Int
                                else {
                                    continue
                            }
                            let msg = Message(type: .MSG_DANMU_MSG(danmuMsg),
                                              uname: userName,
                                              isadmin: isAdmin,
                                              isvip: isVip, issvip: isSVip)
                            self.delegate.handleMsg(msg: msg)
                        } else if jsonCmdTypeUpper == "SEND_GIFT" {
                            guard let jsonData = jsonObject["data"] as? [String: Any],
                                let giftName = jsonData["giftName"] as? String,
                                let uname = jsonData["uname"] as? String,
                                let num = jsonData["num"] as? Int
                                else {
                                    continue
                            }
                            let msg = Message(type: .MSG_GIFT(giftName), uname: uname, num: num)
                            self.delegate.handleMsg(msg: msg)
                        } else if jsonCmdTypeUpper == "WELCOME" {
                            guard let jsonData = jsonObject["data"] as? [String: Any],
                                let uname = jsonData["uname"] as? String,
                                let isAdmin = jsonData["isadmin"] as? Int
                                else {
                                    continue
                            }
                            var isVip: Int = 0, isSVip: Int = 0
                            if jsonData["vip"] != nil {
                                isVip = 1
                            } else if jsonData["svip"] != nil {
                                isSVip = 1
                            }
                            let msg = Message(type: .MSG_WELCOME,
                                              uname: uname,
                                              isadmin: isAdmin,
                                              isvip: isVip, issvip: isSVip)
                            self.delegate.handleMsg(msg: msg)
                        } else {
                            let msg = Message(type: .MSG_UNKNOWN_JSON_MSG(jsonCmdTypeUpper))
                            self.delegate.handleMsg(msg: msg)
                        }
                    }
                } else if Int32(actType) == ActionType.ACTION_ROOM_USER.rawValue {
                    let userNum = self.readSocketData32()
                    let msg = Message(type: .MSG_USER_NUM(Int(userNum)))
                    self.delegate.handleMsg(msg: msg)
                } else if Int32(actType) == ActionType.ACTION_ENTER_ROOM.rawValue {
                    let msg = Message(type: .MSG_ENTER_ROOM)
                    self.delegate.handleMsg(msg: msg)
                } else {
                    let t = self.readSocketData(length: Int(totalLen) - 16)
                    debugPrint(t)
                }
            } else {
                debugPrint("totalLen", totalLen, "actType", actType, d)
            }
        }
    }
    
    private func readSocketData(length: Int) -> [UInt8] {
        var buf = [UInt8](repeating: 0, count: length)
        self.inputStream!.read(&buf, maxLength: length)
        return buf
    }
    
    private func readSocketData32() -> UInt32 {
        var buf32: UInt32
        buf32 = UInt32(readSocketData16()) << 16 | UInt32(readSocketData16())
        return buf32
    }
    
    private func readSocketData16() -> UInt16 {
        var buf16: UInt16
        buf16 = UInt16(readSocketData8()) << 8 | UInt16(readSocketData8())
        return buf16
    }
    
    private func readSocketData8() -> UInt8 {
        var buf8: UInt8 = 0
        self.inputStream!.read(&buf8, maxLength: 1)
        return buf8
    }
    
    @objc private func hearBeat() {
        self.sendSocketData(action: .ACTION_HEART_BEAT, data: "")
    }
    
    private func getRoomBasicInfo(liveId: String, completionHandler: @escaping (String, String) -> Void) {
        let url = "https://live.bilibili.com"
        // fetch html
        Alamofire.request(URL(string: url)!.appendingPathComponent(liveId)).responseString{ response in
            var roomId = ""
            var title = ""
            if let html = response.value {
                // search for room id in html
                guard let roomIdStr = self.getFirstRegexMatch(pattern: "var\\s+roomid\\s+=\\s*(\\d+);", content: html) else {
                    return
                }
                roomId = roomIdStr
                // search for title in html
                guard let titleStr = self.getFirstRegexMatch(pattern: "<title>(.*)</title>", content: html) else {
                    return
                }
                title = titleStr
            }
            completionHandler(roomId, title)
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
    
    private func sendSocketData(action: ActionType, data: String) {
        var tempData = Data()
        let totalLen: Int32 = 16 + data.characters.count
        let headLen_verPro: Int32 = 16 << 16 | Int32(self.PROTOCOL_VERSION)
        let actionType: Int32 = action.rawValue
        let param: Int32 = 1
        
        let arHead: [Int32] = [totalLen.bigEndian, headLen_verPro.bigEndian, actionType.bigEndian, param.bigEndian]
        tempData.append(UnsafeBufferPointer(start: arHead, count: arHead.count))
        if data.characters.count > 0 {
            let dataBytes = [UInt8](data.utf8)
            tempData.append(contentsOf: dataBytes)
        }
        
        var ar = Array(tempData)
        self.outputStream!.write(&ar, maxLength: ar.count)
    }
}
