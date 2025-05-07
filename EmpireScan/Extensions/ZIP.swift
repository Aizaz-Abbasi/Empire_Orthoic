//
//  ZIP.swift
//  EmpireScan
//
//  Created by MacOK on 15/04/2025.
//

import Foundation
import ZIPFoundation

extension FileManager {
    func createZip(at zipFileURL: URL, withFilesAt fileURLs: [URL]) throws -> URL {
        // Remove existing zip file if it exists
        if fileExists(atPath: zipFileURL.path) {
            try removeItem(at: zipFileURL)
        }

        // Create a new archive
        guard let archive = Archive(url: zipFileURL, accessMode: .create) else {
            throw NSError(domain: "com.EmpireOpLabs.EmpireOrthoticProstheticLabs", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create ZIP archive."])
        }

        for fileURL in fileURLs {
            let fileName = fileURL.lastPathComponent
            try archive.addEntry(with: fileName, relativeTo: fileURL.deletingLastPathComponent())
        }

        return zipFileURL
    }
}

extension UIApplication {
    func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController,
           let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
}
