//
//  danmaku.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 27/02/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import SocketIO
import Alamofire

enum LogType {
    case LOG_ROOM_ID
    case LOG_ROOM_TITLE
}

class Danmaku {
    public var delegate: DanmakuProtocol
    private var socket: SocketIOClient?
    private var liveId: String = ""
    
    init(liveId: Int, delegate: DanmakuProtocol) {
        self.delegate = delegate
        self.liveId = String(liveId)
    }
    
    public func connectServer() {
        getRoomBasicInfo(liveId: liveId) {
            (roomId, title, hasError) in
            self.delegate.log(type: .LOG_ROOM_ID, text: roomId)
            self.delegate.log(type: .LOG_ROOM_TITLE, text: title)
            
            let config: SocketIOClientConfiguration = [.log(true), .reconnectAttempts(5), .reconnectWait(1)]
            self.socket = SocketIOClient(socketURL: URL(string: "https://livecmt-1.bilibili.com")!.appendingPathComponent(String(roomId)), config: config)
            
            let socket = self.socket!
            socket.on("connect") {
                data, ack in
                debugPrint(data, ack)
            }
            
            socket.connect()
        }
    }
    
    private func getRoomBasicInfo(liveId: String, completionHandler: @escaping (String, String, Bool) -> Void) {
        let url = "https://live.bilibili.com"
        // fetch html
        Alamofire.request(URL(string: url)!.appendingPathComponent(liveId)).responseString{ response in
            var error = false
            var roomId = ""
            var title = ""
            if let html = response.value {
                while true {
                    // search for room id in html
                    let regexRoomId = try! NSRegularExpression(pattern: "var\\s+roomid\\s+=\\s*(\\d+);", options: .caseInsensitive)
                    let mRooms = regexRoomId.matches(in: html, options: [], range: NSRange(location: 0, length: html.characters.count))
                    if mRooms.count > 0 {
                        let mRoomRange = mRooms[0].rangeAt(1)
                        let l = html.index(html.startIndex, offsetBy: mRoomRange.location)
                        let r = html.index(l, offsetBy: mRoomRange.length)
                        let str = html.substring(with: l..<r)
                        debugPrint(str)
                        roomId = str
                    } else {
                        error = true
                        break
                    }
                    // search for title in html
                    let regexTitle = try! NSRegularExpression(pattern: "<title>(.*)</title>", options: .caseInsensitive)
                    let mTitles = regexTitle.matches(in: html, options: [], range: NSRange(location: 0, length: html.characters.count))
                    if mTitles.count > 0 {
                        let mTitleRange = mTitles[0].rangeAt(1)
                        let l = html.index(html.startIndex, offsetBy: mTitleRange.location)
                        let r = html.index(l, offsetBy: mTitleRange.length)
                        let str = html.substring(with: l..<r)
                        debugPrint(str)
                        title = str
                    } else {
                        error = true
                    }
                    break
                }
            }
            completionHandler(roomId, title, error)
        }
    }
}
