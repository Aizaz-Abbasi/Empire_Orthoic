import SwiftUI

struct LoginScreen: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isKeyboardVisible = false
    var body: some View {
        if #available(iOS 14.0, *) {
            GeometryReader { geometry in
                ZStack {
                    // Background Image
                    Image("backgroundImg")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: geometry.size.height * 0.02) {
                        Text("Welcome back")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Colors.primaryText)
                            .padding(.top, geometry.size.height * 0.2)
                        
                        Text("We're so excited to see you again!")
                            .font(.system(size: 16))
                            .foregroundColor(Colors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        CustomTextField(
                            title: "Email",
                            text: $email,
                            placeholder: "Enter your email",
                            isSecure: false,
                            screenWidth: geometry.size.width,
                            screenHeight: UIScreen.main.bounds.height
                        )
                        
                        CustomTextField(
                            title: "Password",
                            text: $password,
                            placeholder: "Enter your password",
                            isSecure: true,
                            screenWidth: geometry.size.width,
                            screenHeight: UIScreen.main.bounds.height
                        )
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Text("Forgot password?")
                                .foregroundColor(Colors.primary)
                                .font(.caption)
                        }
                        .padding(.trailing)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.system(size: 14, weight: .semibold))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                        }
                        // Login Button
                        Button(action: {
                            performLogin()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(height: 44) // Maintain button height
                            } else {
                                Text("Log in")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Colors.primary)
                                    .cornerRadius(30)
                            }
                        }
                        .padding(.horizontal)
                        .disabled(isLoading)
                        
                        
                        // Sign-Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(Colors.primaryText)
                                .font(.system(size: 14))
                            
                            
                            Text("Sign up")
                                .foregroundColor(Colors.primary)
                                .font(.system(size: 14))
                            
                                .underline()
                        }
                        .font(.footnote)
                        .padding(.top, 5)
                        
                        Spacer(minLength: geometry.size.height * 0.03)
                    }
                    .keyboardAware() //isVisible: $isKeyboardVisible Apply the keyboard-aware modifier
                }
            }
        } else {
            // Fallback for older iOS versions
        }
    }
    
    func performLogin() {
        //switchToMainTabBar()
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    print("Login Success: Token - \(response.data?.accessToken ?? "")")
                    if(response.success){
                        switchToMainTabBar()
                    }else{
                        print("response.message",response.message)
                        errorMessage = response.message
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func switchToMainTabBar() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            window.rootViewController = tabBarVC
            window.makeKeyAndVisible()
        }
    }
}

#Preview {
    LoginScreen()
}

