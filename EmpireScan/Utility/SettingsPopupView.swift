/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import UIKit

func colorFromHexString(_ hexString: String) -> UIColor {
    var cleanString: String! = hexString.replacingOccurrences(of: "#", with: "")
    if cleanString.count == 6 {
        cleanString = cleanString.appending("ff")
    }
    assert(cleanString.count == 8)
    
    var baseValue: UInt32 = 0
    let scanner = Scanner(string: cleanString)
    scanner.scanHexInt32(&baseValue)
    
    let mask: UInt32 = 0x000000FF
    let red = CGFloat((baseValue >> 24) & mask) / 255.0
    let green = CGFloat((baseValue >> 16) & mask) / 255.0
    let blue = CGFloat((baseValue >> 8) & mask) / 255.0
    let alpha = CGFloat((baseValue >> 0) & mask) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
}

// MARK: DropDownView
typealias _Action = (Int) -> Void

class DropDownView: UITableView, UITableViewDelegate, UITableViewDataSource {
    private var _options: [String] = []
    private var _cellReuseIdentifier: String = "cell"
    private var _heightConstraint: NSLayoutConstraint!
    private var _isShown: Bool = false
    private var _activeIndex: Int = 0
    private var _action: _Action?
    var selectedIndex: Int {
        get { return _activeIndex }
        set {
            _activeIndex = newValue
            reloadData()
        }
    }
    var onChangedTarget: _Action? {
        get { return _action }
        set {
            _action = newValue
        }
    }
    
    init(options: [String], activeIndex index: Int) {
        _options = options
        _cellReuseIdentifier = "cell"
        _isShown = false
        _activeIndex = index
        
        super.init(frame: CGRect.zero, style: .plain)
        
        register(UITableViewCell.self, forCellReuseIdentifier: _cellReuseIdentifier)
        
        _heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        _heightConstraint.isActive = true
        
        dataSource = self
        delegate = self
        
        layoutIfNeeded()
        reloadData()
        _heightConstraint.constant = contentSize.height
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: _cellReuseIdentifier, for: indexPath)
        
        guard let label = cell.textLabel else { return cell }
        let iRow: Int = indexPath[1]
        if iRow == 0 { // header
            label.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
            label.textColor = colorFromHexString("3A3A3C")
            cell.backgroundColor = colorFromHexString("#DEDEDE")
            label.text = _options[_activeIndex]
        } else if iRow - 1 == _activeIndex { // selected cell
            label.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
            label.textColor = UIColor.white
            cell.backgroundColor = colorFromHexString("#00C3FF")
            label.text = _options[iRow - 1]
        } else {
            label.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
            label.textColor = colorFromHexString("505053")
            cell.backgroundColor = colorFromHexString("#DEDEDE")
            label.text = _options[iRow - 1]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _isShown ? 1 + _options.count : 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if _isShown {
            _isShown = false
            let iRow: Int = indexPath[1]
            if iRow > 0 && _activeIndex != (iRow - 1) {
                _activeIndex = iRow - 1
                if let action = _action {
                    action(_activeIndex)
                }
            }
        } else {
            _isShown = true
        }
        
        reloadData()
        _heightConstraint.constant = contentSize.height
        layoutIfNeeded()
    }
}

// MARK: SettingsListModal
class SettingsListModal: UIScrollView {
    let marginSize: CGFloat = 10.0
    let fontHeight: CGFloat = 17.0
    let fontHeightSmall: CGFloat = 14.0
    let cornerRadius: CGFloat = 8.0
    var _contentView: UIView!
    
    var optionsSet = OptionsSet()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(options: OptionsSet = OptionsSet()) {
        super.init(frame: CGRect.zero)
        optionsSet = options
        setupUIComponentsAndLayout()
    }
    
