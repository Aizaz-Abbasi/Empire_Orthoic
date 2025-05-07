//
//  HomeVC.swift
//  EmpireScan
//
//  Created by MacOK on 17/03/2025.
//
import Foundation
import SwiftUI
import UIKit

class HomeVC: UIViewController {
    
    @IBOutlet weak var profileImg: UIImageView?
    @IBOutlet weak var nameLbl: UILabel?
    @IBOutlet weak var patientCountLbl: UILabel?
    @IBOutlet weak var totalScanLbl: UILabel?
    @IBOutlet weak var pendingScanCountLbl: UILabel?
    @IBOutlet weak var notScanCountLbl: UILabel?
    
    var profileData:UserProfile?
    var userStats:UserStats?
    var isLoading: Bool = false
    private var errorMessage: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HomeVC loaded")
        getData()
        profileImg?.image = profileImg?.image?.withRenderingMode(.alwaysTemplate)
        profileImg?.tintColor = .gray
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    private func getData() {
        print("HomeVC Get Data")
        HomeService.shared.getStats() { result in
            DispatchQueue.main.async {
                self.isLoading = false
                print("response getStats",result)
                switch result {
                case .success(let response):
                    print("response getStats",response)
                    self.userStats = response.data
                    self.setupStats()
                    if(response.success){
                    }else{
                        print("response.message",response.message)
                    }
                case .failure(let error): break
                   // errorMessage = error.localizedDescription
                }
            }
        }
        
        HomeService.shared.getProfile() { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    print("response getStats",response)
                    self.profileData = response.data
                    self.setupProfile()
                    if(response.success){
                    }else{
                        print("response.message",response.message)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    break
                }
            }
        }
    }
    
    func setupProfile() {
        nameLbl?.text = (profileData?.firstName ?? "") + " " + (profileData?.lastName ?? "")
        
    }
    
    func setupStats() {
        patientCountLbl?.text = "\(userStats?.patients ?? 0)"
        totalScanLbl?.text = "\(userStats?.totalScans ?? 0)"
        pendingScanCountLbl?.text = "\(userStats?.pendingScans ?? 0)"
        notScanCountLbl?.text = "\(userStats?.notScanYet ?? 0)"
    }
    
    @IBAction func scanTab(_ sender: UIButton) {
        guard let tabBarController = self.tabBarController else { return }
        print("sender.tag",sender.tag)
        if sender.tag == 0 {
            tabBarController.selectedIndex = 2 // Move to index 3
        } else {
            // Move to index 2 and pass parameters
            if let scansNavVC = tabBarController.viewControllers?[2] as? UINavigationController,
               let scansVC = scansNavVC.viewControllers.first as? ScansVC {
                if sender.tag == 1 {
                    scansVC.selectedTab = "All"
                }else if sender.tag == 2 {
                    scansVC.selectedTab = "Pending"
                }else if sender.tag == 3 {
                    scansVC.selectedTab = "Patients not scan yet"
                }
            }
            tabBarController.selectedIndex = 1 // Move to index 2
        }
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
