//
//  ViewController.swift
//  ConvolutionExplorer
//
//  Created by Simon Gladman on 18/05/2015.
//  Copyright (c) 2015 Simon Gladman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let mainGroup = SLVGroup()
    let workspace = SLHGroup()
    let imageView = UIImageView()
    let kernelEditor = KernelEditor(kernel: [Int](repeating: 0, count: 49))
    let valueSlider = UISlider()
    
    let toolbar = SLHGroup()
    let leftToolbar = SLVGroup()
    let rightToolbar = SLVGroup()
    let leftToolbarButtonGroup = SLHGroup()
    
    let clearSelectionButton = borderedButton("Clear Selection")
    let selectAllButton = borderedButton("Select All")
    let invertSelectionButton = borderedButton("Invert Selection")
    let zeroSelectionButton = borderedButton("Zero Selection")
    
    let divisorSegmentedControl = UISegmentedControl(items: ["1", "2", "4", "8", "16", "32"])
    let kernelSizeSegmentedControl = UISegmentedControl(items: KernelSize.allCases.map({ $0.rawValue }))
    
    let image = UIImage(named: "image.jpg")
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        imageView.contentMode = .scaleAspectFit
        
        valueSlider.minimumValue = -20
        valueSlider.maximumValue = 20
        valueSlider.isEnabled = false
        
        kernelEditor.kernel[17] = -1
        kernelEditor.kernel[23] = -1
        kernelEditor.kernel[24] = 7
        kernelEditor.kernel[25] = -1
        kernelEditor.kernel[31] = -1
        
        kernelSizeSegmentedControl.selectedSegmentIndex = 0
        divisorSegmentedControl.selectedSegmentIndex = 2

        createLayout()
        createControlEvenHandlers()
        selectionChanged()
        kernelSizeChange()
    }
    
    func createLayout()
    {
        workspace.children = [kernelEditor, imageView]
        
        leftToolbarButtonGroup.margin = 5
        leftToolbarButtonGroup.children = [clearSelectionButton, selectAllButton, invertSelectionButton, zeroSelectionButton]
        
        leftToolbar.children = [leftToolbarButtonGroup, valueSlider]
        leftToolbar.margin = 2
        
        rightToolbar.children = [kernelSizeSegmentedControl, divisorSegmentedControl]
        rightToolbar.margin = 2
        
        toolbar.children = [leftToolbar, rightToolbar]
        toolbar.explicitSize = 84
        
        mainGroup.children = [workspace, toolbar]
        
        view.addSubview(mainGroup)
    }
    
    func createControlEvenHandlers()
    {
        valueSlider.addTarget(self, action: #selector(sliderChange), for: .valueChanged)
        
        divisorSegmentedControl.addTarget(self, action: #selector(divisorChanged), for: .valueChanged)
        kernelSizeSegmentedControl.addTarget(self, action: #selector(kernelSizeChange), for: .valueChanged)
        kernelEditor.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
        
        clearSelectionButton.addTarget(self, action: #selector(clearSelection), for: .touchDown)
        selectAllButton.addTarget(self, action: #selector(selectAllCells), for: .touchDown)
        invertSelectionButton.addTarget(self, action: #selector(invertSelection), for: .touchDown)
        zeroSelectionButton.addTarget(self, action: #selector(setSelectedToZero), for: .touchDown)
    }
 

    func applyKernel()
    {
        var kernel = [Int16]()
        //let size: Int = kernelEditor.kernelSize == .ThreeByThree ? 3 : kernelEditor.kernelSize == .FiveByFive ? 5 : 7
        
        for (idx, cell) in kernelEditor.kernel.enumerated()
        {
            let row = Int(idx / 7)
            let column = idx % 7

            switch kernelEditor.kernelSize
            {
            case .ThreeByThree:
                if row >= 2 && row <= 4 && column >= 2 && column <= 4
                {
                    kernel.append(Int16(cell))
                }
            case .FiveByFive:
                if row >= 1 && row <= 5 && column >= 1 && column <= 5
                {
                    kernel.append(Int16(cell))
                }
            case .SevenBySeven:
                kernel.append(Int16(cell))
            }
        }
        
        let divisor = Int(pow(2, Float(divisorSegmentedControl.selectedSegmentIndex)))
        
        imageView.image = applyConvolutionFilterToImage(image!, kernel: kernel, divisor: divisor)
    }
    
    @objc
    func sliderChange()
    {
        let newValue = Int(valueSlider.value)
        
        kernelEditor.selectedCellIndexes.forEach({ self.kernelEditor.kernel[$0] = newValue })
        
        applyKernel()
    }
    
    @objc
    func setSelectedToZero()
    {
        kernelEditor.selectedCellIndexes.forEach({ self.kernelEditor.kernel[$0] = 0 })
        
        selectionChanged()
        applyKernel()
    }
    
    @objc
    func clearSelection()
    {
        kernelEditor.cells.forEach({ $0.selected = false })
        selectionChanged()
    }
    
    @objc
    func selectAllCells()
    {
        kernelEditor.cells.forEach({ $0.selected = true })
        selectionChanged()
    }
    
    @objc
    func invertSelection()
    {
        kernelEditor.cells.forEach({ $0.selected = !$0.selected })
        selectionChanged()
    }
    
    @objc
    func selectionChanged()
    {
        let cellsSelected = kernelEditor.selectedCellIndexes.count != 0
        
        valueSlider.isEnabled = cellsSelected
        clearSelectionButton.isEnabled = cellsSelected
        invertSelectionButton.isEnabled = cellsSelected
        zeroSelectionButton.isEnabled = cellsSelected
        
        if cellsSelected
        {
            let selectionAverage = kernelEditor.selectedCellIndexes.reduce(0, { $0 + kernelEditor.kernel[$1] }) / kernelEditor.selectedCellIndexes.count
            
            valueSlider.value = Float(selectionAverage)
        }
    }
    
    @objc
    func divisorChanged()
    {
        applyKernel()
    }
    
    @objc
    func kernelSizeChange()
    {
        if let kernelSize = KernelSize(rawValue: kernelSizeSegmentedControl.titleForSegment(at: kernelSizeSegmentedControl.selectedSegmentIndex)!)
        {
            kernelEditor.kernelSize = kernelSize
            applyKernel()
        }
    }

    override func viewDidLayoutSubviews()
    {
        let top = topLayoutGuide.length
        let bottom = bottomLayoutGuide.length
        
        mainGroup.frame = CGRect(x: 0, y: top, width: view.frame.width, height: view.frame.height - top - bottom).insetBy(dx: 5, dy: 5)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    class func borderedButton(_ text: String) -> SLButton
    {
        let button = SLButton()
        button.setTitle(text, for: .normal)
        
        button.setTitleColor(.blue, for: .normal)
        button.setTitleColor(.lightGray, for: .disabled)
        
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        
        button.layer.cornerRadius = 3
        button.layer.borderColor = UIColor.blue.cgColor
        button.layer.borderWidth = 1
        
        return button
    }
    
}


