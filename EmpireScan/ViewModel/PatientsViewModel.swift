class PatientsViewModel: ObservableObject {
    @Published var patients: [PatientData] = []
    @Published var totalPatients: Int = 0
    @Published var isLoading: Bool = false

    var currentPage = 1
    private let pageSize = 20
    var canLoadMore = true

    func fetchPatients(for status: String?, searchText: String, pageNumber: Int, isSearching: Bool = false) {
        print("fetchPatients",isLoading,canLoadMore)
        
        if(!isSearching){
            print("returning...",isLoading,canLoadMore)
            guard !isLoading, canLoadMore else { return }
        }
        isLoading = true
        
        let requestBody = SearchOrdersRequest(
            searchText: searchText,
            status: status,
            startDate: nil,
            endDate: nil,
            sortBy: "",
            pageNumber: pageNumber,
            pageSize: pageSize
        )
       
        ScansService.shared.getScansOrder(requestBody: requestBody) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let response):
                    if response.success {
                        print("getScansOrder",response)
                        let newPatients = response.data?.items ?? []
                        self.totalPatients = response.data?.totalItems ?? 0

                        if pageNumber == 1 {
                            self.patients = newPatients
                        } else {
                            self.patients.append(contentsOf: newPatients)
                        }
                        self.currentPage = pageNumber
                        self.canLoadMore = newPatients.count == self.pageSize
                    }
                case .failure(let error):
                    print("Error fetching getScansOrder: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadMorePatients(for status: String?, searchText: String) {
        if canLoadMore {
            fetchPatients(for: status, searchText: searchText, pageNumber: currentPage + 1)
        }
    }
    
    func appendNewPatient(_ patient: PatientData) {
        patients.insert(patient, at: 0) // Add to the top of the list
        totalPatients += 1
    }
    
    func removePatient(byId id: Int) {
        if let index = patients.firstIndex(where: { $0.id == id }) {
            patients.remove(at: index)
            totalPatients = max(totalPatients - 1, 0)
        }
    }
}
