import Foundation
import SwiftUI
import UIKit
import Combine
class ScansVC: UIViewController {
    @IBOutlet weak var profileImg: UIImageView?
    @IBOutlet weak var searchView: UIView?
    @IBOutlet weak var searchBar: UISearchBar!
    var isSearching: Bool = false
    var patients: [PatientData] = []
    //var isLoading: Bool = false
    private var errorMessage: String? = nil
    var selectedTab: String = "All"
    @ObservedObject private var viewModel = PatientsViewModel()
    
    private var hostingControllerPatients: UIHostingController<PatientListView>?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var cancellables: Set<AnyCancellable> = []
    //Filter
    var appliedFilters: FilterValues?
    private let filterStatusView = UIView()
    private let filterLabel = UILabel()
    private let clearFilterButton = UIButton(type: .system)
    private var hasNavigated = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupLoader()
        addPatientScanList()
        setupFilterStatusView()
        bindViewModel()
        getData(searchText: "")
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        print("User name:", HomeService.shared.user?.firstName ?? "No name1" + (HomeService.shared.user?.lastName ?? "No name2"))
        profileImg?.image = profileImg?.image?.withRenderingMode(.alwaysTemplate)
        profileImg?.tintColor = .gray
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        hasNavigated = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear - ScansVC")
        if !hasNavigated {
            clearFilters()
            print("viewDidDisappear - ScansVC Clearing Filter")
        }
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
        view.bringSubviewToFront(activityIndicator)
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
                            print("Calling API to load more data...",selectedTab)
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
                            case "Submitted":
                                status = "Scanned and Submitted"
                            default:
                                status = nil
                            }
                            // Safely use filters
                            let sortOption = appliedFilters?.sortOption
                            let startDate = appliedFilters?.startDate
                            let endDate = appliedFilters?.endDate
                            let displayUploaded = appliedFilters?.displayUploadedScans ?? false
                            viewModel.fetchPatients(
                                for: status,
                                searchText: searchBar.text ?? "-",
                                pageNumber: self.viewModel.currentPage + 1,
                                isSearching: isSearching,
                                sortOption: sortOption,
                                startDate: startDate,
                                endDate: endDate,
                                displayUploadedScans: displayUploaded
                            )
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
                    self.view.bringSubviewToFront(self.activityIndicator)
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
            options: ["All", "In Progress", "Completed", "Pending","Submitted"],
            onTabSelected: { [weak self] selectedTab in
                SessionService.shared.filters = nil
                self?.appliedFilters?.displayUploadedScans = false
                self?.appliedFilters?.endDate=nil
                self?.appliedFilters?.startDate=nil
                self?.appliedFilters?.sortOption=""
                self?.isSearching = false
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
    
    private func setupFilterStatusView() {
        filterStatusView.translatesAutoresizingMaskIntoConstraints = false
        filterStatusView.backgroundColor = UIColor.systemGray6
        filterStatusView.layer.cornerRadius = 8
        filterStatusView.isHidden = true // Hidden by default
        
        filterLabel.translatesAutoresizingMaskIntoConstraints = false
        filterLabel.textColor = .darkGray
        filterLabel.font = UIFont.systemFont(ofSize: 14)
        
        clearFilterButton.setTitle("✖", for: .normal)
        clearFilterButton.translatesAutoresizingMaskIntoConstraints = false
        clearFilterButton.addTarget(self, action: #selector(clearFilters), for: .touchUpInside)
        
        filterStatusView.addSubview(filterLabel)
        filterStatusView.addSubview(clearFilterButton)
        view.addSubview(filterStatusView)
        
        NSLayoutConstraint.activate([
            filterStatusView.topAnchor.constraint(equalTo: searchView?.bottomAnchor ?? view.topAnchor, constant: 8),
            filterStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterLabel.leadingAnchor.constraint(equalTo: filterStatusView.leadingAnchor, constant: 8),
            filterLabel.centerYAnchor.constraint(equalTo: filterStatusView.centerYAnchor),
            clearFilterButton.leadingAnchor.constraint(equalTo: filterLabel.trailingAnchor, constant: 8),
            clearFilterButton.trailingAnchor.constraint(equalTo: filterStatusView.trailingAnchor, constant: -8),
            clearFilterButton.centerYAnchor.constraint(equalTo: filterStatusView.centerYAnchor),
            filterStatusView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    @objc private func clearFilters() {
        appliedFilters = nil
        SessionService.shared.filters = nil
        filterLabel.text = ""
        filterStatusView.isHidden = true
        viewModel.canLoadMore = true
        viewModel.currentPage = 1
        getData(searchText: "")
    }
    
    func getData(searchText: String, isSearching: Bool = false) {
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
        case "Submitted":
            status = "Scanned and Submitted"
        default:
            status = nil
        }
        //
        if let filters = appliedFilters {
            var components: [String] = []
            
            if let sort = filters.sortOption, !sort.isEmpty {
                components.append("Sort: \(sort)")
            }
            if let start = filters.startDate {
                components.append("| Date")
                print("Date",start)
            }else if let end = filters.endDate {
                components.append("| Date")
                print("Date",end)
            }
            filterLabel.text = components.joined(separator: " | ")
            filterStatusView.isHidden = components.isEmpty
            viewModel.canLoadMore = true
            viewModel.currentPage = 1
            print("components",components)
        } else {
            filterLabel.text = ""
            filterStatusView.isHidden = true
        }
        print("isSearching",isSearching)
        // Safely use filters
        let sortOption = appliedFilters?.sortOption
        let startDate = appliedFilters?.startDate
        let endDate = appliedFilters?.endDate
        let displayUploaded = appliedFilters?.displayUploadedScans ?? false
        viewModel.fetchPatients(
            for: status,
            searchText: searchText,
            pageNumber: 1,
            isSearching: isSearching,
            sortOption: sortOption,
            startDate: startDate,
            endDate: endDate,
            displayUploadedScans: displayUploaded
        )
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
            SessionService.shared.filters = filters
            self.appliedFilters = filters
            self.getData(searchText: "")
        })
        let hostingController = UIHostingController(rootView: filterModalView)
        hostingController.modalPresentationStyle = .automatic
        present(hostingController, animated: true)
    }
    
    private func openPatientProfile(patient: PatientData) {
        hasNavigated = true
        let swiftUIView = PatientProfileView(patient: patient)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(hostingController, animated: true)
    }
}

extension ScansVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("User typed: \(searchText)")
        isSearching = true
        if(searchText.isEmpty){
            print("User typed: isSearching = false")
            isSearching = false
        }
        getData(searchText: searchText,isSearching: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search button tapped: \(searchBar.text ?? "")")
        searchBar.resignFirstResponder()
        getData(searchText: searchBar.text ?? "",isSearching: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancel button tapped")
        isSearching = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
}
