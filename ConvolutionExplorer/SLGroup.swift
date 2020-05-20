//
//  SLGroup.swift
//  ShinpuruLayout
//
//  Created by Simon Gladman on 02/05/2015.
//  Copyright (c) 2015 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

import UIKit


/// Horizontal Group
public class SLHGroup: SLGroup
{
    override public func layoutSubviews()
    {
        super.layoutSubviews()

        let childMetrics = SLGroup.calculateChildMetrics(children: children, childPercentageSizes: childPercentageSizes, availableSize: frame.width, totalExplicitSize: totalExplicitSize)
   
        for (child, metrics) in zip(children, childMetrics)
        {
            child.frame = CGRect(x: metrics.origin, y: 0, width: metrics.size, height: self.frame.height).insetBy(dx: self.margin / 2, dy: 0)
        }
    }
}


/// Vertical Group
public class SLVGroup: SLGroup
{
    override public func layoutSubviews()
    {
        super.layoutSubviews()
        
        let childMetrics = SLGroup.calculateChildMetrics(children: children, childPercentageSizes: childPercentageSizes, availableSize: frame.height, totalExplicitSize: totalExplicitSize)
        
        for (child, metrics) in zip(children, childMetrics)
        {
            child.frame = CGRect(x: 0, y: metrics.origin, width: self.frame.width, height: metrics.size).insetBy(dx: 0, dy: self.margin / 2)
        }
    }
}

/// Base Class
public class SLGroup: UIView, SLLayoutItem
{
    public var percentageSize: CGFloat?
    public var explicitSize: CGFloat?
    
    internal var childPercentageSizes = [CGFloat]()
    internal var totalExplicitSize: CGFloat = 0
    
    typealias LayoutMetrics = (childPercentageSizes: [CGFloat], totalExplicitSize: CGFloat)
    typealias ChildMetric = (origin: CGFloat, size: CGFloat)
    
    public required init ()
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func addSubview(_ view: UIView)
    {
        children.append(view)
    }
    
    var children: [UIView] = [UIView]()
    {
        didSet
        {
            oldValue.forEach { $0.removeFromSuperview() }

            setNeedsLayout()
        }
    }
    
