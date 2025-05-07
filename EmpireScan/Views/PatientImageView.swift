import SwiftUI
import Kingfisher

struct PatientImageView: View {
    let imageUrl: String?
    
    var body: some View {
        if let imageUrl = imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
            if #available(iOS 14.0, *) {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 0.12, height: UIScreen.main.bounds.width * 0.12)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Colors.border, lineWidth: 1) // Add a border
                    )
                    .background(Color.white)
            } else {
                EmptyView() // Fallback on earlier versions
            }
        } else {
            Image(systemName: "person.crop.circle")
                .renderingMode(.template) // ✅ Apply before modifying the view
                .resizable()
                .scaledToFit()
                .foregroundColor(Colors.lightGray)
                .frame(width: UIScreen.main.bounds.width * 0.12, height: UIScreen.main.bounds.width * 0.12)
                .clipShape(Circle())
                .overlay(Circle().stroke(Colors.border, lineWidth: 0))
                .background(Color.white)

        }
    }
}