    class func setConstraintsFor(_ view: UIView, below anchor: UIView?, margin: CGFloat) {
        let topAnchor: NSLayoutYAxisAnchor = anchor != nil ? anchor!.bottomAnchor : view.superview!.layoutMarginsGuide.topAnchor
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor, constant: anchor != nil ? margin : 0.0),
            view.leadingAnchor.constraint(equalTo: view.superview!.layoutMarginsGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: view.superview!.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    class func pinToViewBottom(_ view: UIView) {
        view.bottomAnchor.constraint(equalTo: view.superview!.layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    func createHorizontalRule(_ height: CGFloat) -> UIView {
        // NOTE: You still need to add a width == superview.width constraint
        // You may also want to change the background color
        let horizontalRule = UIView()
        horizontalRule.translatesAutoresizingMaskIntoConstraints = false
        horizontalRule.backgroundColor = UIColor.darkGray
        
        horizontalRule.addConstraint(NSLayoutConstraint(item: horizontalRule,
                                                        attribute: .height,
                                                        relatedBy: .equal,
                                                        toItem: nil,
                                                        attribute: .notAnAttribute,
                                                        multiplier: 1.0,
                                                        constant: height))
        return horizontalRule
    }
    
    func addHorizontalRule(to parent: UIView, below anchor: UIView, margin: CGFloat, width: CGFloat) -> UIView {
        let hr: UIView = createHorizontalRule(1.0)
        hr.backgroundColor = colorFromHexString("#979797")
        parent.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.topAnchor.constraint(equalTo: anchor.bottomAnchor, constant: margin),
            hr.centerXAnchor.constraint(equalTo: hr.superview!.centerXAnchor),
            hr.widthAnchor.constraint(equalTo: hr.superview!.widthAnchor, multiplier: width)
        ])
        return hr
    }
    
    func addOptionGroupView(to parent: UIView, below anchor: UIView?, margin: CGFloat, label text: String) -> UIView {
        var topLine: UIView?
        if let anchor = anchor {
            topLine = addHorizontalRule(to: parent, below: anchor, margin: 0.0, width: 1.0)
        }
        
        let label: UILabel = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: fontHeight, weight: .regular)
        label.textColor = colorFromHexString("505053")
        label.text = text
        parent.addSubview(label)
        SettingsListModal.setConstraintsFor(label, below: topLine, margin: margin)
        
        let bottomLine: UIView = addHorizontalRule(to: parent, below: label, margin: marginSize / 2, width: 1.0)
        
        let subView: UIView = UIView()
        subView.translatesAutoresizingMaskIntoConstraints = false
        subView.backgroundColor = colorFromHexString("#F1F1F1")
        subView.layoutMargins = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        parent.addSubview(subView)
        
        NSLayoutConstraint.activate([
            subView.topAnchor.constraint(equalTo: bottomLine.bottomAnchor),
            subView.leadingAnchor.constraint(equalTo: subView.superview!.leadingAnchor),
            subView.widthAnchor.constraint(equalTo: subView.superview!.widthAnchor)
        ])
        return subView
    }
    
    func addSwitchOption(to parent: UIView, below anchor: UIView?, margin: CGFloat, label text: String) -> UISwitch{
        let label: UILabel = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: fontHeight, weight: .medium)
        label.textColor = colorFromHexString("3A3A3C")
        label.text = text
        parent.addSubview(label)
        SettingsListModal.setConstraintsFor(label, below: anchor, margin: margin)
        
        let switchView: UISwitch = UISwitch()
        switchView.translatesAutoresizingMaskIntoConstraints = false
        switchView.isUserInteractionEnabled = true
        switchView.onTintColor = colorFromHexString("#00C3FF")
        parent.addSubview(switchView)
        
