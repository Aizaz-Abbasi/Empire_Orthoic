//
//  CustomTabBar.swift
//  EmpireScan
//
//  Created by MacOK on 20/03/2025.
//

import UIKit

class CustomTabBar: UITabBar {
    
    private let centerButton = UIButton(type: .custom)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCenterButton()
    }
    
    private func setupCenterButton() {
        centerButton.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerButton.backgroundColor = UIColor(red: 177/255, green: 57/255, blue: 55/255, alpha: 1) // Red Color
        centerButton.layer.cornerRadius = 30
        centerButton.layer.masksToBounds = true
        centerButton.setImage(UIImage(systemName: "plus"), for: .normal)
        centerButton.tintColor = .white
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        
        addSubview(centerButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let screenWidth = UIScreen.main.bounds.width
        let tabBarHeight: CGFloat = 50
        let buttonSize: CGFloat = 60
        let buttonY = -20
        
        // Position the center button
        centerButton.frame = CGRect(x: (screenWidth / 2) - (buttonSize / 2), y: CGFloat(buttonY), width: buttonSize, height: buttonSize)
        
        // Get all tab bar items except the center button
        let tabBarItems = subviews
            .filter { $0 is UIControl && $0 != centerButton }
            .sorted(by: { $0.frame.minX < $1.frame.minX })
        
        guard tabBarItems.count >= 4 else { return } // Ensure enough items exist
        
        let leftItems = Array(tabBarItems.prefix(tabBarItems.count / 2))  // Left of the center button
        let rightItems = Array(tabBarItems.suffix(tabBarItems.count / 2)) // Right of the center button
        
        let totalSpacing = screenWidth - (buttonSize + (CGFloat(tabBarItems.count) * leftItems[0].frame.width))
        let spacing = totalSpacing / CGFloat(tabBarItems.count + 1)
        
        // Arrange left-side items
        var xPosition: CGFloat = spacing
        for item in leftItems {
            item.frame.origin.x = xPosition
            xPosition += item.frame.width + spacing
        }
        
        // Arrange right-side items
        xPosition = (screenWidth / 2) + (buttonSize / 2) + spacing
        for item in rightItems {
            item.frame.origin.x = xPosition
            xPosition += item.frame.width + spacing
        }
    }
    
    @objc private func centerButtonTapped() {
        NotificationCenter.default.post(name: NSNotification.Name("CenterButtonTapped"), object: nil)
    }
}
