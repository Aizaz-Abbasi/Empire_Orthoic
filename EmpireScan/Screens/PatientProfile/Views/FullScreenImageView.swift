//
//  FullScreenImageView.swift
//  EmpireScan
//
//  Created by MacOK on 18/04/2025.
//
import Foundation
import SwiftUI

struct FullScreenImageView: View {
    let imageURL: URL?
    @Binding var isPresented: Bool
    init(imageURL: URL?, isPresented: Binding<Bool>) {
        self.imageURL = imageURL
        self._isPresented = isPresented
        
        // Print the imageURL during initialization
        if let url = imageURL {
            print("🖼️ imageURL:", url)
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let imageURL = imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack(alignment: .center) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2.0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                            .font(.largeTitle)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text("No image available")
                    .foregroundColor(.white)
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
            }
            // Close Button (Top Right)
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(Color.black.opacity(0.4))
                    .padding(16)
                    .clipShape(Circle()) // Optional: makes the background circular
            }

        }
    }
}
