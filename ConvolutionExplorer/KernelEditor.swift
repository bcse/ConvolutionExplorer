//
//  KernelEditor.swift
//  ConvolutionExplorer
//
//  Created by Simon Gladman on 18/05/2015.
//  Copyright (c) 2015 Simon Gladman. All rights reserved.
//

import UIKit

class KernelEditor: UIControl
{
    let mainGroup = SLVGroup()
    let topSpacer = SLSpacer(percentageSize: nil, explicitSize: nil)
    let bottomSpacer = SLSpacer(percentageSize: nil, explicitSize: nil)
    
    var cells = [KernelEditorCell]()
    
    required init(kernel: [Int])
    {
        self.kernel = kernel
        
        super.init(frame: .zero)

        mainGroup.children.append(topSpacer)
        mainGroup.margin = 7
        
        for i in 0 ... 6
        {
            let row = KernelEditorRow(rowNumber: i, kernelEditor: self)
            mainGroup.children.append(row)
        }
        
        mainGroup.children.append(topSpacer)
        
        addSubview(mainGroup)
        
        updateCellsFromKernel()
    }

    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    
    var kernel: [Int]
    {
        didSet
        {
            updateCellsFromKernel()
        }
    }
    
    func updateCellsFromKernel()
    {
        for (value, cell) in zip(kernel, cells)
        {
            cell.text = "\(value)"
        }
    }
    
    var kernelSize: KernelSize = .ThreeByThree
    {
        didSet
        {
            for cell in cells
            {
                switch kernelSize
                {
                case .ThreeByThree:
                    cell.isEnabled = cell.rowNumber >= 2 && cell.rowNumber <= 4 && cell.columnNumber >= 2 && cell.columnNumber <= 4
                case .FiveByFive:
                    cell.isEnabled = cell.rowNumber >= 1 && cell.rowNumber <= 5 && cell.columnNumber >= 1 && cell.columnNumber <= 5
                case .SevenBySeven:
                    cell.isEnabled = true
                }
            }
        }
    }
    
    var touchedCells = [KernelEditorCell]()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        touchedCells = [KernelEditorCell]()
        
        if let touch = touches.first
        {
            let obj = (hitTest(touch.location(in: self), with: event))
            
            if let obj = obj as? KernelEditorCell, obj.isEnabled
            {
                obj.selected = !obj.selected
                touchedCells.append(obj)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesMoved(touches, with: event)
        
        if let touch = touches.first
        {
            let obj = (hitTest(touch.location(in: self), with: event))
            
            if let obj = obj as? KernelEditorCell, obj.isEnabled && touchedCells.firstIndex(of: obj) == nil
            {
                obj.selected = !obj.selected
                touchedCells.append(obj)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesEnded(touches, with: event)
        
        sendActions(for: .valueChanged)
    }
    
    var selectedCellIndexes: [Int]
    {
        return cells.filter({ $0.selected }).map({ $0.index })
    }
    
    override func layoutSubviews()
    {
        topSpacer.explicitSize = frame.width / 4
        bottomSpacer.explicitSize = frame.width / 4
        mainGroup.frame = frame
    }
}

// MARK: KernelEditorRow

class KernelEditorRow: SLHGroup
{
    var kernelEditor: KernelEditor
    
    required init(rowNumber: Int, kernelEditor: KernelEditor)
    {
        self.kernelEditor = kernelEditor
        
        super.init()
        
        margin = 7
        
        for i in 0 ... 6
        {
            let cell = KernelEditorCell(rowNumber: rowNumber, columnNumber: i, kernelEditor: kernelEditor)
            children.append(cell)
        }
    }
    
    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    required init()
    {
        fatalError("init() has not been implemented")
    }
}

// MARK: KernelEditorCell

class KernelEditorCell: SLLabel
{
    var kernelEditor: KernelEditor
    var rowNumber: Int
    var columnNumber: Int
    
    required init(rowNumber: Int, columnNumber: Int, kernelEditor: KernelEditor)
    {
        self.kernelEditor = kernelEditor
        self.rowNumber = rowNumber
        self.columnNumber = columnNumber
        
        super.init(frame: .zero)
     
        isUserInteractionEnabled = true
        
        textAlignment = .center

        layer.backgroundColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 3
        
        kernelEditor.cells.append(self)
    }
    
    var index: Int
    {
        return (rowNumber * 7) + columnNumber
    }
    
    var selected: Bool = false
    {
        didSet
        {
            setColors()
        }
    }
    
    override var isEnabled: Bool
    {
        didSet
        {
            setColors()
        }
    }
    
    func setColors()
    {
        layer.backgroundColor = selected && isEnabled ? UIColor.blue.cgColor : UIColor.lightGray.cgColor
        textColor = selected && isEnabled ? .white : .black
        alpha = isEnabled ? 1 : 0.5
    }
    
    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

enum KernelSize: String, CaseIterable
{
    case ThreeByThree = "3 x 3"
    case FiveByFive = "5 x 5"
    case SevenBySeven = "7 x 7"
}
