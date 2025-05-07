import SwiftUI
import Kingfisher

struct PatientsRowView: View {
    let patient: PatientData

    var body: some View {
        //Color.green
        GeometryReader { geometry in
           // Color.blue
            VStack() {
               // Color.green
                HStack {
                    (Text("ID #: ")
                        .font(.system(size: 16))
                        .foregroundColor(.gray) +
                     Text(" \(patient.orderId)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black))
                    Spacer()
                    
                    Text(patient.status ?? "")
                        .font(.system(size: geometry.size.width * 0.035))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(patient.status == "Sent" ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }.background(Color.clear)
                Divider() // Adds a subtle separator
                // Bottom Section - Profile Image and Details
                HStack(spacing: geometry.size.width * 0.04) { // Dynamic spacing

                    PatientImageView(imageUrl: patient.imageUrl ?? "")
                        .frame(width: geometry.size.width * 0.15, height: geometry.size.width * 0.15)
                        .clipShape(Circle())
                    
                    // Patient Details
                    VStack(alignment: .leading, spacing: geometry.size.height * 0.005) { // 0.5% of height
                        Text("\(patient.patientFirstName  ?? "") \(patient.patientLastName ?? "")")
                            .font(.system(size: geometry.size.width * 0.05, weight: .bold))
                            .foregroundColor(.black)

                        Text("Last scan: \(patient.completeDate)")
                            .font(.system(size: geometry.size.width * 0.035))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    // Chevron Arrow
                    Image(systemName: "chevron.right")
                        .foregroundColor(Colors.primary)
                }
            }
            //.padding(.horizontal, 8)
            .padding(.vertical, 8)
            //.background(Color.red)
        }
        .frame(height: UIScreen.main.bounds.height * 0.12)
        .background(Color.clear)
    }
}
