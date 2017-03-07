//
//  DanmakuProtocol.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 02/03/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Cocoa

protocol DanmakuProtocol: NSObjectProtocol {
//    func OnGetRoomBasicInfo(roomId: String, title: String, hasError: Bool)
    func handleMsg(msg: Message)
}
