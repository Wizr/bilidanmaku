//
//  DanmakuViewController.swift
//  bilidanmaku
//
//  Created by Xudong Yang on 07/03/2017.
//  Copyright © 2017 Xudong Yang. All rights reserved.
//

import Cocoa

class DanmakuViewController: NSViewController, CAAnimationDelegate {
    private var sema: DispatchSemaphore?
    private var dispatchQueue: DispatchQueue?
    private let width: Double = 250
    private var rootLayer: CALayer {
        return self.view.layer!
    }
    private var l: CALayer?
    private var height: CGFloat = 0
    
    public func initialize() {
        let layer = CALayer()
        self.view.layer = layer
        self.view.wantsLayer = true
        
        layer.isGeometryFlipped = true
        
        let l = CALayer()
        layer.addSublayer(l)
        l.frame.origin.y = layer.frame.size.height
        self.l = l
        
        
        self.dispatchQueue = DispatchQueue(label: "danmakuScene")
        self.sema = DispatchSemaphore(value: 1)
    }
    
    // to remove
    private func heightFor(string: NSAttributedString, width: Int, font: NSFont) -> CGFloat {
        let textStorage = NSTextStorage(attributedString: string)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: NSSize(width: 250, height: Int.max))
        
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        layoutManager.glyphRange(for: textContainer)
        return layoutManager.usedRect(for: textContainer).size.height
    }
    
    public func appendDanmakuItem(string: NSAttributedString) {
        DispatchQueue.global().async {
            self.dispatchQueue?.sync() {
                debugPrint("waiting....")
                self.sema?.wait()
                debugPrint("running.....")
                DispatchQueue.main.sync {
                    debugPrint("doing.....")
                    self.doAppendDanmakuItem(string: string)
                }
            }
        }
    }
    
    @objc public func doAppendDanmakuItem(string: NSAttributedString) {
//        self.sema?.wait()
        debugPrint("NSRunLoop")
        let layer = DanmakuItem(string: string, showTime: 3)
        let height = layer.frame.size.height
        layer.frame.origin.y = self.height // rootLayer.frame.size.height - self.l!.frame.origin.y

        debugPrint(self.l!.frame)
        self.l?.addSublayer(layer)
        debugPrint(self.l!.frame)
        debugPrint(layer.frame)
        CATransaction.begin()
        CATransaction.setCompletionBlock {
//            debugPrint("end", self.l!.presentation()!.frame)
//            self.sema?.signal()
        }
        
        let anim = CABasicAnimation(keyPath: "position.y")
        anim.duration = 1
        anim.byValue = -height
        anim.isRemovedOnCompletion = false
        anim.fillMode = kCAFillModeForwards
        
        self.l?.add(anim, forKey: nil)
//        rootLayer.sublayers?.forEach {
//            layer in
//            layer.add(anim, forKey: nil)
//        }
        CATransaction.commit()
        self.height += height
        self.sema?.signal()

//        rootLayer.setNeedsDisplay()
//        rootLayer.setNeedsLayout()
    }
}

class DanmakuItem: CALayer {
    init(string: NSAttributedString, showTime: Int) {
        super.init()
        createSubLayer(string: string)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createSubLayer(string: NSAttributedString) {
        let ds = ConfigManager.shared.danmakuScene
        
        // create text layer
        let caText = CATextLayer()
        caText.string = string
        caText.isWrapped = true
        caText.contentsScale = 2
        
        // determine height for text layer
        let height = self.heightFor(string: string, withTextLayer: caText).toDouble()
        caText.frame = NSRect(x: ds.marginTextH, y: ds.marginTextV, width: ds.textWidth, height: height)
        
        // create inner(background) layer
        let caInner = CALayer()
        caInner.frame = NSRect(x: ds.marginInnerH, y: ds.marginInnerV, width: ds.innerWidth(), height: ds.innerHeight(textHeight: height))
        caInner.backgroundColor = CGColor(gray: 0, alpha: 0.5)
        caInner.cornerRadius = min(ds.marginTextH, ds.marginTextV).toCGFloat()
        
        // create wrapper layer
        self.frame = NSRect(x: 0, y: 0, width: ds.itemWidth(), height: ds.itemHeight(textHeight: height))
        
        caInner.addSublayer(caText)
        self.addSublayer(caInner)
    }
    
    private func heightFor(string: NSAttributedString, withTextLayer textLayer: CATextLayer) -> CGFloat {
        let ds = ConfigManager.shared.danmakuScene
        let typeSetter = CTTypesetterCreateWithAttributedString(string)
        
        var offset: Int = 0, length: Int
        var y: CGFloat = 0
        repeat {
            length = CTTypesetterSuggestLineBreak(typeSetter, offset, ds.textWidth)
            let line = CTTypesetterCreateLine(typeSetter, CFRange(location: offset, length: length))
            
            var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            offset += length
            y += ascent + descent + leading
        } while offset < string.length
        
        return y
    }
}
