//
//  DownloadAndExtractPreview.swift
//  EmpireScan
//
//  Created by MacOK on 14/04/2025.
//
import Foundation
import ZIPFoundation

import Foundation

func downloadAndExtractPreview(from urlString: String, identifier: String = UUID().uuidString, completion: @escaping (URL?, URL?) -> Void) {
    print("📥 downloadAndExtractPreview from: \(urlString), identifier: \(identifier)")
    
    guard let url = URL(string: urlString) else {
        print("❌ Invalid URL: \(urlString)")
        completion(nil, nil)
        return
    }
    
    let fileName = url.lastPathComponent
    let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(identifier)_\(fileName)")
    let fileManager = FileManager.default

    // Ensure no file exists at the destination path
    if fileManager.fileExists(atPath: destinationURL.path) {
        do {
            try fileManager.removeItem(at: destinationURL)
            print("🗑️ Removed existing file: \(destinationURL.path)")
        } catch {
            print("⚠️ Error removing existing file: \(error)")
        }
    }

    print("⏬ Starting download from: \(urlString)")
    URLSession.shared.downloadTask(with: url) { tempURL, response, error in
        guard let tempURL = tempURL, error == nil else {
            print("❌ Download failed: \(error?.localizedDescription ?? "Unknown error")")
            DispatchQueue.main.async {
                completion(nil, nil)
            }
            return
        }
        
        print("✅ Download completed to temp URL: \(tempURL.path)")

        // Remove any existing file at the destination before moving
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.removeItem(at: destinationURL)
                print("🗑️ Removed existing destination file: \(destinationURL.path)")
            } catch {
                print("⚠️ Error removing existing file at destination: \(error)")
            }
        }

        do {
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            print("📦 Moved file to: \(destinationURL.path)")
            
            // Create unique extraction directory using the identifier
            let extractURL = fileManager.temporaryDirectory.appendingPathComponent("unzipped_\(identifier)")

            if fileManager.fileExists(atPath: extractURL.path) {
                try fileManager.removeItem(at: extractURL)
                print("🗑️ Removed existing extract directory")
            }

            try fileManager.createDirectory(at: extractURL, withIntermediateDirectories: true)
            print("📁 Created extraction directory: \(extractURL.path)")
            
            // Extract the main zip file
            do {
                try fileManager.unzipItem(at: destinationURL, to: extractURL)
                
                let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path)
                let fileSize = attributes?[.size] as? Int64 ?? 0
                print("ZIP file size: \(fileSize) bytes")
                print("📦 Successfully unzipped main file")
            } catch let zipError {
                print("❌ Error unzipping main file: \(zipError)")
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
                return
            }

            // Look for Preview.jpg
            let previewImageURL = extractURL.appendingPathComponent("Preview.jpg")
            var meshFileURL: URL?

            // Get contents of extracted directory
            let contents = try fileManager.contentsOfDirectory(at: extractURL, includingPropertiesForKeys: nil)
            print("📂 Directory contents: \(contents.map { $0.lastPathComponent })")
            
            // Look for mesh files recursively
            func findMeshFiles(in directory: URL) -> URL? {
                let meshExtensions = ["obj", "ply", "stl"]
                do {
                    let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                    
                    // First check for mesh files
                    for file in contents {
                        if meshExtensions.contains(file.pathExtension.lowercased()) {
                            return file
                        }
                    }
                    
                    // Then check subdirectories
                    for file in contents {
                        var isDir: ObjCBool = false
                        fileManager.fileExists(atPath: file.path, isDirectory: &isDir)
                        if isDir.boolValue {
                            if let meshURL = findMeshFiles(in: file) {
                                return meshURL
                            }
                        }
                    }
                } catch {
                    print("❌ Error searching directory: \(error)")
                }
                return nil
            }
                        
            // If still no mesh found, try the main directory
            if meshFileURL == nil {
                meshFileURL = findMeshFiles(in: extractURL)
            }
            
            // Returning the result
            DispatchQueue.main.async {
                completion(
                    fileManager.fileExists(atPath: previewImageURL.path) ? previewImageURL : nil,
                    meshFileURL
                )
            }

        } catch {
            print("❌ Processing failed: \(error)")
            DispatchQueue.main.async {
                completion(nil, nil)
            }
        }
    }.resume()
}



