//
//  LetsGoVC.swift
//  3DFootScan_Pro
//
//  Created by MacOK on 06/03/2025.
//

import Foundation
import SwiftUI
import UIKit

class LetsGoVC: UIViewController {

    @IBOutlet weak var letsGoBtn: UIButton?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setDynamicCornerRadius()
        print("LetsGoVC loaded")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setDynamicCornerRadius()
    }

    private func setDynamicCornerRadius() {
        guard let button = letsGoBtn else { return }
        // Set corner radius as a percentage of the button's height (e.g., 20% of the height)
        let cornerRadius = button.frame.size.height * 0.5
        button.layer.cornerRadius = cornerRadius
        // Ensure the button's content doesn't overflow the rounded corners
        button.clipsToBounds = true
    }

    @IBAction func navigateToSwiftUIScreen(_ sender: UIButton) {
        print("navigateToSwiftUIScreen")
        if #available(iOS 14.0, *) {
            let swiftUIView = LoginScreen()
            let hostingController = UIHostingController(rootView: swiftUIView)
            navigationController?.pushViewController(hostingController, animated: true)
        } else {
            // Fallback on earlier versions
        }
       
    }
}
