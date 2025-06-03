import UIKit

class FootSelectionVC: UIViewController {
    
    @IBOutlet weak var bodyImageView: UIImageView!
    @IBOutlet weak var scanType: UILabel!
    @IBOutlet weak var foot: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    
    var patient: PatientData?
    var folderId: Int = 0
    private var leftLabel: UILabel?
    private var rightLabel: UILabel?
    private var selectedFootOptionIndex: Int?
    // Foot areas
//    private let leftFootArea = CGRect(x: 0.30, y: 0.90, width: 0.15, height: 0.1)
//    private let rightFootArea = CGRect(x: 0.52, y: 0.90, width: 0.15, height: 0.1)
    // Foot areas (swap the coordinates of left and right)
    private let leftFootArea = CGRect(x: 0.52, y: 0.90, width: 0.15, height: 0.1)
    private let rightFootArea = CGRect(x: 0.30, y: 0.90, width: 0.15, height: 0.1)

    
    // Track selected foot
    private var selectedFoot: String?
    private var footOptionButtons: [UIButton] = []
    private var cancelButton: UIButton?
    
    // Circle layers
    private var leftOuterCircle: CAShapeLayer?
    private var leftInnerCircle: CAShapeLayer?
    private var rightOuterCircle: CAShapeLayer?
    private var rightInnerCircle: CAShapeLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        bodyImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        bodyImageView.addGestureRecognizer(tapGesture)
        foot.isHidden = true
        scanType.isHidden = true
        updateStartButton()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        print("handleTap")
        let tapLocation = gesture.location(in: bodyImageView)
        let imageSize = bodyImageView.bounds.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        
        let leftFootRect = CGRect(
            x: leftFootArea.origin.x * imageSize.width,
            y: leftFootArea.origin.y * imageSize.height,
            width: leftFootArea.width * imageSize.width,
            height: leftFootArea.height * imageSize.height
        )
        
        let rightFootRect = CGRect(
            x: rightFootArea.origin.x * imageSize.width,
            y: rightFootArea.origin.y * imageSize.height,
            width: rightFootArea.width * imageSize.width,
            height: rightFootArea.height * imageSize.height
        )
        
