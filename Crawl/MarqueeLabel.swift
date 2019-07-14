//
//  MarqueeLabel.swift
//  Crawl
//
//  Created by Justin Kaufman on 3/23/17.
//  Copyright © 2017 Justin Kaufman. All rights reserved.
//

import Foundation
import Cocoa
import QuartzCore

protocol MarqueeLabelDelegate: NSObjectProtocol {
    func didStartScrolling()
    func didFinishScrolling(_ string: String)
}

extension MarqueeLabelDelegate {
    func didStartScrolling() {}
}

class MarqueeLabel: NSTextField, CAAnimationDelegate {
    weak var scrollDelegate: MarqueeLabelDelegate?

    var rootLayer: CALayer?
    var firstLayer: CATextLayer?
    var secondLayer: CATextLayer?
    var maskLayer: CAGradientLayer?

    var currentStringValue: String = ""

    @IBInspectable var scrollingRate: CGFloat = 90.0
    @IBInspectable var scrollingOffset: CGFloat = 10.0
    var stringWidth: CGFloat = 0.0
    var resetFlag: Bool = false
    var isScrolling: Bool = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        wantsLayer = true
        
        scrollingRate = 90.0
        scrollingOffset = 10.0
       
        rootLayer = CALayer()
        rootLayer?.frame = bounds
        
        maskLayer = CAGradientLayer()
        maskLayer?.frame = bounds
        maskLayer?.colors = [(NSColor.clear.cgColor), (NSColor.white.cgColor), (NSColor.white.cgColor), (NSColor.clear.cgColor)]
        maskLayer?.locations = [(0.0), (0.05), (0.95), (1.0)]
        maskLayer?.startPoint = CGPoint(x: CGFloat(0), y: CGFloat(1))
        maskLayer?.endPoint = CGPoint(x: CGFloat(1), y: CGFloat(1))
        rootLayer?.mask = maskLayer
        
        firstLayer = CATextLayer()
        firstLayer?.string = stringValue
        firstLayer?.fontSize = font!.pointSize
        firstLayer?.font = (font as CFTypeRef)
        firstLayer?.frame = bounds
        firstLayer?.alignmentMode = CATextLayerAlignmentMode.center
        firstLayer?.foregroundColor = textColor!.cgColor
    
        secondLayer = CATextLayer()
        secondLayer?.string = ""
        secondLayer?.fontSize = font!.pointSize
        secondLayer?.font = (font as CFTypeRef)
        secondLayer?.frame = bounds
        secondLayer?.alignmentMode = CATextLayerAlignmentMode.center
        secondLayer?.foregroundColor = textColor!.cgColor
        secondLayer?.isHidden = true
        
        rootLayer?.addSublayer(firstLayer!)
        rootLayer?.addSublayer(secondLayer!)
        
        layer = rootLayer
        