        NSLayoutConstraint.activate([
            switchView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            switchView.trailingAnchor.constraint(equalTo: switchView.superview!.layoutMarginsGuide.trailingAnchor)
        ])
        return switchView
    }
    
    func imageWithColor(_ color: UIColor, _ rect: CGRect, _ cornerRadius: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        
        color.setFill()
        
        let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        bezierPath.fill()
        
        let image: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
        
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        
        UIGraphicsEndImageContext()
        return image
    }
    
    func addSegmentedOption(to parent: UIView, below anchor: UIView?, label text: String, options: [String]) -> UISegmentedControl {
        let label: UILabel = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: fontHeight, weight: .medium)
        label.textColor = colorFromHexString("3A3A3C")
        label.text = text
        parent.addSubview(label)
        SettingsListModal.setConstraintsFor(label, below: anchor, margin: marginSize)
        
        let segmentView: UISegmentedControl = UISegmentedControl(items: options)
        segmentView.translatesAutoresizingMaskIntoConstraints = false
        segmentView.clipsToBounds = true
        segmentView.isUserInteractionEnabled = true
        segmentView.backgroundColor = colorFromHexString("#D2D2D2")
        segmentView.tintColor = colorFromHexString("#00C3FF")
        
        segmentView.setTitleTextAttributes([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontHeight, weight: .medium),
            NSAttributedString.Key.foregroundColor: colorFromHexString("#505053")],
                                           for: .normal)
        
        segmentView.setTitleTextAttributes([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontHeight, weight: .medium),
            NSAttributedString.Key.foregroundColor: UIColor.white],
                                           for: .selected)
        
        segmentView.setBackgroundImage(imageWithColor(colorFromHexString("#DEDEDE"), CGRect(x: 0.0, y: 0.0, width: 1.0, height: 30.0), 0.0),
                                       for: .normal,
                                       barMetrics: .default)
        segmentView.setBackgroundImage(imageWithColor(colorFromHexString("#00C3FF"), CGRect(x: 0.0, y: 0.0, width: 1.0, height: 30.0), 0.0),
                                       for: .selected,
                                       barMetrics: .default)
        segmentView.setDividerImage(imageWithColor(UIColor.clear, CGRect(x: 0.0, y: 0.0, width: 1.0, height: 30.0), 0.0),
                                    forLeftSegmentState: .normal,
                                    rightSegmentState: .normal,
                                    barMetrics: .default)
        segmentView.setDividerImage(imageWithColor(UIColor.clear, CGRect(x: 0.0, y: 0.0, width: 1.0, height: 30.0), 0.0),
                                    forLeftSegmentState: .normal,
                                    rightSegmentState: .selected,
                                    barMetrics: .default)
        segmentView.layer.cornerRadius = cornerRadius
        
        parent.addSubview(segmentView)
        SettingsListModal.setConstraintsFor(segmentView, below: label, margin: marginSize)
        return segmentView
    }
    
    func addSliderOption(to parent: UIView, below anchor: UIView?, label text: String, textMin: String, textMax: String, min: Float, max: Float) -> UISlider {
        let label: UILabel = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: fontHeight, weight: .medium)
        label.textColor = colorFromHexString("#3A3A3C")
        label.text = text
        parent.addSubview(label)
        SettingsListModal.setConstraintsFor(label, below: anchor, margin: marginSize)
        
        let slider: UISlider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = colorFromHexString("#00C3FF")
        slider.minimumValue = min
        slider.maximumValue = max
        slider.isUserInteractionEnabled = true
        parent.addSubview(slider)
        
        let minLabel: UILabel = UILabel()
        minLabel.translatesAutoresizingMaskIntoConstraints = false
        minLabel.font = UIFont.systemFont(ofSize: fontHeight, weight: .medium)
        minLabel.textColor = colorFromHexString("979797")
        minLabel.text = textMin
        parent.addSubview(minLabel)
        
        let maxLabel: UILabel = UILabel()
        maxLabel.translatesAutoresizingMaskIntoConstraints = false
        maxLabel.font = UIFont.systemFont(ofSize: fontHeight, weight: .medium)
        maxLabel.textColor = colorFromHexString("979797")
        maxLabel.text = textMax
        parent.addSubview(maxLabel)
        
        NSLayoutConstraint.activate([
            slider.centerYAnchor.constraint(equalTo: label.bottomAnchor, constant: marginSize),
            minLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            minLabel.leftAnchor.constraint(equalTo: minLabel.superview!.layoutMarginsGuide.leftAnchor),
            minLabel.rightAnchor.constraint(equalTo: slider.leftAnchor),
            maxLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            maxLabel.leftAnchor.constraint(equalTo: slider.rightAnchor),
            maxLabel.rightAnchor.constraint(equalTo: maxLabel.superview!.layoutMarginsGuide.rightAnchor)
        ])
        
        return slider
    }
    
    func addDropDownOption(to parent: UIView, below anchor: UIView?, label text: String, options: [String], active index: Int) -> DropDownView {
        let label: UILabel = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: fontHeight, weight: .medium)
        label.textColor = colorFromHexString("3A3A3C")
        label.text = text
        parent.addSubview(label)
        SettingsListModal.setConstraintsFor(label, below: anchor, margin: marginSize)
        
        let dropDown = DropDownView(options: options, activeIndex: index)
        dropDown.layer.cornerRadius = cornerRadius
        dropDown.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(dropDown)
        SettingsListModal.setConstraintsFor(dropDown, below: label, margin: marginSize)
        return dropDown
    }
    
    func showOpts(in view: UIView, below anchor: UIView?) -> UIView? {
        var groupAnchor = anchor
        for group in optionsSet.groups {
            let groupView: UIView = self.addOptionGroupView(to: _contentView, below: groupAnchor, margin: marginSize, label: group.title)
            groupAnchor = groupView
            var optAnchor: UIView?
            for opt in group.options {
                var viewControl: UIView! = nil
                switch opt {
                case let optBool as OptionBool:
                    let optControl = self.addSwitchOption(to: groupView, below: optAnchor, margin: marginSize, label: optBool.name)
                    optControl.isOn = optBool.val
                    optControl.addAction(for: .valueChanged, { [weak optBool] in optBool?.val = optControl.isOn })
                    viewControl = optControl
                case let optEnum as OptionEnum:
                    if optEnum.style == .segmented {
                        let optControl = self.addSegmentedOption(to: groupView, below: optAnchor, label: optEnum.name, options: optEnum.map)
                        optControl.selectedSegmentIndex = optEnum.val
                        optControl.addAction(for: .valueChanged, { [weak optEnum] in optEnum?.val = optControl.selectedSegmentIndex })
                        viewControl = optControl
                    } else {
                        let optControl = self.addDropDownOption(to: groupView, below: optAnchor, label: optEnum.name, options: optEnum.map, active: optEnum.val)
                        optControl.onChangedTarget = { [weak optEnum] in optEnum?.val = $0 }
                        viewControl = optControl
                    }
                    
                case let optFloat as OptionFloat:
                    if optFloat.style == .slider {
                        let optControl = self.addSliderOption(to: groupView, below: optAnchor, label: optFloat.name,
                                                              textMin: optFloat.minText, textMax: optFloat.maxText, min: optFloat.min, max: optFloat.max)
                        optControl.value = optFloat.val
                        optControl.addAction(for: .valueChanged, { [weak optFloat] in optFloat?.val = optControl.value })
                        viewControl = optControl
                    }
                default:
                    continue
                }
                
                if opt !==  group.options.last {
                    optAnchor = self.addHorizontalRule(to: groupView, below: viewControl, margin: marginSize, width: 0.9)
                } else {
                    optAnchor = viewControl
                }
            }
            SettingsListModal.pinToViewBottom(optAnchor!)
        }
        return groupAnchor
    }
    
    func setupUIComponentsAndLayout() {
        // Attributes that apply to the whole content view
        backgroundColor = UIColor.white
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        layer.cornerRadius = cornerRadius
        
        _contentView = UIView()
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.clipsToBounds = true
        _contentView.layoutMargins = UIEdgeInsets(top: marginSize, left: marginSize, bottom: marginSize, right: marginSize)
        addSubview(_contentView)
        
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: _contentView.superview!.topAnchor),
            _contentView.bottomAnchor.constraint(equalTo: _contentView.superview!.bottomAnchor),
            _contentView.leftAnchor.constraint(equalTo: _contentView.superview!.leftAnchor),
            _contentView.rightAnchor.constraint(equalTo: _contentView.superview!.rightAnchor),
            _contentView.widthAnchor.constraint(equalTo: _contentView.superview!.widthAnchor)
        ])
        
        let groupView = showOpts(in: _contentView, below: nil)
        
        let hr6: UIView = addHorizontalRule(to: _contentView, below: groupView!, margin: 0.0, width: 1.0)
        SettingsListModal.pinToViewBottom(hr6)
    }
}


extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping () -> Void) {
        @objc class ClosureSleeve: NSObject {
            let closure: () -> Void
            
            init(_ closure: @escaping () -> Void) { self.closure = closure }
            
            @objc func invoke() { closure() }
        }
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, "\(UUID())", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
