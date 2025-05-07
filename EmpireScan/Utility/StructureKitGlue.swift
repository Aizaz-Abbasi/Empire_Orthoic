/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import StructureKit
import Structure

extension STMesh: STKMesh {
}

extension STColorFrame: STKColorFrame {
}

extension STIntrinsics: STKIntrinsics {
}

extension STDepthFrame: STKDepthFrame {
  public func intrinsics() -> STKIntrinsics {
    let i: STIntrinsics = self.intrinsics()
    return i
  }
}