        updateLayerFrames()
    }

    override var bounds: NSRect {
        didSet {
            guard isScrolling else {
                maskLayer?.frame = self.bounds
                return
            }

            firstLayer?.frame = self.bounds
            secondLayer?.frame = self.bounds
        }
    }
    
    override var frame: NSRect {
        didSet {
            guard isScrolling else {
                maskLayer?.frame = bounds
                return
            }

            firstLayer?.frame = bounds
            secondLayer?.frame = bounds
        }
    }

    func boundingWidth(for attributedString: NSAttributedString) -> CGFloat {
        let setter: CTFramesetter = CTFramesetterCreateWithAttributedString(attributedString as! CFMutableAttributedString)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            setter,
            CFRangeMake(0, 0),
            nil,
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            nil
        )
        
        return size.width
    }
    
    override var stringValue: String {
        didSet {
            guard currentStringValue != stringValue else { return }
            currentStringValue = stringValue
            firstLayer?.string = stringValue
            secondLayer?.string = ""
            updateLayerFramesWithoutScrolling()
        }
    }
    
    func setScrollRate(_ scrollRate: CGFloat) {
        scrollingRate = scrollRate
        updateLayerFrames()
    }
    
    func setScrollOffset(_ scrollOffset: CGFloat) {
        scrollingOffset = scrollOffset
        updateLayerFrames()
    }
    
    func updateLayerFramesWithoutScrolling() {
        stringWidth = boundingWidth(for: attributedStringValue)
        maskLayer?.locations = [0.0, 0.0, 0.95, 1.0]
        secondLayer?.isHidden = true
        firstLayer?.removeAllAnimations()
        secondLayer?.removeAllAnimations()
        
        CATransaction.begin()
        CATransaction.setValue((kCFBooleanTrue as Any), forKey: kCATransactionDisableActions)

        var firstBounds: NSRect = bounds
        var secondBounds: NSRect = bounds
        firstBounds.size.width = stringWidth
        secondBounds.origin.x = stringWidth + scrollingOffset
        secondBounds.size.width = stringWidth
        firstLayer?.frame = firstBounds
        secondLayer?.frame = secondBounds
        
        CATransaction.commit()
    }
    
    func updateLayerFrames() {
        stringWidth = boundingWidth(for: attributedStringValue)
        maskLayer?.locations = [0.0, 0.0, 0.95, 1.0]
        firstLayer?.isHidden = true
        firstLayer?.removeAllAnimations()
        secondLayer?.removeAllAnimations()

        CATransaction.begin()
        CATransaction.setValue((kCFBooleanTrue as Any), forKey: kCATransactionDisableActions)

        var firstBounds: NSRect = bounds
        var secondBounds: NSRect = bounds

        firstBounds.size.width = stringWidth
        secondBounds.origin.x = stringWidth + scrollingOffset
        secondBounds.size.width = stringWidth
        firstLayer?.frame = firstBounds
        secondLayer?.frame = secondBounds

        CATransaction.commit()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
            execute: { [weak self] in
                guard let self = self else { return }
                self.firstLayer?.isHidden = false

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1.125,
                    execute: { [weak self] in self?.scrollTextField() }
                )
            }
        )
    }

    func scrollTextField() {
        maskLayer?.locations = [(0.0), (0.05), (0.95), (1.0)]
        isScrolling = true
        
        let animationDuration: CGFloat = (stringWidth + scrollingOffset) / scrollingRate

        let firstAnimation = CABasicAnimation(keyPath: "position")
        firstAnimation.fromValue = NSValue(point: (firstLayer?.position)!)
        firstAnimation.toValue = NSValue(point: NSMakePoint((firstLayer?.position.x)! - stringWidth - scrollingOffset, (firstLayer?.position.y)!))
        firstAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        firstAnimation.duration = CFTimeInterval(animationDuration)
        firstLayer?.add(firstAnimation, forKey: "frameAnimation")
        
        let secondAnimation = CABasicAnimation(keyPath: "position")
        secondAnimation.delegate = self
        secondAnimation.setValue(secondLayer, forKey: "targetLayer")
        secondAnimation.fromValue = NSValue(point: (secondLayer?.position)!)
        secondAnimation.toValue = NSValue(point: NSMakePoint((secondLayer?.position.x)! - stringWidth - scrollingOffset, (secondLayer?.position.y)!))
        secondAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        secondAnimation.duration = CFTimeInterval(animationDuration)
        secondLayer?.add(secondAnimation, forKey: "frameAnimation")
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        scrollDelegate?.didStartScrolling()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if ((anim.value(forKey: "targetLayer") as! CALayer) == secondLayer) && flag {
            isScrolling = false
            scrollDelegate?.didFinishScrolling(stringValue)
            updateLayerFrames()
        }
    }
    
    override func viewDidChangeBackingProperties() {
        if let backingScale = window?.backingScaleFactor {
            if backingScale > CGFloat(0.0) {
                for layer: CALayer in (rootLayer?.sublayers!)! {
                    layer.contentsScale = backingScale
                }
            }
        }
    }
}
