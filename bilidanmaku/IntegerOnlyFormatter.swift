//
//  LiveIdTextFieldDelegate.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 02/03/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Cocoa

class IntegerOnlyFormatter: NumberFormatter {
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if partialString.characters.count == 0 {
            return true
        }
        if partialString.characters.count > 9 {
            return false
        }
        let scanner = Scanner(string: partialString)
        if !(scanner.scanInt(nil) && scanner.isAtEnd) {
            return false
        }
        return true
    }
}
