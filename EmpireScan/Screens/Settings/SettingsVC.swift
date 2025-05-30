//
//  SettingsVC.swift
//  EmpireScan
//
//  Created by MacOK on 06/05/2025.
//
import Foundation
import SwiftUI

class SettingsVC: UIViewController {
    
    @IBOutlet weak var headerView: UIView?
    @IBOutlet weak var settingsBtn: UIButton?
    private let sensorTypeLabel = UILabel()
    private let structureButton = UIButton(type: .system)
    private let appleButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    private var selectedSensorType: String = ""
    private let sensorContainerView = UIView()
    
    private let trackerContainerView = UIView()
    private let trackerTypeLabel = UILabel()
    private let depthOnlyButton = UIButton(type: .system)
    private let depthColorButton = UIButton(type: .system)
    private var selectedTrackerType: String = UserDefaults.standard.string(forKey: "selectedTrackerType") ?? ""
    
    let meshContainerView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        //view.backgroundColor = .red
        //UIColor(named: "#f5f5f5")
        //setDynamicCornerRadius()
        print("SettingsVC loaded")
        if let savedSensor = UserDefaults.standard.string(forKey: "selectedSensorType") {
            print("savedSensor",savedSensor)
            selectedSensorType = savedSensor
        }
        setupSensorUI()
        setupTrackerUI()
        setupHighResolutionMeshToggle()
        setupLogoutButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //setDynamicCornerRadius()
    }

    private func setupSensorUI() {
        // Set up container view
        sensorContainerView.backgroundColor = .white
        //sensorContainerView.layer.cornerRadius = 12
        //sensorContainerView.layer.borderWidth = 1
        sensorContainerView.layer.borderColor = UIColor.lightGray.cgColor
        sensorContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sensorContainerView)

        // Add subviews to container
        sensorContainerView.addSubview(sensorTypeLabel)
        sensorContainerView.addSubview(structureButton)
        sensorContainerView.addSubview(appleButton)
        sensorTypeLabel.text = "Sensor Type"
        sensorTypeLabel.font = UIFont.boldSystemFont(ofSize: 18)

        sensorTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        structureButton.translatesAutoresizingMaskIntoConstraints = false
        appleButton.translatesAutoresizingMaskIntoConstraints = false
        print(selectedSensorType,"selectedSensorType")
        // Configure buttons
        configureRadioButton(structureButton, title: "Structure", isSelected: selectedSensorType == "Structure")
        configureRadioButton(appleButton, title: "Apple", isSelected: selectedSensorType == "Apple")
        
        structureButton.addTarget(self, action: #selector(sensorTypeTapped(_:)), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(sensorTypeTapped(_:)), for: .touchUpInside)

        // Layout container view
        NSLayoutConstraint.activate([
            sensorContainerView.topAnchor.constraint(equalTo: headerView!.bottomAnchor, constant: 10),
            sensorContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            sensorContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
        ])

        // Layout inside container
        NSLayoutConstraint.activate([
            sensorTypeLabel.topAnchor.constraint(equalTo: sensorContainerView.topAnchor, constant: 20),
            sensorTypeLabel.leadingAnchor.constraint(equalTo: sensorContainerView.leadingAnchor, constant: 16),

            structureButton.topAnchor.constraint(equalTo: sensorTypeLabel.bottomAnchor, constant: 20),
            structureButton.leadingAnchor.constraint(equalTo: sensorTypeLabel.leadingAnchor),

            appleButton.topAnchor.constraint(equalTo: structureButton.bottomAnchor, constant: 20),
            appleButton.leadingAnchor.constraint(equalTo: sensorTypeLabel.leadingAnchor),

            appleButton.bottomAnchor.constraint(equalTo: sensorContainerView.bottomAnchor, constant: -20)
        ])
    }

    private func setupTrackerUI() {
        // Set up container view
        trackerContainerView.backgroundColor = .white
        trackerContainerView.layer.borderColor = UIColor.lightGray.cgColor
        trackerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(trackerContainerView)

        // Add subviews to container
        trackerContainerView.addSubview(trackerTypeLabel)
        trackerContainerView.addSubview(depthOnlyButton)
        trackerContainerView.addSubview(depthColorButton)

        trackerTypeLabel.text = "Tracker Type"
        trackerTypeLabel.font = UIFont.boldSystemFont(ofSize: 18)

        trackerTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        depthOnlyButton.translatesAutoresizingMaskIntoConstraints = false
        depthColorButton.translatesAutoresizingMaskIntoConstraints = false

        // Configure buttons
        configureRadioButton(depthOnlyButton, title: "Depth Only", isSelected: selectedTrackerType == "Depth Only")
        configureRadioButton(depthColorButton, title: "Color + Depth", isSelected: selectedTrackerType == "Color + Depth")

        depthOnlyButton.addTarget(self, action: #selector(trackerTypeTapped(_:)), for: .touchUpInside)
        depthColorButton.addTarget(self, action: #selector(trackerTypeTapped(_:)), for: .touchUpInside)

        // Layout container view
        NSLayoutConstraint.activate([
            trackerContainerView.topAnchor.constraint(equalTo: sensorContainerView.bottomAnchor, constant: 10),
            trackerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            trackerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
        ])

        // Layout inside container
        NSLayoutConstraint.activate([
            trackerTypeLabel.topAnchor.constraint(equalTo: trackerContainerView.topAnchor, constant: 20),
            trackerTypeLabel.leadingAnchor.constraint(equalTo: trackerContainerView.leadingAnchor, constant: 16),

            depthOnlyButton.topAnchor.constraint(equalTo: trackerTypeLabel.bottomAnchor, constant: 20),
            depthOnlyButton.leadingAnchor.constraint(equalTo: trackerTypeLabel.leadingAnchor),

            depthColorButton.topAnchor.constraint(equalTo: depthOnlyButton.bottomAnchor, constant: 20),
            depthColorButton.leadingAnchor.constraint(equalTo: trackerTypeLabel.leadingAnchor),

            depthColorButton.bottomAnchor.constraint(equalTo: trackerContainerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupLogoutButton() {
        view.addSubview(logoutButton)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setTitle(" Logout", for: .normal)
        logoutButton.setTitleColor(Colors.primary.uiColor, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        logoutButton.setImage(UIImage(systemName: "power"), for: .normal)
        logoutButton.tintColor =  Colors.primary.uiColor

        // Match sensorContainerView style
        logoutButton.backgroundColor = .white
        logoutButton.clipsToBounds = true
        logoutButton.contentHorizontalAlignment = .center
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        logoutButton.addTarget(self, action: #selector(logOutButton(_:)), for: .touchUpInside)

        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: meshContainerView.bottomAnchor, constant: 20),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupHighResolutionMeshToggle() {
        // Label
        let meshLabel = UILabel()
        meshLabel.text = "High Resolution Mesh"
        meshLabel.font = UIFont.systemFont(ofSize: 16)
        meshLabel.textColor = .black
        meshLabel.translatesAutoresizingMaskIntoConstraints = false

        // Switch
        let meshSwitch = UISwitch()
        meshSwitch.translatesAutoresizingMaskIntoConstraints = false
        meshSwitch.isOn = UserDefaults.standard.object(forKey: "highResolutionMesh") as? Bool ?? true
        meshSwitch.onTintColor = UIColor(Colors.primary)
        meshSwitch.addTarget(self, action: #selector(highResolutionMeshChanged(_:)), for: .valueChanged)

        // Container
        meshContainerView.backgroundColor = .white
        meshContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(meshContainerView)
        meshContainerView.addSubview(meshLabel)
        meshContainerView.addSubview(meshSwitch)

        // Layout
        NSLayoutConstraint.activate([
            meshContainerView.topAnchor.constraint(equalTo: trackerContainerView.bottomAnchor, constant: 10),
            meshContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            meshContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            meshLabel.topAnchor.constraint(equalTo: meshContainerView.topAnchor, constant: 20),
            meshLabel.leadingAnchor.constraint(equalTo: meshContainerView.leadingAnchor, constant: 20),
            meshLabel.bottomAnchor.constraint(equalTo: meshContainerView.bottomAnchor, constant: -20),

            meshSwitch.centerYAnchor.constraint(equalTo: meshLabel.centerYAnchor),
            meshSwitch.trailingAnchor.constraint(equalTo: meshContainerView.trailingAnchor, constant: -20)
        ])
    }

    @objc private func sensorTypeTapped(_ sender: UIButton) {
        selectedSensorType = sender.tag == 0 ? "Structure" : "Apple"
        UserDefaults.standard.setValue(selectedSensorType, forKey: "selectedSensorType")
        configureRadioButton(structureButton, title: "Structure", isSelected: sender.tag == 0)
        configureRadioButton(appleButton, title: "Apple", isSelected: sender.tag == 1)
        print("Selected sensor type: \(selectedSensorType)")
    }
    
    @objc private func trackerTypeTapped(_ sender: UIButton) {
        selectedTrackerType = sender.tag == 0 ? "Depth Only" : "Color + Depth"
        UserDefaults.standard.setValue(selectedTrackerType, forKey: "selectedTrackerType")

        configureRadioButton(depthOnlyButton, title: "Depth Only", isSelected: sender.tag == 0)
        configureRadioButton(depthColorButton, title: "Color + Depth", isSelected: sender.tag == 1)
        print("Selected tracker type: \(selectedTrackerType)")
    }
    
    @objc private func highResolutionMeshChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "highResolutionMesh")
        print("High Resolution Mesh is now \(sender.isOn)")
    }



    private func configureRadioButton(_ button: UIButton, title: String, isSelected: Bool) {
        let symbol = isSelected ? "largecircle.fill.circle" : "circle"
        let image = UIImage(systemName: symbol)?.withTintColor(Colors.primary.uiColor, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        button.setTitle("  \(title)", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.contentHorizontalAlignment = .left
        button.tag = (title == "Structure" || title == "Depth Only") ? 0 : 1
    }

//
//    private func setDynamicCornerRadius() {
//        guard let button = settingsBtn else { return }
//        // Set corner radius as a percentage of the button's height (e.g., 20% of the height)
//        let cornerRadius = button.frame.size.height * 0.5
//        button.layer.cornerRadius = cornerRadius
//        // Ensure the button's content doesn't overflow the rounded corners
//        button.clipsToBounds = true
//    }

    @IBAction func logOutButton(_ sender: UIButton) {
        print("logOutButton ===>")
        TokenManager.shared.clearTokens()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let letsGoVC = storyboard.instantiateViewController(withIdentifier: "LetsGoVC") as? UIViewController{
            let navController = UINavigationController(rootViewController: letsGoVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true, completion: nil)
        }
    }
}
