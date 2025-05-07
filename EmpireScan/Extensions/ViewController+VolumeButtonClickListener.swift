/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

//
//  ViewController+.swift
//  3DFootScan
//
//  Created by Kazi Miftahul on 23/11/22.
//

import Foundation
import MediaPlayer

extension UIViewController {
  func setupVolumeButtonClickListener(action selector: Selector) {
    // hide volume indicator
    let volumeView = MPVolumeView(frame: CGRect(x: -CGFloat.greatestFiniteMagnitude, y: 0.0, width: 0.0, height: 0.0))
    self.view.addSubview(volumeView)

    if #available(iOS 15, *) {
      NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: "SystemVolumeDidChange"), object: nil)
    } else {
      NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
    }
  }

  func removeVolumeButtonClickListener() {
    if #available(iOS 15, *) {
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "SystemVolumeDidChange"), object: nil)
    } else {
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
    }
  }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
        }
        return self
    }
}
