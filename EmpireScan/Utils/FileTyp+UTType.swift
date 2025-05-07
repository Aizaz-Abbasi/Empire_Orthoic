//
//  FileTyp+UTType.swift
//  EmpireScan
//
//  Created by MacOK on 18/04/2025.
//
import UniformTypeIdentifiers
func mimeType(for url: URL) -> String {
    if let type = UTType(filenameExtension: url.pathExtension),
       let mimeType = type.preferredMIMEType {
        return mimeType
    }
    return "application/octet-stream" // default fallback
}
