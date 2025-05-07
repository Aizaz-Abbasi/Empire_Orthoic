/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import UIKit

let redButtonColorWithAlpha = UIColor(_colorLiteralRed: 230.0 / 255, green: 72.0 / 255, blue: 64.0 / 255, alpha: 0.85)
let blueButtonColorWithAlpha = UIColor(_colorLiteralRed: 0.160784314, green: 0.670588235, blue: 0.88627451, alpha: 0.85)
let blueGrayButtonColorWithAlpha = UIColor(_colorLiteralRed: 64.0 / 255, green: 110.0 / 255, blue: 117.0 / 255, alpha: 0.85)
let redButtonColorWithLightAlpha = UIColor(_colorLiteralRed: 230.0 / 255, green: 72.0 / 255, blue: 64.0 / 255, alpha: 0.45)
let blackLabelColorWithLightAlpha = UIColor(_colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)

extension UIButton {
  func applyCustomStyle(backgroundColor color: UIColor) {
    layer.cornerRadius = 15.0
    backgroundColor = color
    titleLabel?.textColor = UIColor.white
    layer.borderColor = UIColor.white.cgColor
    layer.borderWidth = 2.0

    setTitleColor(UIColor.white, for: .normal)
    setTitleColor(UIColor.white, for: .selected)
    setTitleColor(UIColor.white, for: .highlighted)

    titleLabel?.font = UIFont(name: "Helvetica Neue", size: 16.0)
  }
}
