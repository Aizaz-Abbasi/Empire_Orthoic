import Foundation
import SwiftUI
import UIKit
import Combine

class ScansVC: UIViewController {
    @IBOutlet weak var profileImg: UIImageView?
    @IBOutlet weak var searchView: UIView?
    @IBOutlet weak var searchBar: UISearchBar!
    
    var patients: [PatientData] = []
    var isLoading: Bool = false
    private var errorMessage: String? = nil
    var selectedTab: String = "All"
    @ObservedObject private var viewModel = PatientsViewModel()
    
    private var hostingControllerPatients: UIHostingController<PatientListView>?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var cancellables: Set<AnyCancellable> = []
    var appliedFilters: FilterValues?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupLoader()
        addPatientScanList()
        bindViewModel()
        getData(searchText: "")
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        print("User name:", HomeService.shared.user?.firstName ?? "No name1" + (HomeService.shared.user?.lastName ?? "No name2"))
        profileImg?.image = profileImg?.image?.withRenderingMode(.alwaysTemplate)
        profileImg?.tintColor = .gray
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        if let textfield = searchBar.value(forKey: "searchField") as? UITextField {
            textfield.textColor = UIColor.black
            textfield.backgroundColor = UIColor.white
        }
    }
    
    private func setupLoader() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func handleTabSelection(_ newTab: String) {
        selectedTab = newTab
        print("Selected tab updated in ScansVC: \(newTab)")
        viewModel.patients = []
        viewModel.totalPatients = 0
        viewModel.currentPage = 0
        viewModel.canLoadMore = true
        getData(searchText: "") // Fetch new data when tab changes
    }

    private func bindViewModel() {
        viewModel.$patients
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedPatients in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.hostingControllerPatients?.rootView = PatientListView(
                        patients: Binding(
                            get: { self.viewModel.patients },
                            set: { self.viewModel.patients = $0 }
                        ), totalPatients: Binding(
                            get: { self.viewModel.totalPatients },
                            set: { self.viewModel.totalPatients = $0 }),
                        isLoading: Binding(
                            get: { self.viewModel.isLoading },
                            set: { self.viewModel.isLoading = $0 }),
                        loadMoreAction: { [weak self] in
                                guard let self = self else { return }
                                print("Calling API to load more data...")
                                var statusTag: String?
                                statusTag = "Not Scanned"
                                self.viewModel.fetchPatients(for: statusTag, searchText: "", pageNumber: self.viewModel.currentPage + 1)
                            
                            },
                        onPatientSelected: { [weak self] patient in
                                                self?.openPatientProfile(patient: patient)
                        }, onRefresh: {
                            self.refresh()
                        }
                    )
                }
            }
            .store(in: &cancellables)
        // Observe isLoading to control loader visibility
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self = self else { return }
                if loading {
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
    
    func refresh(){
        viewModel.totalPatients = 0
        viewModel.currentPage = 0
        viewModel.canLoadMore = true
        getData(searchText: "")
    }

    func addPatientScanList() {
        //, "Patients not scan yet"
        let swiftUIView = ScrollableTabView(
            options: ["All", "In Progress", "Completed", "Pending"],
            onTabSelected: { [weak self] selectedTab in
                self?.handleTabSelection(selectedTab)
            }
        )
        
        let hostingControllerTabs = UIHostingController(rootView: swiftUIView)
        addChild(hostingControllerTabs)
        hostingControllerTabs.view.backgroundColor = .white
        hostingControllerTabs.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingControllerTabs.view)
        hostingControllerTabs.didMove(toParent: self)

        let swiftUIViewPatient = PatientListView(patients: $viewModel.patients, totalPatients: $viewModel.totalPatients, isLoading: $viewModel.isLoading, onRefresh: {
            self.refresh()
        })
        hostingControllerPatients = UIHostingController(rootView: swiftUIViewPatient)
        
        addChild(hostingControllerPatients!)
        hostingControllerPatients!.view.translatesAutoresizingMaskIntoConstraints = false
        hostingControllerPatients!.view.backgroundColor = .clear
        view.addSubview(hostingControllerPatients!.view)
        hostingControllerPatients!.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingControllerTabs.view.topAnchor.constraint(equalTo: searchView?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 0),
            hostingControllerTabs.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingControllerTabs.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingControllerTabs.view.heightAnchor.constraint(equalToConstant: 50),
            
            hostingControllerPatients!.view.topAnchor.constraint(equalTo: hostingControllerTabs.view.bottomAnchor, constant: 0),
            hostingControllerPatients!.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            hostingControllerPatients!.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            hostingControllerPatients!.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
    }
    
    func getData(searchText: String, isSearching: Bool = false) {
        isLoading = true
        var status: String?
        
        switch selectedTab {
        case "All":
            status = nil
        case "In Progress":
            status = "In Progress"
        case "Completed":
            status = "Completed"
        case "Pending":
            status = "Pending"
        case "Patients not scan yet":
            status = "Not Scanned"
        default:
            status = nil
        }
        // Safely use filters
        let sortOption = appliedFilters?.sortOption
        let startDate = appliedFilters?.startDate
        let endDate = appliedFilters?.endDate
        let displayUploaded = appliedFilters?.displayUploadedScans ?? false
        viewModel.fetchPatients(for: status, searchText: searchText, pageNumber: 1, isSearching: isSearching)
    }
    
    @IBAction func showFilterModal(_ sender: UIButton) {
        let isPresented = true
            let filterModalView = FilterModalView(isPresented: Binding(
                get: { isPresented },
                set: { newValue in
                    if !newValue {
                        self.dismiss(animated: true)
                    }
                }
            ), FromScreen: "Scans",
            onApply: { [weak self] filters in
                guard let self = self else { return }
                self.appliedFilters = filters
                self.getData(searchText: "")
            })
            let hostingController = UIHostingController(rootView: filterModalView)
            hostingController.modalPresentationStyle = .automatic
            present(hostingController, animated: true)
    }

    private func openPatientProfile(patient: PatientData) {
        let swiftUIView = PatientProfileView(patient: patient)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.hidesBottomBarWhenPushed = true
        // Make sure you're pushing onto a navigation stack
        navigationController?.pushViewController(hostingController, animated: true)
    }
}

extension ScansVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("User typed: \(searchText)")
        getData(searchText: searchText,isSearching: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search button tapped: \(searchBar.text ?? "")")
        searchBar.resignFirstResponder()
        getData(searchText: searchBar.text ?? "",isSearching: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancel button tapped")
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
}
