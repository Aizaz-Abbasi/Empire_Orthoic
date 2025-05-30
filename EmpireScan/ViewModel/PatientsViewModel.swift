class SessionService {
    static let shared = SessionService()

    var filters: FilterValues? = nil
    var selectedTab: String = "All"
    var lastSearchText: String = ""
    
    private init() {} // Prevent external initialization
}

class PatientsViewModel: ObservableObject {
    @Published var patients: [PatientData] = []
    @Published var totalPatients: Int = 0
    @Published var isLoading: Bool = false
    
    var currentPage = 1
    private let pageSize = 20
    var canLoadMore = true
    var currentSearchText = ""
    var currentStatus: String? = nil
    var currentSortOption: String? = nil
    var currentStartDate: Date? = nil
    var currentEndDate: Date? = nil
    var currentDisplayUploadedScans: Bool = false
    
    func fetchPatients(
        for status: String?,
        searchText: String,
        pageNumber: Int,
        isSearching: Bool = false,
        sortOption: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        displayUploadedScans: Bool = false
    ){
        
        print("fetchPatients",isLoading,canLoadMore)
        if(!isSearching){
            print("returning...",isLoading,canLoadMore)
            guard !isLoading, canLoadMore else { return }
        }
        var sortOptionStr = ""
        if let sortOption = sortOption {
            let sortMapping: [String: String] = [
                "Alphabetical": "Name",
                "Modified recently first": "ModifyAsc",
                "Modified recently last": "ModifyDesc",
                "Latest scan": "ScanDesc"
            ]
            sortOptionStr = sortMapping[sortOption] ?? ""
        }
        
        isLoading = true
        
        let requestBody = SearchOrdersRequest(
            searchText: searchText,
            status: status,
            startDate: formatDateToString(startDate),
            endDate: formatDateToString(endDate),
            sortBy: sortOptionStr,
            pageNumber: pageNumber,
            pageSize: pageSize,
            displayUploadedScans: displayUploadedScans
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
            fetchPatients(
                for: currentStatus,
                searchText: currentSearchText,
                pageNumber: currentPage + 1,
                sortOption: currentSortOption,
                startDate: currentStartDate,
                endDate: currentEndDate,
                displayUploadedScans: currentDisplayUploadedScans
            )
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
    
    func updatePatientStatus(byId id: Int,status:String) {
        if let index = patients.firstIndex(where: { $0.id == id }) {
            patients[index].status = status
            
        }
    }
}