    override public func layoutSubviews()
    {
        children.forEach { super.addSubview($0) }
        
        let layoutMetrics = SLGroup.calculateLayoutMetrics(children)
        
        totalExplicitSize = layoutMetrics.totalExplicitSize
        childPercentageSizes = layoutMetrics.childPercentageSizes
        
        if newChild != nil
        {
            Timer.scheduledTimer(timeInterval: 1 / 60, target: self, selector: #selector(addStep), userInfo: nil, repeats: false)
            
        }
        else if removeChildIndex != nil
        {
            Timer.scheduledTimer(timeInterval: 1 / 60, target: self, selector: #selector(removeStep), userInfo: nil, repeats: false)
        }
        else
        {
            getNextAnimation()
        }
    }
    
    var margin: CGFloat = 1
    {
        didSet
        {
            setNeedsLayout()
        }
    }
    
    /// Returns a LayoutMetrics instance containing the percemtage sizes for each child and the total of the
    /// explicit sizes.
    class func calculateLayoutMetrics(_ children: [UIView]) -> LayoutMetrics
    {
        let totalExplicitSize = children.filter({ self.hasExplicitSize($0) }).reduce(CGFloat(0), {$0 + ($1 as! SLLayoutItem).explicitSize!})
        
        let totalPercentages = children.filter({ self.hasPercentage($0) }).reduce(CGFloat(0), {$0 + ($1 as! SLLayoutItem).percentageSize!})
        
        let defaultComponentPercentage = (CGFloat(100) - totalPercentages) / CGFloat(children.filter({ !self.hasPercentage($0) && !self.hasExplicitSize($0) }).count)
        
        let childPercentageSizes = children.map({ self.hasPercentage($0) ? ($0 as! SLLayoutItem).percentageSize! : defaultComponentPercentage })
        
        return (childPercentageSizes, totalExplicitSize)
    }
    
    
    
    /// Returns an array of ChildMetric instances that define absolute position and width
    /// to fit within totalExplicitSize
    class func calculateChildMetrics(children: [UIView], childPercentageSizes: [CGFloat], availableSize: CGFloat, totalExplicitSize: CGFloat) -> [ChildMetric]
    {
        var currentOrigin: CGFloat = 0

        let returnArray = zip(children, childPercentageSizes).map
        { (child, childPercentage) -> ChildMetric in
            let percentageWidth = childPercentage / 100 * (availableSize - totalExplicitSize)
            let componentWidth: CGFloat = SLGroup.hasExplicitSize(child) ? (child as! SLLayoutItem).explicitSize! : percentageWidth
            let previous = currentOrigin
            currentOrigin += componentWidth
            
            return ChildMetric(origin: previous, size: componentWidth)
        }
        
        return returnArray
    }
    
    class func hasExplicitSize(_ value: UIView) -> Bool
    {
        return (value as? SLLayoutItem)?.explicitSize != nil && !hasPercentage(value)
    }
    
    class func hasPercentage(_ value: UIView) -> Bool
    {
        return (value as? SLLayoutItem)?.percentageSize != nil
    }

    // MARK: Animated add and remove....
    
    typealias SLGroupAnimationQueueItem = (type: SLAnimationType, index: Int, child: UIView?)
    
    private var animationQueueItems = [SLGroupAnimationQueueItem]()
    
    private let transientChildSpacer = SLSpacer(percentageSize: nil, explicitSize: 0)
    private let animationSteps = CGFloat(10)
    private let fadeDuration = 0.25
    
    private var newChildIndex: Int?
    private var newChild: UIView?
    private var newChildExplicitSize: CGFloat?
    
    private var removeChildIndex: Int?

    private var sizeStep: CGFloat?
    private var animationRunning: Bool = false
    
    func getNextAnimation()
    {
        if let nextAnim = animationQueueItems.first
        {
            nextAnim.type == .Add
                ? addChild(nextAnim.child!, atIndex: nextAnim.index)
                : removeChild(at: nextAnim.index)
            
            animationQueueItems.remove(at: 0)
        }
    }
    
    func removeChild(at index: Int)
    {
        if animationRunning
        {
            animationQueueItems.append( SLGroupAnimationQueueItem(.Remove, index, nil) )
            return
        }
        else if index >= children.count
        {
            return
        }
      
        animationRunning = true
        
        let availableSize = self is SLHGroup ? frame.width : frame.height
        
        let layoutMetrics = SLGroup.calculateLayoutMetrics(children)
        let childMetrics = SLGroup.calculateChildMetrics(children: children, childPercentageSizes: layoutMetrics.childPercentageSizes, availableSize: availableSize, totalExplicitSize: layoutMetrics.totalExplicitSize)
        
        transientChildSpacer.explicitSize = childMetrics[index].size
        removeChildIndex = index
        
        sizeStep = transientChildSpacer.explicitSize! / animationSteps
        
        UIView.animate(withDuration: fadeDuration, delay: 0, options: .curveEaseInOut, animations: { self.children[index].alpha = 0
        }) { _ in
            self.children[index] = self.transientChildSpacer
            self.removeStep()
        }
    }
    
    func addChild(_ child: UIView, atIndex: Int)
    {
        if animationRunning
        {
            if animationQueueItems.filter({ $0.child == child }).count == 0
            {
                animationQueueItems.append( SLGroupAnimationQueueItem(.Add, atIndex, child) )
            }
            return
        }
        
        animationRunning = true
        
        let targetIndex = min(children.count, atIndex)
        
        transientChildSpacer.explicitSize = 0
        children.insert(transientChildSpacer, at: targetIndex)
        newChildIndex = targetIndex
        newChild = child
        newChild?.alpha = 0
        
        let availableSize = self is SLHGroup ? frame.width : frame.height
 
        var candidateChildren = children
        candidateChildren.insert(child, at: targetIndex)
        let layoutMetrics = SLGroup.calculateLayoutMetrics(candidateChildren)
        let childMetrics = SLGroup.calculateChildMetrics(children: candidateChildren, childPercentageSizes: layoutMetrics.childPercentageSizes, availableSize: availableSize, totalExplicitSize: layoutMetrics.totalExplicitSize)
 
        newChildExplicitSize = childMetrics[targetIndex].size
        sizeStep = newChildExplicitSize! / animationSteps
        
        addStep()
    }
    
    @objc
    func removeStep()
    {
        if let removeChildIndex = removeChildIndex
        {
            children.remove(at: removeChildIndex)
            
            self.removeChildIndex = nil
            animationRunning = false
        }
        else if let explicitSize = transientChildSpacer.explicitSize, explicitSize > 0, let sizeStep = sizeStep
        {
            transientChildSpacer.explicitSize = max(explicitSize - sizeStep, 0)
        }
        
        setNeedsLayout()
    }
    
    @objc
    func addStep()
    {
        if let newChild = newChild
        {
            children[newChildIndex!] = newChild
            
            UIView.animate(withDuration: fadeDuration, delay: 0, options: .curveEaseInOut, animations: {
                newChild.alpha = 1
            })
            
            animationRunning = false
            self.newChild = nil
        }
        else if let explicitSize = transientChildSpacer.explicitSize, let newChildExplicitSize = newChildExplicitSize, explicitSize < newChildExplicitSize, let sizeStep = sizeStep
        {
            transientChildSpacer.explicitSize = min(explicitSize + sizeStep, newChildExplicitSize)
        }
        
        setNeedsLayout()
    }
    
}

enum SLAnimationType
{
    case Add
    case Remove
}
