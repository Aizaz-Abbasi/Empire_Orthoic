//
//  SettingsVC.swift
//  EmpireScan
//
//  Created by MacOK on 06/05/2025.
//
import Foundation
import SwiftUI

class SettingsVC: UIViewController {
    
    @IBOutlet weak var settingsBtn: UIButton?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setDynamicCornerRadius()
        print("SettingsVC loaded")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setDynamicCornerRadius()
    }

    private func setDynamicCornerRadius() {
        guard let button = settingsBtn else { return }
        // Set corner radius as a percentage of the button's height (e.g., 20% of the height)
        let cornerRadius = button.frame.size.height * 0.5
        button.layer.cornerRadius = cornerRadius
        // Ensure the button's content doesn't overflow the rounded corners
        button.clipsToBounds = true
    }

    @IBAction func logOutButton(_ sender: UIButton) {
        print("logOutButton ===>")
        TokenManager.shared.clearTokens()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let letsGoVC = storyboard.instantiateViewController(withIdentifier: "LetsGoVC") as? UIViewController{
            let navController = UINavigationController(rootViewController: letsGoVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true, completion: nil)
        }
    }
}
