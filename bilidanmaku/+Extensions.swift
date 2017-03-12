//
//  +Extensions.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 10/03/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Foundation

extension CGFloat {
    func toDouble() -> Double {
        return Double(self)
    }
}

extension Double {
    func toCGFloat() -> CGFloat {
        return CGFloat(self)
    }
}

extension Data {
    func toInt32() -> Int32 {
        return self.withUnsafeBytes { (t: UnsafePointer<Int32>) in t.pointee }
    }
}
