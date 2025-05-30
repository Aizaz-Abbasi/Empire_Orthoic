
import SwiftUI
struct PatientListView: View {
    @Binding var patients: [PatientData]
    @Binding var totalPatients: Int
    @Binding var isLoading: Bool
    var loadMoreAction: (() -> Void)?
    var onPatientSelected: ((PatientData) -> Void)?
    var onRefresh: () -> Void
    
    // MARK: - New State Variables for Navigation
    @State private var selectedPatient: PatientData?
    @State private var isNavigating = false
    @State private var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView()
            
            if patients.isEmpty && !isLoading {
                emptyStateView()
            } else {
                patientListView()
            }
        }
        .background(Color.clear)
        .navigationDestination(isPresented: $isNavigating) {
            if let patient = selectedPatient {
                PatientProfileView(patient: patient)
            }
        }
    }

    // MARK: - Header View
    private func headerView() -> some View {
        HStack {
            totalPatientsView()
            //selectAllButton()
        }
        .padding()
    }

    private func totalPatientsView() -> some View {
        HStack {
            Text("Total Patients: ")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            Text("\(totalPatients)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.clear))
    }

    private func selectAllButton() -> some View {
        HStack {
            Button(action: { isSelected.toggle() }) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
            }

            Text("Select all")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .background(Color(UIColor.clear))
    }

    // MARK: - Empty State
    private func emptyStateView() -> some View {
        Text("No patients available")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 16)
    }

    // MARK: - Patient List
    private func patientListView() -> some View {
        List {
            ForEach(patients) { patient in
                patientRow(patient)
            }
            .background(Color(UIColor.clear))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .refreshable {
                onRefresh()
             }
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
        .scrollContentBackground(.hidden)
    }


    private func patientRow(_ patient: PatientData) -> some View {
        Button(action: {
            onPatientSelected?(patient)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)

                PatientRowView(patient: patient)
                    .padding(12)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
            .padding(.horizontal, 8)
            .listRowSeparator(.hidden)
            .onAppear {
                if patient == patients.last && !isLoading {
                    loadMoreAction?()
                }
            }
            .background(Color(UIColor.clear))
        }
        .background(Color(UIColor.clear))
    }
}

