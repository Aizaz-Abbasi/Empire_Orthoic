//
//  LoaderManager.swift
//  EmpireScan
//
//  Created by MacOK on 17/04/2025.
//

import Foundation
import UIKit

final class LoaderManager {
    static let shared = LoaderManager()
    private var loaderView: UIView?

    private init() {}

    func show(in view: UIView, message: String = "Uploading...") {
        // Avoid duplicate loaders
        if loaderView != nil { return }

        let loader = UIView(frame: view.bounds)
        loader.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        let container = UIView()
        container.backgroundColor = UIColor.white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = message
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()

        container.addSubview(indicator)
        container.addSubview(label)
        loader.addSubview(container)
        view.addSubview(loader)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: loader.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: loader.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 140),
            container.heightAnchor.constraint(equalToConstant: 100),

            indicator.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            label.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])

        loaderView = loader
    }

    func hide(completion: (() -> Void)? = nil) {
        loaderView?.removeFromSuperview()
        loaderView = nil
        completion?()
    }
}