//func downloadAndExtractPreview(from urlString: String, identifier: String = UUID().uuidString, completion: @escaping (URL?, URL?) -> Void) {
//    print("📥 downloadAndExtractPreview from: \(urlString), identifier: \(identifier)")
//    guard let url = URL(string: urlString) else {
//        print("❌ Invalid URL: \(urlString)")
//        completion(nil, nil)
//        return
//    }
//    
//    let fileName = url.lastPathComponent
//    let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(identifier)_\(fileName)")
//    let fileManager = FileManager.default
//
//    // Delete existing file if it exists
//    if fileManager.fileExists(atPath: destinationURL.path) {
//        do {
//            try fileManager.removeItem(at: destinationURL)
//           // print("🗑️ Removed existing file: \(destinationURL.path)")
//        } catch {
//            //print("⚠️ Error removing existing file: \(error)")
//        }
//    }
//    
//    //print("⏬ Starting download from: \(urlString)")
//    URLSession.shared.downloadTask(with: url) { tempURL, response, error in
//        guard let tempURL = tempURL, error == nil else {
//            print("❌ Download failed: \(error?.localizedDescription ?? "Unknown error")")
//            DispatchQueue.main.async {
//                completion(nil, nil)
//            }
//            return
//        }
//        
//       // print("✅ Download completed to temp URL: \(tempURL.path)")
//        
//        // Check downloaded file size
////        do {
////            let attributes = try fileManager.attributesOfItem(atPath: tempURL.path)
////            let fileSize = attributes[.size] as? UInt64 ?? 0
////            print("📊 Downloaded file size: \(fileSize) bytes")
////            if fileSize == 0 {
////                print("⚠️ Warning: Downloaded file is empty!")
////            }
////        } catch {
////            print("⚠️ Error getting file attributes: \(error)")
////        }
//
//        do {
//            try fileManager.moveItem(at: tempURL, to: destinationURL)
//            //print("📦 Moved file to: \(destinationURL.path)")
//            
//            // Create unique extraction directory using the identifier
//            let extractURL = fileManager.temporaryDirectory.appendingPathComponent("unzipped_\(identifier)")
//
//            if fileManager.fileExists(atPath: extractURL.path) {
//                try fileManager.removeItem(at: extractURL)
//                //print("🗑️ Removed existing extract directory")
//            }
//
//            try fileManager.createDirectory(at: extractURL, withIntermediateDirectories: true)
//            //print("📁 Created extraction directory: \(extractURL.path)")
//            
//            // Extract the main zip file
//            do {
//                try fileManager.unzipItem(at: destinationURL, to: extractURL)
//                //print("📦 Successfully unzipped main file")
//            } catch let zipError {
//                print("❌ Error unzipping main file: \(zipError)")
//                DispatchQueue.main.async {
//                    completion(nil, nil)
//                }
//                return
//            }
//
//            // Print directory structure for debugging
//            func printDirectoryStructure(_ url: URL, indentation: String = "") {
//                do {
//                    let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
//                    for item in contents {
//                        var isDir: ObjCBool = false
//                        fileManager.fileExists(atPath: item.path, isDirectory: &isDir)
//                        print("\(indentation)📄 \(item.lastPathComponent) \(isDir.boolValue ? "(directory)" : "")")
//                        
//                        if isDir.boolValue {
//                            printDirectoryStructure(item, indentation: indentation + "  ")
//                        }
//                    }
//                } catch {
//                    print("\(indentation)❌ Error reading directory: \(error)")
//                }
//            }
//            
//            //print("📁 Full directory structure:")
//            //printDirectoryStructure(extractURL)
//
//            // Look for Preview.jpg
//            let previewImageURL = extractURL.appendingPathComponent("Preview.jpg")
//            var meshFileURL: URL?
//
//            // Get contents of extracted directory
//            let contents = try fileManager.contentsOfDirectory(at: extractURL, includingPropertiesForKeys: nil)
//            //print("📂 Directory contents: \(contents.map { $0.lastPathComponent })")
//            
//            // Look for mesh files recursively
//            func findMeshFiles(in directory: URL) -> URL? {
//                let meshExtensions = ["obj", "ply", "stl"]
//                do {
//                    let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
//                    
//                    // First check for mesh files
//                    for file in contents {
//                        //print("   🔍 Checking file: \(file.lastPathComponent) - Extension: \(file.pathExtension.lowercased())")
//                        if meshExtensions.contains(file.pathExtension.lowercased()) {
//                            //print("✅ Mesh file found: \(file.lastPathComponent)")
//                            return file
//                        }
//                    }
//                    
//                    // Then check subdirectories
//                    for file in contents {
//                        var isDir: ObjCBool = false
//                        fileManager.fileExists(atPath: file.path, isDirectory: &isDir)
//                        if isDir.boolValue {
//                            print("🔍 Searching directory: \(file.lastPathComponent)")
//                            if let meshURL = findMeshFiles(in: file) {
//                                return meshURL
//                            }
//                        }
//                    }
//                } catch {
//                    print("❌ Error searching directory: \(error)")
//                }
//                return nil
//            }
//                        
//            // If still no mesh found, try the main directory
//            if meshFileURL == nil {
//                meshFileURL = findMeshFiles(in: extractURL)
//            }
//            
//            // Check preview image
////            if fileManager.fileExists(atPath: previewImageURL.path) {
////                print("✅ Preview.jpg found at: \(previewImageURL.path)")
////            } else {
////                print("❌ Preview.jpg not found")
////            }
////            
////            // Check mesh file
////            if let meshFileURL = meshFileURL {
////                print("✅ Final mesh file URL: \(meshFileURL.path)")
////            } else {
////                print("❌ No mesh file found")
////            }
//
//            DispatchQueue.main.async {
//                completion(
//                    fileManager.fileExists(atPath: previewImageURL.path) ? previewImageURL : nil,
//                    meshFileURL
//                )
//            }
//
//        } catch {
//            print("❌ Processing failed: \(error)")
//            DispatchQueue.main.async {
//                completion(nil, nil)
//            }
//        }
//    }.resume()
//}