        if rightFootRect.contains(tapLocation) {
            selectedFoot = selectedFoot == "Right" ? nil : "Right"
            toggleFootSelection("Right", at: rightLabel?.frame.origin ?? tapLocation)
            foot.isHidden = false
            foot.text = selectedFoot
        } else if leftFootRect.contains(tapLocation) {
            selectedFoot = selectedFoot == "Left" ? nil : "Left"
            toggleFootSelection("Left", at: leftLabel?.frame.origin ?? tapLocation)
            foot.isHidden = false
            foot.text = selectedFoot
        }
    }
    
    private func updateStartButton() {
        startBtn.isEnabled = selectedFootOptionIndex != nil
        startBtn.alpha = selectedFootOptionIndex != nil ? 1.0 : 0.5
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addFootCirclesOverlay()
    }
    
    private func toggleFootSelection(_ foot: String, at position: CGPoint) {
        showFootOptions(at: position)
    }
    
    private func addFootCirclesOverlay() {
        print("addFootCirclesOverlay")
        guard bodyImageView.bounds.size != .zero else { return }
        let imageSize = bodyImageView.bounds.size
        removeExistingOverlays()
        let leftFootCenter = CGPoint(
            x: leftFootArea.origin.x * imageSize.width + (leftFootArea.width * imageSize.width)/2,
            y: leftFootArea.origin.y * imageSize.height + (leftFootArea.height * imageSize.height)/2
        )

        let rightFootCenter = CGPoint(
            x: rightFootArea.origin.x * imageSize.width + (rightFootArea.width * imageSize.width)/2,
            y: rightFootArea.origin.y * imageSize.height + (rightFootArea.height * imageSize.height)/2
        )

        leftOuterCircle = addCircle(center: leftFootCenter,
                                    radius: (leftFootArea.width * imageSize.width)/2,
                                    color: UIColor.clear,
                                    borderColor: UIColor.white.cgColor)
        
        leftInnerCircle = addCircle(center: leftFootCenter,
                                    radius: (leftFootArea.width * imageSize.width)/3,
                                    color: UIColor(red: 113/255, green: 199/255, blue: 78/255, alpha:1.0),
                                    borderColor: UIColor(red: 113/255, green: 199/255, blue: 78/255, alpha: 1.0).cgColor)
        
        rightOuterCircle = addCircle(center: rightFootCenter,
                                     radius: (leftFootArea.width * imageSize.width)/2,
                                     color: UIColor.clear,
                                     borderColor: UIColor.white.cgColor)
        
        rightInnerCircle = addCircle(center: rightFootCenter,
                                     radius: (leftFootArea.width * imageSize.width)/3,
                                     color: UIColor.green,
                                     borderColor: UIColor.green.cgColor)
        // Add L and R labels
        addFootLabels(leftCenter: leftFootCenter, rightCenter: rightFootCenter)
        updateCircleColors()
    }
    
    private func addFootLabels(leftCenter: CGPoint, rightCenter: CGPoint) {
        // Remove existing labels if present
        leftLabel?.removeFromSuperview()
        rightLabel?.removeFromSuperview()
        let labelSize: CGFloat = 20
        
        // Right foot label (update to left position)
        let right = UILabel(frame: CGRect(
            x: rightCenter.x - labelSize / 2,
            y: rightCenter.y - labelSize / 2,
            width: labelSize,
            height: labelSize)
        )
        right.text = "R"
        right.textColor = .white
        right.font = UIFont.boldSystemFont(ofSize: 16)
        right.textAlignment = .center
        bodyImageView.addSubview(right)
        rightLabel = right

        // Left foot label (update to right position)
        let left = UILabel(frame: CGRect(
            x: leftCenter.x - labelSize / 2,
            y: leftCenter.y - labelSize / 2,
            width: labelSize,
            height: labelSize)
        )
        left.text = "L"
        left.textColor = .white
        left.font = UIFont.boldSystemFont(ofSize: 16)
        left.textAlignment = .center
        bodyImageView.addSubview(left)
        leftLabel = left
    }
    
    private func addCircle(center: CGPoint, radius: CGFloat, color: UIColor, borderColor: CGColor) -> CAShapeLayer {
        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = color.cgColor
        shapeLayer.strokeColor = borderColor
        shapeLayer.lineWidth = 2.0
        bodyImageView.layer.addSublayer(shapeLayer)
        return shapeLayer
    }
    
    private func updateCircleColors() {
        let selectedColor =  UIColor(red: 113/255, green: 199/255, blue: 78/255, alpha: 1.0)
        let unselectedColor = UIColor.gray
        
        // Update left foot circles
        leftInnerCircle?.fillColor = selectedFoot == "Left" ? selectedColor.cgColor : unselectedColor.cgColor
        leftInnerCircle?.strokeColor = selectedFoot == "Left" ? selectedColor.cgColor : unselectedColor.cgColor
        
        // Update right foot circles
        rightInnerCircle?.fillColor = selectedFoot == "Right" ? selectedColor.cgColor : unselectedColor.cgColor
        rightInnerCircle?.strokeColor = selectedFoot == "Right" ? selectedColor.cgColor : unselectedColor.cgColor
    }
    
    private func removeExistingOverlays() {
        bodyImageView.layer.sublayers?
            .filter { $0 is CAShapeLayer }
            .forEach { $0.removeFromSuperlayer() }
        
        leftOuterCircle = nil
        leftInnerCircle = nil
        rightOuterCircle = nil
        rightInnerCircle = nil
    }
    
    private func showFootOptions(at position: CGPoint) {
        removeFootOptionButtons()
        
        let icons = ["FootSolid", "FormFootSolid"]
        let buttonSize: CGFloat = 60
        let spacing: CGFloat = 10
        let isRight = selectedFoot == "Right"
        
        for (index, icon) in icons.enumerated() {
            let offsetX: CGFloat = !isRight ? 100 : -100
            let button = UIButton(type: .custom)
            button.frame = CGRect(
                x: position.x - buttonSize / 2 + offsetX,
                y: position.y - CGFloat(index + 1) * (buttonSize + spacing),
                width: buttonSize,
                height: buttonSize
            )
            button.layer.cornerRadius = buttonSize / 2
            button.backgroundColor = .white
            button.setImage(UIImage(named: icon), for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(footOptionSelected(_:)), for: .touchUpInside)
            addShadow(to: button)
            bodyImageView.addSubview(button)
            footOptionButtons.append(button)
        }
        
        // Determine cancel button position based on selected foot
        var cancelCenter: CGPoint = position
        if selectedFoot == "Left", let leftLabel = leftLabel {
            cancelCenter = CGPoint(x: leftLabel.center.x, y: leftLabel.center.y)
        } else if selectedFoot == "Right", let rightLabel = rightLabel {
            cancelCenter = CGPoint(x: rightLabel.center.x, y: rightLabel.center.y)
        }
        
        let cancel = UIButton(type: .custom)
        cancel.frame = CGRect(
            x: cancelCenter.x - buttonSize / 2,
            y: cancelCenter.y - buttonSize / 2,
            width: buttonSize,
            height: buttonSize
        )
        cancel.layer.cornerRadius = buttonSize / 2
        cancel.backgroundColor = .white
        cancel.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancel.addTarget(self, action: #selector(cancelFootOptions), for: .touchUpInside)
        addShadow(to: cancel)
        bodyImageView.addSubview(cancel)
        cancelButton = cancel
    }
    
    private func removeFootOptionButtons() {
        footOptionButtons.forEach { $0.removeFromSuperview() }
        footOptionButtons = []
        cancelButton?.removeFromSuperview()
        cancelButton = nil
        scanType.isHidden = true
    }
    
    private func addShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
    }
    
    @objc private func cancelFootOptions() {
        removeFootOptionButtons()
        selectedFoot = nil
        selectedFootOptionIndex = nil
        leftLabel?.isHidden = false
        rightLabel?.isHidden = false
        scanType.isHidden = true
        foot.isHidden = true
        updateStartButton()
    }
    
    @objc private func footOptionSelected(_ sender: UIButton) {
        // Check if this button is already selected
        if selectedFootOptionIndex == sender.tag {
            // Deselect it
            let iconName = sender.tag == 0 ? "FootSolid" : "FormFootSolid"
            sender.setImage(UIImage(named: iconName), for: .normal)
            selectedFootOptionIndex = nil
            scanType.isHidden =  true
            updateStartButton()
        } else {
            // Deselect all first
            for (index, button) in footOptionButtons.enumerated() {
                let iconName = index == 0 ? "FootSolid" : "FormFootSolid"
                button.setImage(UIImage(named: iconName), for: .normal)
            }
            if sender.tag == 0 {
                sender.setImage(UIImage(named: "Active-footSolid"), for: .normal)
                scanType.text = "Plantar Surface"
            } else if sender.tag == 1 {
                sender.setImage(UIImage(named: "ActiveFormFootSolid"), for: .normal)
                scanType.text = "Foam Box"
            }
            scanType.isHidden =  false
            selectedFootOptionIndex = sender.tag
            updateStartButton()
        }
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        guard let foot = selectedFoot else { return }
        //print("Starting scan for \(foot) \(selectedFootOptionIndex) foot")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let sensorType = UserDefaults.standard.string(forKey: "selectedSensorType")
        print("sensorType",sensorType)
        if(sensorType == "Structure"){
            
            guard let fixedOrientationVC = storyboard.instantiateViewController(withIdentifier: "FixedOrientationStructure") as? FixedOrientationStructure,
                  let viewController = fixedOrientationVC.viewControllers.first as? StructureViewController else {
                print("❌ Could not instantiate FixedOrientationStructure or inner ViewController")
                return
            }
//            if let fixedOrientationVC = storyboard.instantiateViewController(withIdentifier: "FixedOrientationStructure") as? FixedOrientationStructure {
                if let viewController = fixedOrientationVC.viewControllers.first as? StructureViewController {
                    viewController.footType = selectedFoot
                    viewController.orderId = patient?.orderId
                    viewController.folderId = folderId
                    viewController.scanType = scanType.text
                    viewController.orderStatus = patient?.status
                }
                fixedOrientationVC.modalPresentationStyle = .fullScreen // Optional
                self.present(fixedOrientationVC, animated: true)
           // }
            
        }else{
            
            if let fixedOrientationVC = storyboard.instantiateViewController(withIdentifier: "FixedOrientationController") as? FixedOrientationController {
                if let viewController = fixedOrientationVC.viewControllers.first as? ViewController {
                    viewController.footType = selectedFoot
                    viewController.orderId = patient?.orderId
                    viewController.folderId = folderId
                    viewController.scanType = scanType.text
                    viewController.orderStatus = patient?.status
                }
                fixedOrientationVC.modalPresentationStyle = .fullScreen // Optional
                self.present(fixedOrientationVC, animated: true)
            }
        }
       
    }

}
