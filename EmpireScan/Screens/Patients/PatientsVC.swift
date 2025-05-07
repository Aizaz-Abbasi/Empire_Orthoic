import Foundation
import SwiftUI
import UIKit
import Combine

class PatientsVC: UIViewController {
    @IBOutlet weak var profileImg: UIImageView?
    @IBOutlet weak var searchView: UIView?
    @IBOutlet weak var searchBar: UISearchBar!
    private var selectedTab: String = "All"
    
    @ObservedObject private var viewModel = PatientsViewModel()
    private var hostingControllerPatients: UIHostingController<PatientsListView>?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        setupSearchBar()
        setupLoader()
        addPatientScanList()
        bindViewModel()
        //getData(searchText: "")
        print("User name:", HomeService.shared.user?.firstName ?? "No name1" + (HomeService.shared.user?.lastName ?? "No name2"))
        profileImg?.image = profileImg?.image?.withRenderingMode(.alwaysTemplate)
        profileImg?.tintColor = .gray
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getData(searchText: "")
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
        getData(searchText: "")
    }
    
    private func bindViewModel() {
        viewModel.$patients
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedPatients in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.hostingControllerPatients?.rootView = PatientsListView(
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
                        }, onRefresh: { [weak self] in
                            guard let self = self else { return }
                            self.getData(searchText: "")
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
    
    func addPatientScanList() {
        
        let swiftUIViewPatient = PatientsListView(patients: $viewModel.patients, totalPatients: $viewModel.totalPatients, isLoading: $viewModel.isLoading, onRefresh: {
            self.getData(searchText: "")
        })
        hostingControllerPatients = UIHostingController(rootView: swiftUIViewPatient)
        
        addChild(hostingControllerPatients!)
        hostingControllerPatients!.view.translatesAutoresizingMaskIntoConstraints = false
        hostingControllerPatients!.view.backgroundColor = .clear
        view.addSubview(hostingControllerPatients!.view)
        hostingControllerPatients!.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingControllerPatients!.view.topAnchor.constraint(equalTo: searchView?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 10),
            hostingControllerPatients!.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingControllerPatients!.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingControllerPatients!.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
    }
    
    func getData(searchText:String) {
        //isLoading = true
        var status: String?
        status = "Not Scanned"
        viewModel.fetchPatients(for: status, searchText: searchText,pageNumber: 1)
        
    }
    
    func updateData(searchText:String) {
       // isLoading = true
        var status: String?
        status = "Not Scanned"
        viewModel.fetchPatients(for: status, searchText: searchText,pageNumber: 1,isSearching: true)
    }
    
    func appendAndNavigate(data:PatientData) {
        viewModel.appendNewPatient(data)
        openPatientProfile(patient: data)
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
        ), FromScreen: "Patients",
         onApply: { [weak self] filters in
            guard let self = self else { return }
//            self.appliedFilters = filters
//            self.getData(searchText: "")
        })
        let hostingController = UIHostingController(rootView: filterModalView)
        hostingController.modalPresentationStyle = .automatic
        present(hostingController, animated: true)
    }
    
    private func openPatientProfile(patient: PatientData) {
        let swiftUIView = PatientProfileView(patient: patient,
                                             onSOrderSubmitted: {id in
                self.viewModel.removePatient(byId: id)
        })
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(hostingController, animated: true)
    }
}

extension PatientsVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("User typed: \(searchText)")
        getData(searchText: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search button tapped: \(searchBar.text ?? "")")
        searchBar.resignFirstResponder()
        getData(searchText: searchBar.text ?? "")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancel button tapped")
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
}
