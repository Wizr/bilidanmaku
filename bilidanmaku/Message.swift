//
//  Message.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 06/03/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

// message for passing to delegate
struct Message {
    // message type for communicating with outside
    enum MsgType {
        case MSG_ERROR(String)
        case MSG_ROOM_ID(String)
        case MSG_ROOM_TITLE(String)
        case MSG_DANMU_MSG(String)
        case MSG_GIFT(String)
        case MSG_USER_NUM(Int)
        case MSG_UNKNOWN_JSON_MSG(String)
        case MSG_WELCOME
        case MSG_ENTER_ROOM
    }
    // vip level
    enum VipLevel {
        case VIP_NONE
        case VIP_VIP
        case VIP_SVIP
    }
    
    // message type
    var type: MsgType
    // user info
    var uname: String = ""
    var isadmin: Bool = false
    var vip: VipLevel = .VIP_NONE
    // gift info
    var num: Int = 1
    
    // other
    init(type: MsgType) {
        self.type = type
    }
    
    // gift
    init(type: MsgType, uname: String, num: Int) {
        self.type = type
        self.uname = uname
        self.num = num
    }
    
    // danmu message
    init(type: MsgType, uname: String, isadmin: Int, isvip: Int, issvip: Int) {
        self.type = type
        self.uname = uname
        
        if isadmin == 1 {
            self.isadmin = true
        }
        
        if isvip == 1 {
            self.vip = .VIP_VIP
        } else if issvip == 1 {
            self.vip = .VIP_SVIP
        }
    }
}
