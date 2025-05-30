////
////  CustomTabBarController.swift
////  EmpireScan
////
////  Created by MacOK on 20/03/2025.
////
import Foundation
import UIKit
import SwiftUI

class CustomTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(openCenterScreen), name: NSNotification.Name("CenterButtonTapped"), object: nil)
    }

    @objc private func openCenterScreen() {
        if #available(iOS 15.0, *) {
            let newPatientView = NewPatientView(dismissAction: {data in
                self.navigateToTab(index: 2)
                DispatchQueue.main.async {
                        if let navController = self.viewControllers?[2] as? UINavigationController,
                           let targetVC = navController.topViewController as? PatientsVC {
                            targetVC.appendAndNavigate(data: data)
                            print("getData")
                        }
                }
            })
            let hostingController = UIHostingController(rootView: newPatientView)
            hostingController.modalPresentationStyle = .fullScreen
            present(hostingController, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
        }
    }
    
    private func openPatientProfile(patient: PatientData) {
        let swiftUIView = PatientProfileView(patient: patient)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.hidesBottomBarWhenPushed = true
        // Make sure you're pushing onto a navigation stack
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    func navigateToTab(index: Int) {
        self.selectedIndex = index
    }
}
