import UIKit
import SwiftUI
import Sentry
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //        window = UIWindow(frame: UIScreen.main.bounds)
        SentrySDK.start { options in
                options.dsn = "https://5b06fb07cfa0e9df68889dfa0dcb693a@o4509438736138240.ingest.us.sentry.io/4509438823825408"
                options.debug = true // 💡 Remove in production
                options.enableSwizzling = true // Auto breadcrumbs
        }
        setInitialViewController()
        return true
    }
    
    private func setInitialViewController2() {
        guard let window = window else { return }
        
        let isLoggedIn = TokenManager.shared.accessToken
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if isLoggedIn != nil {
            // User is logged in, set the main tab bar controller as root
            if let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
                window.rootViewController = mainTabBarController
                let firstViewController = ScansVC()
                      let firstNavController = UINavigationController(rootViewController: firstViewController)
                      firstNavController.tabBarItem = UITabBarItem(title: "ScansVC", image: UIImage(systemName: "1.circle"), tag: 0)
                      
                      // Create and configure the second tab
                let secondViewController = PatientsVC()
                      let secondNavController = UINavigationController(rootViewController: secondViewController)
                      secondNavController.tabBarItem = UITabBarItem(title: "Patients", image: UIImage(systemName: "2.circle"), tag: 1)
                      
                      // Assign the navigation controllers to the tab bar controller
                      mainTabBarController.viewControllers = [firstNavController, secondNavController]
                      window.rootViewController = mainTabBarController
            
            }
        } else {
            // User is not logged in, show LetsGoVC embedded in a navigation controller
            if let letsGoVC = storyboard.instantiateViewController(withIdentifier: "LetsGoVC")  as? UIViewController{
                let navController = UINavigationController(rootViewController: letsGoVC)
                window.rootViewController = navController
            }
        }
        window.makeKeyAndVisible()
    }

    private func setInitialViewController() {
        guard let window = window else { return }
        
        let isLoggedIn = TokenManager.shared.accessToken
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if (isLoggedIn != nil) {
            let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController
            window.rootViewController = mainTabBarController
        } else {
            // ✅ Show LetsGoVC from Storyboard
            let letsGoVC = storyboard.instantiateViewController(withIdentifier: "LetsGoVC") as? UIViewController
            let navController = UINavigationController(rootViewController: letsGoVC!)
            window.rootViewController = navController
        }
        window.makeKeyAndVisible()
    }
}
