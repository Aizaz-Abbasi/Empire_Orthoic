import SwiftUI

struct FloatingButton1: View {
    @State private var showAlert = false
    
    var body: some View {
        Button(action: {
            self.showAlert = true
        }) {
            VStack {
                Image(systemName: "plus")
                    .imageScale(.large)
                
                Text("Add")
                    .font(.headline)
                    .foregroundColor(Color.black)
            }
            .padding()
            .frame(width: 100, height: 100)
            .background(Color.yellow)
            .foregroundColor(Color.white)
            .cornerRadius(50)
            .shadow(color: Color.black, radius: 5)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text("You tapped the floating button"), dismissButton: .default(Text("Yeah")))
        }
    }
}

#if DEBUG
struct FloatingButton_Previews: PreviewProvider {
    static var previews: some View {
        FloatingButton1()
    }
}
#endif
