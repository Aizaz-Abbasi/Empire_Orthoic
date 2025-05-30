//
//  MeasureStl.swift
//  EmpireScan
//
//  Created by MacOK on 23/05/2025.
//
import SwiftUI
import SceneKit
import UIKit
import Combine
import UniformTypeIdentifiers

struct STLViewerScreen: View {
    @State private var geometry: SCNGeometry? = nil
    @State private var viewID = UUID()
    
    var body: some View {
        VStack {
            if let geometry = geometry {
                STLSceneView(geometry: geometry)
                    .edgesIgnoringSafeArea(.all)
                HStack {
                                Button("Undo") {
                                    NotificationCenter.default.post(name: .undoLastAction, object: nil)
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)

                                Button("Save") {
                                    NotificationCenter.default.post(name: .saveAction, object: nil)
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding()
            } else {
                Text("Loading STL...")
                    .onAppear {
                        if let url = Bundle.main.url(forResource: "20255167140259", withExtension: "stl"),
                           let triangles = STLParser.loadBinarySTL(from: url) {
                            self.geometry = STLParser.buildGeometry(from: triangles)
                        }
                    }
            }
        }
    }
}

extension Notification.Name {
    static let undoLastAction = Notification.Name("undoLastAction")
    static let saveAction = Notification.Name("saveAction")
}
