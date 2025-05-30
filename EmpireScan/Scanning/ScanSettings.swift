//
//  ScanSettings.swift
//  EmpireScan
//
//  Created by MacOK on 21/05/2025.
//

import Foundation

// MARK: SettingsPopupView
class SettingsPopupView: UIView {
    private var _settingsIcon: UIButton!
    private var _closeIcon: UIButton!
    
    private var _settingsListModal: SettingsListModal!
    private var _isSettingsListModalHidden: Bool = true
    private var widthConstraintWhenListModalIsShown: NSLayoutConstraint!
    private var heightConstraintWhenListModalIsShown: NSLayoutConstraint!
    private var widthConstraintWhenListModalIsHidden: NSLayoutConstraint!
    private var heightConstraintWhenListModalIsHidden: NSLayoutConstraint!
    var optionsSet = OptionsSet()
    var isShown: Bool { return !_isSettingsListModalHidden }
    
    init(options: OptionsSet = OptionsSet()) {
        optionsSet = options
        super.init(frame: CGRect.zero)
        setupComponents()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupComponents() {

        backgroundColor = UIColor.clear
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false
        
        // Settings Icon (Top-Left)
        _settingsIcon = UIButton()
        _settingsIcon.setImage(UIImage(named: "settings-icon.png"), for: .normal)
        _settingsIcon.setImage(UIImage(named: "settings-icon.png"), for: .highlighted)
        _settingsIcon.translatesAutoresizingMaskIntoConstraints = false
        _settingsIcon.contentMode = .scaleAspectFit
        _settingsIcon.addTarget(self, action: #selector(settingsIconPressed(_:)), for: .touchUpInside)
        addSubview(_settingsIcon)
        
        NSLayoutConstraint.activate([
            _settingsIcon.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            _settingsIcon.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            _settingsIcon.widthAnchor.constraint(equalToConstant: 45.0),
            _settingsIcon.heightAnchor.constraint(equalToConstant: 45.0)
        ])
        
        // Close Icon (Top-Right)
        _closeIcon = UIButton()
        _closeIcon.setImage(UIImage(named: "cross")?.withRenderingMode(.alwaysTemplate), for: .normal)
        _closeIcon.setImage(UIImage(named: "cross")?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        _closeIcon.tintColor = .white
        _closeIcon.translatesAutoresizingMaskIntoConstraints = false
        _closeIcon.contentMode = .scaleAspectFit
        _closeIcon.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        _closeIcon.layer.cornerRadius = _closeIcon.frame.size.height / 2
        _closeIcon.addTarget(self, action: #selector(closeIconPressed(_:)), for: .touchUpInside)
        addSubview(_closeIcon)
        
        NSLayoutConstraint.activate([
            _closeIcon.topAnchor.constraint(equalTo: self.topAnchor, constant: 10), // Padding from top
            _closeIcon.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10), // Align to right with padding
            _closeIcon.widthAnchor.constraint(equalToConstant: 45.0),
            _closeIcon.heightAnchor.constraint(equalToConstant: 45.0)
        ])
        
        // Settings List Modal
        _settingsListModal = SettingsListModal(options: optionsSet)
        
        let screenBounds: CGRect = UIScreen.main.bounds
        widthConstraintWhenListModalIsShown = widthAnchor.constraint(equalToConstant: 420.0)
        heightConstraintWhenListModalIsShown = heightAnchor.constraint(equalToConstant: screenBounds.size.height - 40)
        
        widthConstraintWhenListModalIsHidden = widthAnchor.constraint(equalToConstant: screenBounds.size.width-50) // Ensure enough width for close button
        heightConstraintWhenListModalIsHidden = heightAnchor.constraint(equalTo: _settingsIcon.heightAnchor)
        
        NSLayoutConstraint.activate([
            widthConstraintWhenListModalIsHidden,
            heightConstraintWhenListModalIsHidden
        ])
        _isSettingsListModalHidden = true
    }
    
    override func layoutSubviews() {
            super.layoutSubviews()

            // Now that layout is complete, set the corner radius
            _closeIcon.layer.cornerRadius = _closeIcon.frame.size.height / 2
            _closeIcon.clipsToBounds = true
    }
    
    func showSettingsListModal() {
        addSubview(_settingsListModal)
        
        NSLayoutConstraint.activate([
            _settingsListModal.leftAnchor.constraint(equalTo: _settingsIcon.leftAnchor),
            _settingsListModal.topAnchor.constraint(equalTo: _settingsIcon.bottomAnchor, constant: 20.0),
            _settingsListModal.widthAnchor.constraint(equalToConstant: 350.0),
            _settingsListModal.heightAnchor.constraint(equalTo: _settingsListModal.superview!.heightAnchor, constant: -40.0)
        ])
        
        bringSubviewToFront(_settingsListModal)
    }
    
    func hideSettingsListModal() {
        _settingsListModal.removeFromSuperview()
    }
    
    @objc func settingsIconPressed(_ sender: UIButton) {
        if _isSettingsListModalHidden {
            _isSettingsListModalHidden = false
            NSLayoutConstraint.deactivate([widthConstraintWhenListModalIsHidden,
                                           heightConstraintWhenListModalIsHidden])
            NSLayoutConstraint.activate([widthConstraintWhenListModalIsShown,
                                         heightConstraintWhenListModalIsShown])
            showSettingsListModal()
            return
        }
        
        _isSettingsListModalHidden = true
        NSLayoutConstraint.deactivate([widthConstraintWhenListModalIsShown,
                                       heightConstraintWhenListModalIsShown])
        NSLayoutConstraint.activate([widthConstraintWhenListModalIsHidden,
                                     heightConstraintWhenListModalIsHidden])
        hideSettingsListModal()
    }
    
    @objc func closeIconPressed(_ sender: UIButton) {
        print("closeIconPressed")
        _isSettingsListModalHidden = true
        NSLayoutConstraint.deactivate([widthConstraintWhenListModalIsShown, heightConstraintWhenListModalIsShown])
        NSLayoutConstraint.activate([widthConstraintWhenListModalIsHidden, heightConstraintWhenListModalIsHidden])
        hideSettingsListModal()
        
        // If this view is presented modally, dismiss it
        if let viewController = self.window?.rootViewController {
            print("closeIconPressed dismiss")
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
}
