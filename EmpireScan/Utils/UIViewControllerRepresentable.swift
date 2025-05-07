//
//  UIViewControllerRepresentable.swift
//  EmpireScan
//
//  Created by MacOK on 14/04/2025.
//

import Foundation
import SwiftUI

struct UIKitViewControllerWrapper: UIViewControllerRepresentable {
    var footType: String
    var folderItem: ScanFolderItem?
    var patient: PatientData?
    var orderId:Int
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Create and return an empty UIViewController to use as a container
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Present your FixedOrientationController here
        navigateToScanner(footType: footType, folderItem: folderItem, patient: patient, orderId: orderId, parentViewController: uiViewController)
    }
    
    func navigateToScanner(footType: String, folderItem: ScanFolderItem?, patient: PatientData?, orderId:Int, parentViewController: UIViewController) {
        var selectedFoot: String?
        
        if let scan = folderItem?.scans.first(where: { $0.footType?.lowercased() == footType.lowercased() }) {
            selectedFoot = footType
            print("Navigating to scanner for \(footType) Foot")
            print("Scan found: \(scan)")
            
            guard let foot = selectedFoot else { return }
            print("Starting scan for \(scan.scanType) foot")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let fixedOrientationVC = storyboard.instantiateViewController(withIdentifier: "FixedOrientationController") as? FixedOrientationController {
                if let viewController = fixedOrientationVC.viewControllers.first as? ViewController {
                    viewController.footType = foot
                    viewController.orderId = patient?.orderId
                    viewController.folderId = folderItem?.folderId
                    viewController.orderStatus = patient?.status
                }
                fixedOrientationVC.modalPresentationStyle = .fullScreen
                parentViewController.present(fixedOrientationVC, animated: true)
            }
        } else {
            print("❌ No scan found for \(footType) Foot")
        }
    }
}
