//
//  ConfigManager.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 10/03/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Foundation

class ConfigManager {
    struct DanmakuScene {
        var showTime: Int = 7
        var width: Double = 250
        var marginInnerH: Double = 3
        var marginInnerV: Double = 0.5
        var marginTextH: Double = 3
        var marginTextV: Double = 5
        var textWidth: Double {
            return width - marginInnerH * 2 - marginTextH * 2
        }
        
        func innerHeight(textHeight: Double) -> Double {
            return textHeight + marginTextV * 2
        }
        
        func innerWidth() -> Double {
            return width - marginInnerH * 2
        }
        
        func itemHeight(textHeight: Double) -> Double {
            return innerHeight(textHeight: textHeight) + marginInnerV * 2
        }
        
        func itemWidth() -> Double {
            return width
        }
    }
    
    static let shared = ConfigManager()
    
    public var danmakuScene = DanmakuScene()
    private init() {}
}
