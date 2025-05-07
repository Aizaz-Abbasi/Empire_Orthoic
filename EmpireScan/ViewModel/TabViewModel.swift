//
//  TabViewModel.swift
//  EmpireScan
//
//  Created by MacOK on 17/03/2025.
//

import Foundation
import Foundation
import Combine

class TabViewModel: ObservableObject {
    @Published var selectedTab: String = "Sent"  // Tracks selected tab
}
