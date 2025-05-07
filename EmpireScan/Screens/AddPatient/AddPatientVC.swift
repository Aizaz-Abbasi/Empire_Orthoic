//
//  AddPatientVC.swift
//  EmpireScan
//
//  Created by MacOK on 20/03/2025.
//

import Foundation
import UIKit
import SwiftUI

class AddPatientVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func showFilterModal(_ sender: UIButton) {
        var isPresented = true

        let filterModalView = FilterModalView(isPresented: Binding(
            get: { isPresented },
            set: { newValue in
                if !newValue {
                    self.dismiss(animated: true)
                }
            }
        ), FromScreen: "",
                                              onApply: { [weak self] filters in
                                                 guard let self = self else { return }
                                     //            self.appliedFilters = filters
                                     //            self.getData(searchText: "")
                                             })

        let hostingController = UIHostingController(rootView: filterModalView)
        hostingController.modalPresentationStyle = .automatic
        present(hostingController, animated: true)
    }
}
