/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import UIKit

class HelpOverlay: UIView {
  private var _contentView: UIView!

  init(parent: UIView) {
    super.init(frame: .zero)

    parent.addSubview(self)
    translatesAutoresizingMaskIntoConstraints = false

    let isIPad = (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad)
    NSLayoutConstraint.activate([
      centerXAnchor.constraint(equalTo: superview!.centerXAnchor),
      centerYAnchor.constraint(equalTo: superview!.centerYAnchor),
      widthAnchor.constraint(equalTo: superview!.widthAnchor, multiplier: isIPad ? 0.75 : 0.9)
    ])
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  private func setup() {
    _contentView?.removeFromSuperview()

    _contentView = UIView()
    _contentView.backgroundColor = UIColor.clear
    _contentView.translatesAutoresizingMaskIntoConstraints = false
    _contentView.clipsToBounds = false
    addSubview(_contentView)

    // Pinning all edges of the content view to the superview (this object)
    NSLayoutConstraint.activate([
      _contentView.topAnchor.constraint(equalTo: _contentView.superview!.topAnchor),
      _contentView.leftAnchor.constraint(equalTo: _contentView.superview!.leftAnchor),
      _contentView.rightAnchor.constraint(equalTo: _contentView.superview!.rightAnchor),
      _contentView.bottomAnchor.constraint(equalTo: _contentView.superview!.bottomAnchor)
    ])

    // constants
    let backgroundColor = UIColor(white: 0.0, alpha: 0.7)
    let cornerRadius = 12.0
    let titleFontSize = 32.0
    let messageFontSize = 22.0
    let verticalMargin = 30.0

    self.backgroundColor = backgroundColor
    self.isUserInteractionEnabled = true
    self.layer.cornerRadius = cornerRadius

    // title
    let titleLabel = UILabel()
    _contentView.addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: titleLabel.superview!.topAnchor, constant: verticalMargin),
      titleLabel.centerXAnchor.constraint(equalTo: titleLabel.superview!.centerXAnchor),
      titleLabel.widthAnchor.constraint(equalTo: titleLabel.superview!.widthAnchor, multiplier: 0.9),
      titleLabel.heightAnchor.constraint(equalToConstant: 43.0)
    ])

    titleLabel.font = UIFont.systemFont(ofSize: titleFontSize, weight: .bold)
    titleLabel.adjustsFontSizeToFitWidth = true
    titleLabel.text = "User Instructions"
    titleLabel.textColor = UIColor.white
    titleLabel.textAlignment = .center

    // message
    let messageLabel = UILabel()
    _contentView.addSubview(messageLabel)
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: verticalMargin/2),
      messageLabel.widthAnchor.constraint(equalTo: _contentView.widthAnchor, multiplier: 0.9),
      messageLabel.centerXAnchor.constraint(equalTo: _contentView.centerXAnchor)
    ])

    let subText = "1. Move your device until it plays a sound.\n2. Double tap on the screen or press the volume buttons to start scan and move your device around the foot.\n3.  Double tap or press the volume buttons again to stop scan."
    let attrSub = NSMutableAttributedString(string: subText)
    let subStyle = NSMutableParagraphStyle()
    subStyle.lineSpacing = 8.0
    attrSub.addAttribute(
      NSAttributedString.Key.paragraphStyle,
      value: subStyle,
      range: NSRange(location: 0, length: subText.count))
    messageLabel.attributedText = attrSub
    messageLabel.textColor = UIColor.white
    messageLabel.font = UIFont.systemFont(ofSize: messageFontSize, weight: .regular)
    messageLabel.lineBreakMode = .byWordWrapping
    messageLabel.numberOfLines = 0

    // button
    let calibrateButton = UIButton(type: .custom)
    _contentView.addSubview(calibrateButton)
    calibrateButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      calibrateButton.centerXAnchor.constraint(equalTo: calibrateButton.superview!.centerXAnchor),
      calibrateButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 25.0),
      calibrateButton.widthAnchor.constraint(equalToConstant: 260.0),
      calibrateButton.heightAnchor.constraint(equalToConstant: 50.0),
      calibrateButton.bottomAnchor.constraint(equalTo: calibrateButton.superview!.bottomAnchor, constant: -verticalMargin)
    ])

    calibrateButton.setTitle("OK", for: .normal)
    calibrateButton.setTitleColor(colorFromHexString("#3A3A3C"), for: .normal)
    calibrateButton.setTitleColor(UIColor.white.withAlphaComponent(0.76), for: .highlighted)
    calibrateButton.setBackgroundImage(imageWithColor(UIColor.white, CGRect(x: 0.0, y: 0.0, width: 413.0, height: 50.0), 25.0),
      for: .normal)
    calibrateButton.setBackgroundImage(imageWithColor(UIColor.lightGray, CGRect(x: 0.0, y: 0.0, width: 413.0, height: 50.0), 25.0),
      for: .highlighted)

    calibrateButton.backgroundColor = UIColor.clear
    calibrateButton.clipsToBounds = true
    calibrateButton.layer.cornerRadius = 25.0
    calibrateButton.titleLabel?.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
    calibrateButton.contentHorizontalAlignment = .center
    calibrateButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    calibrateButton.addTarget(self, action: #selector(okButtonClicked(_:)), for: .touchUpInside)
  }

  @objc private func okButtonClicked(_ button: UIButton) {
    self.isHidden = true
  }
}

func imageWithColor(_ color: UIColor, _ rect: CGRect, _ cornerRadius: CGFloat) -> UIImage {
  UIGraphicsBeginImageContext(rect.size)
  let context = UIGraphicsGetCurrentContext()!
  context.setAllowsAntialiasing(true)
  context.setShouldAntialias(true)

  color.setFill()
  UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()
  let image = UIGraphicsGetImageFromCurrentImageContext()!

  context.setAllowsAntialiasing(false)
  context.setShouldAntialias(false)
  UIGraphicsEndImageContext()
  return image
}
